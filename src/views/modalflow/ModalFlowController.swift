
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

        // start the flow immediately when the controller is created so that ideally the user
        // won't experience any loading times or layout updates when the flow is shown
        startFlow()
    }

    // Actions

    @IBAction func didPressSignIn() {
        print("Starting sign in with flow")

        switch flowViewController.state {
        case .initial, .failed:
            // the flow hasn't been started or needs to be restarted
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
        // create a new flow object
        let flow = DescopeFlow(url: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in")
        
        // we present the flow full screen so we use a flow hook to disable scrolling
        flow.hooks = [
            .setupScrollView({ scrollView in
                scrollView.isScrollEnabled = false
                scrollView.contentInsetAdjustmentBehavior = .never
            }),
        ]

        // start loading the flow
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
        AppInterface.transitionToHomeScreen(from: self)
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
        print("Authentication cancelled")

        // since the DescopeFlowViewController is at the root of its own navigation controller
        // stack it'll show a Cancel button as the left bar button.
        controller.dismiss(animated: true)

        // make sure the user gets a new flow if they press the Sign In button again, rather than
        // the same DescopeFlowViewController instance that the user cancelled
        resetFlow()
    }
    
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError) {
        print("Authentication failed: \(error)")

        // it's important to note that because we're preloading the flow, this delegate function
        // might be called BEFORE the DescopeFlowViewController is presented, most likely due
        // to a network error, and the implementation should be careful to work properly in
        // every case. In this example we dismiss the controller itself, which will do
        // nothing if it hasn't actually been presented yet.
        controller.dismiss(animated: true)

        // make sure the user gets a new flow if they press the Sign In button again, rather than
        // the same DescopeFlowViewController instance that already failed
        resetFlow()

        // since the error might have happened before the flow was ready to be presented, we need
        // to reset the loading indicator to ensure the user can press the Sign In button again
        showLoadingFinished()

        // errors will usually be DescopeError.networkError or DescopeError.flowFailed
        showError(error)
    }
    
    func flowViewControllerDidFinish(_ controller: DescopeFlowViewController, response: AuthenticationResponse) {
        print("Authentication finished")

        // authentication succeeded so we can create a new DescopeSession and set it on the
        // session manager, which is effectively what we consider as the user being signed in
        // to the application
        let session = DescopeSession(from: response)
        Descope.sessionManager.manageSession(session)

        // finally, transition the user to the home screen
        showHome()
    }
}

extension ModalFlowController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("Authentication cancelled interactively")

        // same handling as the cancellation above, in this case the user has already dismissed
        // the flow view controller by swiping it down, so we only need to do the reset
        resetFlow()
    }
}
