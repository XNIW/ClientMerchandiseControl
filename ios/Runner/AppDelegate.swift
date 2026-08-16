import Flutter
import GoogleMaps
import UIKit
import UserNotifications
import app_links

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deliveryMapConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    if let mapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String,
      !mapsApiKey.isEmpty,
      mapsApiKey != "NOT_CONFIGURED"
    {
      GMSServices.provideAPIKey(mapsApiKey)
      deliveryMapConfigured = true
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    _ = super.application(application, open: url, options: options)
    AppLinks.shared.handleLink(url: url)
    return true
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    AppLinks.shared.enabled = false
    let channel = FlutterMethodChannel(
      name: "com.xniw.clientmerchandisecontrol/delivery_map_configuration",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "isConfigured" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.deliveryMapConfigured == true)
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
      let url = CustomerNotificationDeepLinkMapper.map(
        userInfo: response.notification.request.content.userInfo
      )
    else {
      super.userNotificationCenter(
        center,
        didReceive: response,
        withCompletionHandler: completionHandler
      )
      return
    }
    AppLinks.shared.handleLink(url: url)
    completionHandler()
  }
}
