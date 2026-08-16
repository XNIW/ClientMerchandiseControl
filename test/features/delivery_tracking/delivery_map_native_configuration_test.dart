import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android usa placeholder esterno, SDK 24 e nessuna chiave raw', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final activity = File(
      'android/app/src/main/kotlin/com/xniw/clientmerchandisecontrol/MainActivity.kt',
    ).readAsStringSync();

    expect(gradle, contains('ANDROID_GOOGLE_MAPS_API_KEY'));
    expect(gradle, contains('localProperties.getProperty("MAPS_API_KEY")'));
    expect(gradle, contains('minSdk = 24'));
    expect(gradle, contains('"NOT_CONFIGURED"'));
    expect(manifest, contains('com.google.android.geo.API_KEY'));
    expect(manifest, contains(r'${MAPS_API_KEY}'));
    expect(activity, contains('DELIVERY_MAP_CONFIGURATION_CHANNEL'));
    expect(activity, contains('call.method == "isConfigured"'));
    expect(activity, contains('apiKey != "NOT_CONFIGURED"'));
    expect(_containsGoogleApiKey('$gradle\n$manifest\n$activity'), isFalse);
  });

  test('iOS usa chiave locale ignorata, guard fail-closed e target 14', () {
    final debug = File('ios/Flutter/Debug.xcconfig').readAsStringSync();
    final release = File('ios/Flutter/Release.xcconfig').readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();
    final ignore = File('.gitignore').readAsStringSync();

    for (final config in [debug, release]) {
      expect(config, contains('IOS_GOOGLE_MAPS_API_KEY=NOT_CONFIGURED'));
      expect(config, contains('#include? "Maps.local.xcconfig"'));
    }
    expect(plist, contains(r'$(IOS_GOOGLE_MAPS_API_KEY)'));
    expect(delegate, contains('mapsApiKey != "NOT_CONFIGURED"'));
    expect(delegate, contains('GMSServices.provideAPIKey(mapsApiKey)'));
    expect(delegate, contains('deliveryMapConfigured = true'));
    expect(delegate, contains('call.method == "isConfigured"'));
    expect(delegate, contains('engineBridge.applicationRegistrar.messenger()'));
    expect(project, isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0')));
    expect(project, contains('IPHONEOS_DEPLOYMENT_TARGET = 14.0'));
    expect(podfile, contains("platform :ios, '14.0'"));
    expect(ignore, contains('/ios/Flutter/Maps.local.xcconfig'));
    expect(
      _containsGoogleApiKey('$debug\n$release\n$plist\n$delegate'),
      isFalse,
    );
  });
}

bool _containsGoogleApiKey(String value) =>
    RegExp(r'AIza[0-9A-Za-z_-]{20,}').hasMatch(value);
