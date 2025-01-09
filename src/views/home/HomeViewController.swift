
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
        guard let session = Descope.sessionManager.session else { return }
        Descope.sessionManager.clearSession()
        Task {
            try? await Descope.auth.revokeSessions(.currentSession, refreshJwt: session.refreshJwt)
        }
    }

    // Views

    func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    func showAuth() {
        AppInterface.transitionToAuthScreen(from: self)
    }
}
