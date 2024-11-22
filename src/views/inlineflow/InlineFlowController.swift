
import UIKit
import DescopeKit

class InlineFlowController: UIViewController {
    @IBOutlet var welcomeView: UIView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var signinButton: UIButton!
    @IBOutlet var signinActivityIndicator: UIActivityIndicatorView!

    /// A reference to the DescopeFlowView for preloading the flow
    var flowView = DescopeFlowView()

    /// Marks whether the user pressed the sign in button and is waiting for the flow to be shown
    var shouldShowFlow = false

    // Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // add the DescopeFlowView into the controller's view hierarchy
        addFlowView()

        // start the flow immediately when the controller is created
        startFlow()
    }

    // Actions

    @IBAction func didPressSignIn() {
        print("Starting sign in with flow")

        switch flowView.state {
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
            // the flow is ready so show it immediately
            showFlowView()
        case .finished:
            break // shouldn't happen
        }
    }

    // Flow

    func startFlow() {
        let url = URL(string: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in-otp")!
        let flow = DescopeFlow(url: url)
        flowView.delegate = self
        flowView.start(flow: flow)
    }

    func addFlowView() {
        flowView.frame = containerView.bounds
        flowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(flowView)
    }

    func resetFlowView() {
        // revert back to show the welcome screen
        showWelcomeView()

        // clear the delegate from any previous view controller and remove it from the view
        flowView.delegate = nil
        flowView.removeFromSuperview()

        // override the flow view with a new one so if the user taps the Sign In button
        // again they'll get a new flow
        flowView = DescopeFlowView()
        addFlowView()
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

    func showFlowView() {
        // only animate the flow view in if it's still hidden
        guard containerView.isHidden else { return }
        containerView.isHidden = false

        // start the animation with a scaled down and transparent container for the flow view
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        // fade out and scale down the welcome view
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: { [self] in
            welcomeView.alpha = 0
            welcomeView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }, completion: nil)

        // fade in and scale up the container for the flow view
        UIView.animate(withDuration: 0.3, delay: 0.1, options: [.curveEaseOut], animations: { [self] in
            containerView.alpha = 1
            containerView.transform = .identity
        }, completion: nil)
    }

    func showWelcomeView() {
        containerView.isHidden = true
        welcomeView.alpha = 1
        welcomeView.transform = .identity
    }
}

extension InlineFlowController: DescopeFlowViewDelegate {
    func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState) {
        print("Flow state changed to \(state) from \(previous)")
    }
    
    func flowViewDidBecomeReady(_ flowView: DescopeFlowView) {
        // if the shouldShowFlow flag is true that means the user pressed the Sign In button
        // while the flow was still not ready, in which case we'll show it now
        if shouldShowFlow {
            shouldShowFlow = false
            showLoadingFinished()
            showFlowView()
        }
    }
    
    func flowViewDidInterceptNavigation(_ flowView: DescopeFlowView, url: URL, external: Bool) {
        // if there are web links in our flow and the user taps one of them we simply open
        // it in the user's default browser app
        UIApplication.shared.open(url)
    }

    func flowViewDidFailAuthentication(_ flowView: DescopeFlowView, error: DescopeError) {
        // it's important to pay attention that because we're preloading the flow, this delegate
        // function might be called BEFORE the DescopeFlowView is actually shown, most likely due
        // to a network error, and the implementation should be careful to work properly in every
        // case. In this example resetFlowView will just hide the flow view and show the welcome
        // view again which will do nothing if the flow view hasn't actually been shown yet.
        print("Authentication failed: \(error)")
        resetFlowView()

        // since the error might have happened before the flow was ready to be presented, we need
        // to reset the loading indicator to ensure the user can press the Sign In button again
        showLoadingFinished()

        // errors will usually be .networkError or .flowFailed
        showError(error)
    }
    
    func flowViewDidFinishAuthentication(_ flowView: DescopeFlowView, response: AuthenticationResponse) {
        let session = DescopeSession(from: response)
        Descope.sessionManager.manageSession(session)
        print("Authentication finished")
        showHome()
    }
}
