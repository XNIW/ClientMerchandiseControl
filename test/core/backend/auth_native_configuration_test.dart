import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = Directory.current.path;

  test(
    'Android non espone callback Auth privata e mantiene Storefront isolato',
    () {
      final manifest = File(
        '$repositoryRoot/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(_count(manifest, 'android.intent.action.VIEW'), 1);
      expect(
        _count(manifest, 'android:scheme="com.xniw.clientmerchandisecontrol"'),
        1,
      );
      expect(_count(manifest, 'android:host="auth-callback"'), 0);
      expect(_count(manifest, 'android:host="storefront"'), 1);
      expect(_count(manifest, 'android:path="/"'), 0);
      expect(_count(manifest, 'android:pathPrefix="/"'), 1);
      expect(manifest, contains('android:allowBackup="false"'));
      expect(
        manifest,
        matches(
          RegExp(
            r'android:name="flutter_deeplinking_enabled"\s+'
            r'android:value="false"',
          ),
        ),
      );
      expect(manifest, isNot(contains('android:autoVerify')));
      expect(manifest, isNot(contains('android:pathPattern')));
      expect(manifest, isNot(contains('android:scheme="http"')));
      expect(manifest, isNot(contains('android:scheme="https"')));
      expect(manifest, isNot(contains('*')));

      final mainActivity = File(
        '$repositoryRoot/android/app/src/main/kotlin/'
        'com/xniw/clientmerchandisecontrol/MainActivity.kt',
      ).readAsStringSync();
      final notificationMapper = File(
        '$repositoryRoot/android/app/src/main/kotlin/'
        'com/xniw/clientmerchandisecontrol/'
        'CustomerNotificationDeepLinkMapper.kt',
      ).readAsStringSync();
      expect(mainActivity, contains('mapNotificationDeepLink(intent)'));
      expect(_count(mainActivity, 'mapNotificationDeepLink(intent)'), 2);
      expect(
        mainActivity,
        contains('override fun onNewIntent(intent: Intent)'),
      );
      expect(mainActivity, contains('intent.data = Uri.parse(canonical)'));
      expect(mainActivity, contains('intent.removeExtra("deepLink")'));
      expect(
        notificationMapper,
        contains('fun canonicalDeepLink(raw: String?): String? = null'),
      );
      expect(notificationMapper, isNot(contains('java.net.URI')));
      expect(notificationMapper, isNot(contains('/notification/')));
      expect(notificationMapper, isNot(contains('orderId')));
    },
  );

  test('iOS registra il custom scheme solo per Storefront', () {
    final plist = File(
      '$repositoryRoot/ios/Runner/Info.plist',
    ).readAsStringSync();
    final appDelegate = File(
      '$repositoryRoot/ios/Runner/AppDelegate.swift',
    ).readAsStringSync();
    final sceneDelegate = File(
      '$repositoryRoot/ios/Runner/SceneDelegate.swift',
    ).readAsStringSync();
    final notificationMapper = File(
      '$repositoryRoot/ios/Runner/CustomerNotificationDeepLinkMapper.swift',
    ).readAsStringSync();

    expect(_count(plist, '<key>CFBundleURLTypes</key>'), 1);
    expect(
      _count(plist, '<string>com.xniw.clientmerchandisecontrol</string>'),
      1,
    );
    expect(plist, contains('com.xniw.clientmerchandisecontrol.storefront'));
    expect(plist, isNot(contains('com.xniw.clientmerchandisecontrol.auth')));
    expect(
      plist,
      matches(RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>')),
    );
    expect(plist, isNot(contains('com.apple.developer.associated-domains')));
    expect(plist, isNot(contains('applinks:')));
    expect(plist, isNot(contains('REVERSED_CLIENT_ID')));
    expect(
      notificationMapper,
      contains(
        'static func map(userInfo _: [AnyHashable: Any]) -> URL? { nil }',
      ),
    );
    expect(notificationMapper, isNot(contains('/notification/')));
    expect(appDelegate, contains('AppLinks.shared.enabled = false'));
    expect(_count(appDelegate, 'AppLinks.shared.handleLink(url:'), 2);
    expect(
      appDelegate,
      contains('options: [UIApplication.OpenURLOptionsKey: Any] = [:]'),
    );
    expect(_count(sceneDelegate, 'AppLinks.shared.handleLink(url:'), 5);
    expect(
      sceneDelegate,
      contains('openURLContexts URLContexts: Set<UIOpenURLContext>'),
    );
    expect(sceneDelegate, contains('willConnectTo session: UISceneSession'));
    expect(
      appDelegate,
      contains('UNUserNotificationCenter.current().delegate = self'),
    );
    expect(
      appDelegate,
      contains(
        'response.actionIdentifier == UNNotificationDefaultActionIdentifier',
      ),
    );
    expect(sceneDelegate, contains('connectionOptions.notificationResponse'));
    expect(sceneDelegate, contains('CustomerNotificationDeepLinkMapper.map('));
  });
}

int _count(String value, String pattern) {
  return pattern.allMatches(value).length;
}
