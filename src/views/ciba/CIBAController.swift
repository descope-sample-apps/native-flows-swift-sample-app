
import UIKit
import LocalAuthentication
import UserNotifications
import DescopeKit

class CIBAController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var emailLabel: UILabel!

    /// The CIBA request to approve, as validated by `Descope.push.cibaRequest`
    var request: DescopeCIBARequest!

    // Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Showing CIBA approval screen")

        // show the user what is being requested before they act on it, using the title
        // and message that Descope put in the push notification
        titleLabel.text = request.title ?? "Approval request"
        messageLabel.text = request.body
        messageLabel.isHidden = request.body == nil
        emailLabel.text = Descope.sessionManager.session?.user.email.map { "Signed in as \($0)" }
    }

    // Actions

    @IBAction func didPressApprove() {
        print("Approve pressed")
        Task {
            await startApproval()
        }
    }

    @IBAction func didPressNotNow() {
        print("Not now pressed")

        // the SDK has no native deny call yet, so "Not now" leaves the request to expire
        dismiss(animated: true)
    }

    // Approval

    func startApproval() async {
        // make sure it's the owner of the device who approves, with Face ID or the passcode
        guard await confirmUserPresence(reason: "Approve this request") else { return }
        showFlow()
    }

    func confirmUserPresence(reason: String) async -> Bool {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            // a device with no passcode can't prove the user is present, so it can't approve,
            // except for the simulator which usually has no passcode set
            #if targetEnvironment(simulator)
            return true
            #else
            return false
            #endif
        }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }

    /// Creates a new DescopeFlowViewController, loads the CIBA flow into it, and pushes
    /// it onto the navigation controller stack
    func showFlow() {
        // the flow runs with the signed in user's session, and is where the user
        // approves or denies the request
        let flowViewController = DescopeFlowViewController()
        flowViewController.delegate = self
        flowViewController.start(flow: DescopeFlow(url: request.url))

        // the CIBA flow ends on a result screen rather than an end step, so we add a Close
        // button. The controller puts its activity indicator in the right bar item when its
        // view loads, so we load it first and add the button beside the indicator
        flowViewController.loadViewIfNeeded()
        let closeButton = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
            self?.dismiss(animated: true)
        })
        flowViewController.navigationItem.rightBarButtonItems = [closeButton] + (flowViewController.navigationItem.rightBarButtonItems ?? [])

        // push the view controller onto the navigation controller
        navigationController?.pushViewController(flowViewController, animated: true)
    }

    // Results

    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        (navigationController ?? self).present(alert, animated: true)
    }
}

extension CIBAController: DescopeFlowViewControllerDelegate {
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState) {
        print("Flow state changed to \(state) from \(previous)")
    }

    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController) {
        // we're showing the flow immediately so there's no need to handle the ready event
    }

    func flowViewControllerShouldShowURL(_ controller: DescopeFlowViewController, url: URL, external: Bool) -> Bool {
        // we return true so that the DescopeFlowViewController does its builtin behavior
        // of opening the URL in the user's default browser app
        return true
    }

    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController) {
        // the DescopeFlowViewController isn't at the root of its navigation controller stack,
        // so the user gets the default Back button and this function isn't called
    }

    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError) {
        print("CIBA flow failed: \(error)")
        showError(error)
    }

    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse) {
        print("CIBA flow finished")
        dismiss(animated: true)
    }
}

/// Handling the CIBA push notifications that Descope sends
extension CIBAController {
    /// CIBA requests expire within minutes, and the push carries no expiry of its own
    private static let requestLifetime: TimeInterval = 5 * 60

    /// A tapped notification is kept until the user is signed in and the home screen is up, so
    /// a tap that launches the app, or arrives while the sign in screen is showing, isn't lost
    private static var pendingNotification: UNNotification?

    /// The approval screen that's currently showing, if any
    private static weak var shownScreen: UIViewController?

    /// Called when the user taps a CIBA push notification
    static func handleNotification(_ notification: UNNotification) {
        pendingNotification = notification
        presentPendingRequest()
    }

    /// Shows the approval screen for a tapped notification, once the user is signed in
    static func presentPendingRequest() {
        guard let notification = pendingNotification, let session = Descope.sessionManager.session, !session.refreshToken.isExpired else { return }
        guard Date().timeIntervalSince(notification.date) < requestLifetime else {
            pendingNotification = nil
            return
        }

        // a newer tap replaces the approval screen that's showing
        shownScreen?.dismiss(animated: false)
        guard let presenter = topViewController() else { return }
        pendingNotification = nil

        // checks that the push is for this project and for the signed in user, and that the
        // flow URL is on a trusted host, since the flow runs with the user's session
        let userInfo = notification.request.content.userInfo
        guard let request = Descope.push.cibaRequest(from: userInfo, session: session, allowedHosts: []) else { return }

        let controller = CIBAController()
        controller.request = request
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.isModalInPresentation = true
        presenter.present(navigationController, animated: true)
        shownScreen = navigationController
    }

    private static func topViewController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first
        guard var top = window?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
