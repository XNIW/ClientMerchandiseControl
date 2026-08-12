import Flutter
import UIKit
import UserNotifications
import app_links

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    for context in connectionOptions.urlContexts {
      AppLinks.shared.handleLink(url: context.url)
    }
    for userActivity in connectionOptions.userActivities {
      if let url = userActivity.webpageURL {
        AppLinks.shared.handleLink(url: url)
      }
    }
    if let response = connectionOptions.notificationResponse,
      response.actionIdentifier == UNNotificationDefaultActionIdentifier,
      let url = CustomerNotificationDeepLinkMapper.map(
        userInfo: response.notification.request.content.userInfo
      )
    {
      AppLinks.shared.handleLink(url: url)
    }
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    super.scene(scene, openURLContexts: URLContexts)

    for context in URLContexts {
      AppLinks.shared.handleLink(url: context.url)
    }
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    super.scene(scene, continue: userActivity)

    if let url = userActivity.webpageURL {
      AppLinks.shared.handleLink(url: url)
    }
  }
}
