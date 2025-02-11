
import UIKit
import DescopeKit

class HomeViewController: UIViewController {

    // Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Showing checkin screen")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign Out", style: .plain, target: self, action: #selector(didPressSignOut))
    }

    // Actions

    @objc func didPressSignOut() {
        print("Sign out pressed")
        clearSession()
        showAuth()
    }

    // Operations

    func clearSession() {
        // keep the session value before clearing it
        guard let session = Descope.sessionManager.session else { return }

        // clear the session from the manager, this effectively means the user
        // is logged out from the app
        Descope.sessionManager.clearSession()

        // we send a fire and forget asynchronous request to the Descope API to
        // revoke the session as it's not needed anymore
        Task {
            try? await Descope.auth.revokeSessions(.currentSession, refreshJwt: session.refreshJwt)
        }
    }

    // Views

    func showAuth() {
        AppInterface.transitionToAuthScreen(from: self)
    }
}
