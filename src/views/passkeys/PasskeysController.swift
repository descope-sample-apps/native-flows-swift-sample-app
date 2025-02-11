
import UIKit
import DescopeKit

class PasskeysController: UIViewController {

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var emailButton: UIButton!
    @IBOutlet var loadingContainer: UIStackView!

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
        // show the loading indicator as we've started a chain of async operations
        showLoadingStarted()

        // whatever happens hide the loading indicator after we're done
        defer { showLoadingFinished() }

        do {
            // try performing authentication with passkeys and handle errors appropriately
            try await performPasskeyAuthentication(email: email)

            // if we get here then the authentication finished successfully, move to the home screen
            showHome()
        } catch DescopeError.networkError {
            showError(message: "There is no internet connection")
        } catch DescopeError.passkeyCancelled {
            // authentication was cancelled by the user, a timeout, or programmatically, so no need to show error
        } catch let error as DescopeError where error == DescopeError.passkeyFailed {
            // usually a problem with how passkeys were configured in the project
            showError(title: "Passkey Error", message: error.localizedDescription)
        } catch {
            showError(error)
        }
    }

    func performPasskeyAuthentication(email: String) async throws {
        print("Starting passkey authentication with email: \(email)")

        // Starts the authentication, triggering a passkey dialog to pop up for the user
        //
        // IMPORTANT: You must setup passkeys in your app before this can work. Configure
        // your Passkey/WebAuthn settings in the Descope console (https://app.descope.com/settings/authentication/webauthn).
        // Make sure it is enabled and that the top level domain is configured correctly.
        // After that, go through Apple's Supporting passkeys (https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys/)
        // guide, in particular be sure to have an associated domain configured for your app
        // with the `webcredentials` service type, whose value matches the top level domain
        // you configured in the Descope console earlier.
        let authResponse = try await Descope.passkey.signUpOrIn(loginId: email, options: [])

        // A simple conversion from the AuthenticationResponse data type to a
        // DescopeSession object that represents the user's signed in session
        let session = DescopeSession(from: authResponse)

        print("Created new login session \(session) for user \(session.user)")

        // Passes the session object to the default sessionManager, effectively causing
        // the session to be kept refreshed and saving it to the keychain so it can be
        // loaded on the next app launch
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
        AppInterface.transitionToHomeScreen(from: self)
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

    func showLoadingFinished() {
        UIView.animate(withDuration: 0.2) { [self] in
            emailTextField.isEnabled = true
            emailButton.isUserInteractionEnabled = true
            emailButton.setTitle("Sign In", for: .normal)
            loadingContainer.alpha = 0
        }
    }
}
