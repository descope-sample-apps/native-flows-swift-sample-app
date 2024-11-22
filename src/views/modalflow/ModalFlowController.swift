
import UIKit
import DescopeKit

class ModalFlowController: UIViewController {
    @IBOutlet var signinButton: UIButton!
    @IBOutlet var signinActivityIndicator: UIActivityIndicatorView!

    /// A reference to the DescopeFlowViewController for preloading the flow
    var flowViewController = DescopeFlowViewController()

    /// Marks whether the user pressed the sign in button and is waiting for the flow to be shown
    var shouldShowFlow = false

    // Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // start the flow immediately when the controller is created
        startFlow()
    }

    // Actions

    @IBAction func didPressSignIn() {
        print("Starting sign in with flow")

        switch flowViewController.state {
        case .initial, .failed:
            // the flow hasn't be started or needs to be restarted after failure
            shouldShowFlow = true
            startFlow()
            showLoadingStarted()
        case .started:
            // the flow has already been started, so just wait until it's ready
            shouldShowFlow = true
            showLoadingStarted()
        case .ready:
            // the flow is ready so present it immediately
            presentFlow()
        case .finished:
            break // shouldn't happen
        }
    }

    // Flow

    func startFlow() {
        let url = URL(string: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in")!
        let flow = DescopeFlow(url: url)
        flowViewController.delegate = self
        flowViewController.start(flow: flow)
    }

    func presentFlow() {
        // the DescopeFlowViewController is usually wrapped in a navigation controller
        let nav = UINavigationController(rootViewController: flowViewController)

        // we add a presentation delegate to the navigation controller to get notified
        // if the user dismisses the DescopeFlowViewController by swiping it down (rather
        // than pressing the Cancel button)
        nav.presentationController?.delegate = self

        // shows the DescopeFlowViewController modally from the bottom of the screen
        present(nav, animated: true)
    }

    func resetFlow() {
        // clear the delegate from any previous view controller
        flowViewController.delegate = nil

        // override the flow view controller with a new one so if the user taps
        // the Sign In button again they'll get a new flow
        flowViewController = DescopeFlowViewController()
    }

    // Results

    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    func showHome() {
        AppInterface.transitionToHomeScreen(in: view.window)
    }

    // Animations

    func showLoadingStarted() {
        UIView.animate(withDuration: 0.2) { [self] in
            signinButton.isUserInteractionEnabled = false
            signinButton.setTitle("", for: .normal)
            signinActivityIndicator.alpha = 1
        }
    }

    func showLoadingFinished() {
        UIView.animate(withDuration: 0.2) { [self] in
            signinButton.isUserInteractionEnabled = true
            signinButton.setTitle("Sign In", for: .normal)
            signinActivityIndicator.alpha = 0
        }
    }
}

extension ModalFlowController: DescopeFlowViewControllerDelegate {
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState) {
        print("Flow state changed to \(state) from \(previous)")
    }
    
    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController) {
        // if the shouldShowFlow flag is true that means the user pressed the Sign In button
        // while the flow was still not ready, in which case we'll show it now
        print("Flow is ready")
        if shouldShowFlow {
            shouldShowFlow = false
            showLoadingFinished()
            presentFlow()
        }
    }
    
    func flowViewControllerShouldShowURL(_ controller: DescopeFlowViewController, url: URL, external: Bool) -> Bool {
        // we return true so that the DescopeFlowViewController does its builtin behavior
        // of opening the URL in the user's default browser app
        return true
    }
    
    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController) {
        // since the DescopeFlowViewController is at the root of its own navigation controller
        // stack it'll show a Cancel button as the left bar button.
        print("Authentication cancelled")
        controller.dismiss(animated: true)
        resetFlow()
    }
    
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError) {
        // it's important to pay attention that because we're preloading the flow, this delegate
        // function might be called BEFORE the DescopeFlowViewController is presented, most likely
        // due to a network error, and the implementation should be careful to work properly in
        // every case. In this example we dismiss the controller itself, which will do nothing
        // if it hasn't actually been presented yet.
        print("Authentication failed: \(error)")
        controller.dismiss(animated: true) // might not actually do anything, controller might not be presented
        resetFlow()

        // since the error might have happened before the flow was ready to be presented, we need
        // to reset the loading indicator to ensure the user can press the Sign In button again
        showLoadingFinished()

        // errors will usually be .networkError or .flowFailed
        showError(error)
    }
    
    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse) {
        // authentication succeeded so we create a new DescopeSession, give it to the session
        // manager, and transition to the user to the home screen
        print("Authentication finished")
        let session = DescopeSession(from: response)
        Descope.sessionManager.manageSession(session)
        showHome()
    }
}

extension ModalFlowController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("Authentication cancelled interactively")
        resetFlow()
    }
}
