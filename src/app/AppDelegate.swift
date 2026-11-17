
import UIKit
import UserNotifications
import DescopeKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // we fetch the required Descope config values from the project settings, but you
        // can pass constant String values to the `Descope.setup` call as well
        let localProjectId = Bundle.main.infoDictionary?["myProjectId"] as! String
        let localBaseURL = Bundle.main.infoDictionary?["myBaseURL"] as! String

        // initialize the Descope SDK before using it
        Descope.setup(projectId: localProjectId) { config in
            config.baseURL = localBaseURL
            config.logger = .basicLogger
        }

        // set before returning so a notification tap that launched the app is delivered
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs device token: \(deviceToken.map { String(format: "%02x", $0) }.joined())")
        PushEnrollment.enroll(deviceToken: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Push registration failed: \(error)")
    }
}

/// Enrolls this device with Descope for push, the same enrollment push sign-in uses, so the backend
/// can reach it with CIBA approval requests. Called each time the signed in home screen loads, since
/// the token is enrolled for the signed in user.
@MainActor
enum PushEnrollment {
    static func enrollIfSignedIn() {
        guard Descope.sessionManager.session != nil else { return }
        Task {
            // asked in context after sign in rather than at launch
            guard (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) == true else { return }
            // the simulator gets real sandbox APNs tokens too (Apple silicon, macOS 13+)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    static func enroll(deviceToken: Data) {
        enroll { refreshJwt in
            try await Descope.push.enroll(deviceToken: deviceToken, refreshJwt: refreshJwt)
        }
    }

    private static func enroll(_ call: @escaping (String) async throws -> Void) {
        guard let refreshJwt = Descope.sessionManager.session?.refreshJwt else { return }
        Task {
            do {
                try await call(refreshJwt)
                print("Enrolled for push")
            } catch {
                print("Push enrollment failed: \(error)")
            }
        }
    }
}

/// iOS 27 traps at launch for apps that don't adopt the scene lifecycle, so the window lives here.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // show home screen if user is already logged in, otherwise show authentication screen
        let initialViewController: UIViewController
        if let session = Descope.sessionManager.session, !session.refreshToken.isExpired {
            initialViewController = AppInterface.createHomeScreen()
        } else {
            initialViewController = AppInterface.createAuthScreen()
        }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = initialViewController
        window?.makeKeyAndVisible()
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        // pass any incoming Universal Links to the current flow in case we're
        // using Magic Link authentication in the flows
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL else { return }
        _ = Descope.handleURL(url)
    }
}

extension AppDelegate: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        if content.categoryIdentifier == DescopeCIBARequest.category {
            CIBAController.handleNotification(response.notification)
        }
        completionHandler()
    }
}
