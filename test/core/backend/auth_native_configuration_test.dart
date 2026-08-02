import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = Directory.current.path;

  test(
    'Android separa callback Auth e deep link Storefront con backup off',
    () {
      final manifest = File(
        '$repositoryRoot/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(_count(manifest, 'android.intent.action.VIEW'), 2);
      expect(
        _count(manifest, 'android:scheme="com.xniw.clientmerchandisecontrol"'),
        2,
      );
      expect(_count(manifest, 'android:host="auth-callback"'), 1);
      expect(_count(manifest, 'android:host="storefront"'), 1);
      expect(_count(manifest, 'android:path="/"'), 1);
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
    },
  );

  test('iOS registra un solo custom scheme e disabilita handler Flutter', () {
    final plist = File(
      '$repositoryRoot/ios/Runner/Info.plist',
    ).readAsStringSync();
    final appDelegate = File(
      '$repositoryRoot/ios/Runner/AppDelegate.swift',
    ).readAsStringSync();
    final sceneDelegate = File(
      '$repositoryRoot/ios/Runner/SceneDelegate.swift',
    ).readAsStringSync();

    expect(_count(plist, '<key>CFBundleURLTypes</key>'), 1);
    expect(
      _count(plist, '<string>com.xniw.clientmerchandisecontrol</string>'),
      1,
    );
    expect(
      plist,
      matches(RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>')),
    );
    expect(plist, isNot(contains('com.apple.developer.associated-domains')));
    expect(plist, isNot(contains('applinks:')));
    expect(plist, isNot(contains('REVERSED_CLIENT_ID')));
    expect(appDelegate, contains('AppLinks.shared.enabled = false'));
    expect(_count(appDelegate, 'AppLinks.shared.handleLink(url:'), 1);
    expect(
      appDelegate,
      contains('options: [UIApplication.OpenURLOptionsKey: Any] = [:]'),
    );
    expect(_count(sceneDelegate, 'AppLinks.shared.handleLink(url:'), 4);
    expect(
      sceneDelegate,
      contains('openURLContexts URLContexts: Set<UIOpenURLContext>'),
    );
    expect(sceneDelegate, contains('willConnectTo session: UISceneSession'));
  });
}

int _count(String value, String pattern) {
  return pattern.allMatches(value).length;
}
