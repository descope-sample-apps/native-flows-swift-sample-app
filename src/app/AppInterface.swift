
import UIKit

/// Which authentication screen to show when the app runs
@MainActor
var appInterface = AppInterface.modalFlow

/// The kinds of authentication screens supported by the app
@MainActor
enum AppInterface {
    /// Display a native authentication view for doing enchanted link with email
    case enchantedLink

    /// A very simple example of authentication with flows by pushing a
    /// DescopeFlowViewController onto a UINavigationController stack
    case simpleFlow

    /// A more complex example of authentication with flows that creates a
    /// DescopeFlowViewController and preloads the flow in the background,
    /// so that when the user presses the Sign In button the flow is
    /// already fully ready
    case modalFlow

    /// A more complex example of authentication with flows that creates a
    /// DescopeFlowView instead of a controller, embeds the view into
    /// the view hierarchy, and shows it with a custom animation
    case inlineFlow
}

/// Convenience functions for creating view controllers
extension AppInterface {
    static func createAuthScreen() -> UIViewController {
        let vc: UIViewController
        switch appInterface {
        case .enchantedLink: vc = EnchantedLinkController()
        case .simpleFlow: vc = SimpleFlowController()
        case .modalFlow: vc = ModalFlowController()
        case .inlineFlow: vc = InlineFlowController()
        }
        return UINavigationController(rootViewController: vc)
    }

    static func createHomeScreen() -> UIViewController {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        let nav = UINavigationController(rootViewController: HomeViewController())
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        return nav
    }
}

/// Convenience functions for transitioning between screens
extension AppInterface {
    static func transitionToAuthScreen(from: UIViewController) {
        transition(from: from, to: createAuthScreen())
    }

    static func transitionToHomeScreen(from: UIViewController) {
        transition(from: from, to: createHomeScreen())
    }

    private static func transition(from: UIViewController, to: UIViewController) {
        // transition from the window of the calling view controller
        let viewControllerWindow = from.viewIfLoaded?.window

        // alternatively, transition from the window of the navigation controller if the calling
        // view controller's is not currently visible
        let navigationControllerWindow = from.navigationController?.viewIfLoaded?.window

        // we must have a window to perform the transition on
        guard let window = viewControllerWindow ?? navigationControllerWindow else { preconditionFailure("Attempt to transition without a window") }

        UIView.transition(with: window, duration: 1, options: .transitionFlipFromRight) {
            window.rootViewController = to
        }
    }
}
