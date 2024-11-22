
import UIKit

/// Which authentication screen to show when the app runs
@MainActor
var appInterface: AppInterface = .inlineFlow

/// Which kind of authentication UI the app should show
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

    /// A more compex example of authentication with flows that creates a
    /// DescopeFlowView instead of a controller, embeds the view into
    /// the view hierarchy, and shows it with a custom animation
    case inlineFlow
}

/// Convenience functions for creating view controllers
extension AppInterface {
    static var authScreen: UIViewController {
        let vc: UIViewController
        switch appInterface {
        case .enchantedLink: vc = EnchantedLinkController()
        case .simpleFlow: vc = SimpleFlowController()
        case .modalFlow: vc = ModalFlowController()
        case .inlineFlow: vc = InlineFlowController()
        }
        return UINavigationController(rootViewController: vc)
    }

    static var homeScreen: UIViewController {
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
    static func transitionToAuthScreen(in window: UIWindow?) {
        transition(window: window, to: authScreen)
    }

    static func transitionToHomeScreen(in window: UIWindow?) {
        transition(window: window, to: homeScreen)
    }

    private static func transition(window: UIWindow?, to viewController: UIViewController) {
        guard let window else { return }
        UIView.transition(with: window, duration: 1, options: .transitionFlipFromRight) {
            window.rootViewController = viewController
        }
    }
}

