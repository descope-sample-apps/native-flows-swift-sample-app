
import UIKit
import DescopeKit

class SimpleFlowController: UIViewController {

    /// This action is called when the user taps the Sign In button
    @IBAction func didPressSignIn() {
        print("Starting sign in with flow")
        showFlow()
    }

    /// Creates a new DescopeFlowViewController, loads the flow into it, and pushes
    /// it onto the navigation controller stack
    func showFlow() {
        // create a new flow object
        let flow = DescopeFlow(url: "https://api.descope.com/login/\(Descope.config.projectId)?flow=sign-up-or-in")

        // create a new DescopeFlowViewController and start loading the flow
        let flowViewController = DescopeFlowViewController()
        flowViewController.delegate = self
        flowViewController.start(flow: flow)

        // push the view controller onto the navigation controller
        navigationController?.pushViewController(flowViewController, animated: true)
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
}

extension SimpleFlowController: DescopeFlowViewControllerDelegate {
    func flowViewControllerDidUpdateState(_ controller: DescopeFlowViewController, to state: DescopeFlowState, from previous: DescopeFlowState) {
        print("Flow state changed to \(state) from \(previous)")
    }
    
    func flowViewControllerDidBecomeReady(_ controller: DescopeFlowViewController) {
        // in this example we don't need to handle the ready event because we're
        // just showing the flow immediately without preloading it or anything
    }
    
    func flowViewControllerShouldShowURL(_ controller: DescopeFlowViewController, url: URL, external: Bool) -> Bool {
        // we return true so that the DescopeFlowViewController does its builtin behavior
        // of opening the URL in the user's default browser app
        return true
    }
    
    func flowViewControllerDidCancel(_ controller: DescopeFlowViewController) {
        // in this example the cancel button isn't shown and this function can't be called,
        // because the DescopeFlowViewController isn't at the root of its navigation controller
        // stack, and the user gets the default Back button to leave the flow screen
    }
    
    func flowViewControllerDidFail(_ controller: DescopeFlowViewController, error: DescopeError) {
        print("Authentication failed: \(error)")
        
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
