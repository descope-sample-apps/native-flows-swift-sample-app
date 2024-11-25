
import UIKit
import DescopeKit

class EnchantedLinkController: UIViewController {

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var emailButton: UIButton!
    @IBOutlet var loadingContainer: UIStackView!
    @IBOutlet var linkSentLabel: UILabel!

    // Actions

    @IBAction func didPressSignIn() {
        // get the email address from the text field
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespaces), !email.isEmpty else {
            emailTextField.becomeFirstResponder()
            return
        }

        // ready to start the sign in
        print("Starting sign in with email address: \(email)")
        Task {
            await startSignIn(email: email)
        }
    }


    // Authentication

    func startSignIn(email: String) async {
        // update the state of the user interface as we've started a chain of async operations
        showLoadingStarted()

        // whatever happens release the user interface back to regular state afterwards
        defer { showLoadingFinished() }

        do {
            // try performing the enchanted link authentication and handle errors appropriately
            try await performEnchantedLink(email: email)

            // if we get here then the authentication finished successfully, move to the home screen
            showHome()
        } catch DescopeError.networkError {
            showError(message: "There is no internet connection")
        } catch DescopeError.enchantedLinkExpired {
            showError(message: "The authentication has expired")
        } catch {
            showError(error)
        }
    }

    func performEnchantedLink(email: String) async throws {
        // Starts the authentication, triggering an email getting sent to the user's
        // email address with a link they must press
        let startResponse = try await Descope.enchantedLink.signUpOrIn(loginId: email, redirectURL: nil, options: [])

        print("Started enchanted link authentication with linkId: \(startResponse.linkId)")
        showLinkText(startResponse.linkId)

        // An asynchronous operation that returns once the user presses the link
        // in the email, or fails with a timeout after a period of time
        let authResponse = try await Descope.enchantedLink.pollForSession(pendingRef: startResponse.pendingRef, timeout: nil)

        // A simple conversion from the AuthenticationResponse data type to a
        // DescopeSession object that represents the user's signed in session
        let session = DescopeSession(from: authResponse)

        print("Created new signin session: \(session): \(session.user)")

        // Passes the session object to the default sessionManager, effectively causing
        // the session to be kept refreshed and saving to the keychain so it can be loaded
        // on the next app launch
        Descope.sessionManager.manageSession(session)
    }

    // Results

    func showError(title: String = "Error", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    func showError(_ error: Error) {
        showError(message: error.localizedDescription)
    }

    func showHome() {
        AppInterface.transitionToHomeScreen(from: view.window!.rootViewController!)
    }

    // Animations

    func showLoadingStarted() {
        UIView.animate(withDuration: 0.2) { [self] in
            emailTextField.isEnabled = false
            emailButton.isUserInteractionEnabled = false
            emailButton.setTitle("", for: .normal)
            loadingContainer.alpha = 1
        }
    }

    func showLinkText(_ value: String) {
        UIView.animate(withDuration: 0.2) { [self] in
            linkSentLabel.text = "Email sent with link number \(value)"
            linkSentLabel.alpha = 1
        }
    }

    func showLoadingFinished() {
        UIView.animate(withDuration: 0.2) { [self] in
            emailTextField.isEnabled = true
            emailButton.isUserInteractionEnabled = true
            emailButton.setTitle("Sign In", for: .normal)
            loadingContainer.alpha = 0
            linkSentLabel.text = ""
            linkSentLabel.alpha = 0
        }
    }
}
