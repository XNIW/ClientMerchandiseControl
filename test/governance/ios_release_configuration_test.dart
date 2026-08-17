import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = Directory.current.path;

  test('iOS release source uses canonical identity and Release archive', () {
    final project = File(
      '$repositoryRoot/ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    final scheme = File(
      '$repositoryRoot/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme',
    ).readAsStringSync();

    expect(
      project,
      contains(
        'PRODUCT_BUNDLE_IDENTIFIER = com.xniw.clientmerchandisecontrol;',
      ),
    );
    expect(project, contains('CURRENT_PROJECT_VERSION = 1;'));
    expect(project, contains('DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";'));
    expect(scheme, contains('buildForArchiving = "YES"'));
    expect(scheme, contains('buildConfiguration = "Release"'));
  });

  test('production-like configuration remains public and fail-closed', () {
    final values =
        jsonDecode(
              File(
                '$repositoryRoot/config/app_config.production.release.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final releaseConfig = File(
      '$repositoryRoot/ios/Flutter/Release.xcconfig',
    ).readAsStringSync();

    expect(values['APP_ENV'], 'production');
    expect(values['GOOGLE_AUTH_ENABLED'], 'false');
    expect(values['DELIVERY_MAPS_ENABLED'], 'false');
    expect(values['DELIVERY_MAPS_NATIVE_CONFIGURED'], 'false');
    expect(values, isNot(contains('SUPABASE_URL')));
    expect(values, isNot(contains('SUPABASE_PUBLISHABLE_KEY')));
    expect(values, isNot(contains('AUTH_REDIRECT_URI')));
    expect(values, isNot(contains('STOREFRONT_SHOP_SLUG')));
    expect(releaseConfig, contains('IOS_GOOGLE_MAPS_API_KEY=NOT_CONFIGURED'));
  });

  test('native callback is bounded and provider deep linking is disabled', () {
    final info = File(
      '$repositoryRoot/ios/Runner/Info.plist',
    ).readAsStringSync();
    final entitlements = Directory('$repositoryRoot/ios/Runner')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.entitlements'));

    expect(
      info,
      contains('<string>com.xniw.clientmerchandisecontrol</string>'),
    );
    expect(info, contains('<key>FlutterDeepLinkingEnabled</key>'));
    expect(info, contains('<false/>'));
    expect(entitlements, isEmpty);
  });

  test('release validator binds app archive dSYM privacy and security', () {
    final validator = File(
      '$repositoryRoot/scripts/check-ios-release.sh',
    ).readAsStringSync();

    expect(validator, contains('ARTIFACT_BUNDLE_IDENTIFIER_MISMATCH'));
    expect(validator, contains('APP_PRIVACY_MANIFEST_MISMATCH'));
    expect(validator, contains('DEPENDENCY_PRIVACY_MANIFEST_MISSING'));
    expect(validator, contains('ARCHIVE_DSYM_UUID_MISMATCH'));
    expect(validator, contains('APP_ARCHIVE_BUNDLE_MISMATCH'));
    expect(validator, contains('APP_EXECUTABLE_NAME_INVALID'));
    expect(validator, contains('ARTIFACT_SIGNATURE_INVALID'));
    expect(validator, contains('SIGNED_ENTITLEMENT_SET_INVALID'));
    expect(validator, contains('MAPS_ARTIFACT_NOT_FAIL_CLOSED'));
    expect(validator, contains('check-client-security.sh'));
    expect(validator, isNot(contains('/Users/')));
  });

  test('TestFlight gate validates distribution identity and profile', () {
    final validator = File(
      '$repositoryRoot/scripts/check-ios-release.sh',
    ).readAsStringSync();

    for (final boundary in <String>[
      'TESTFLIGHT_REQUIRES_DISTRIBUTION_SIGNATURE',
      'TESTFLIGHT_PROVISIONING_PROFILE_MISSING',
      'APPLE_DISTRIBUTION_CERTIFICATE_REQUIRED',
      'SIGNING_FINGERPRINT_MISMATCH',
      'PROVISIONING_TEAM_MISMATCH',
      'APP_STORE_PROVISIONING_PROFILE_REQUIRED',
      'SIGNED_APPLICATION_IDENTIFIER_MISMATCH',
      'DEVELOPMENT_PROVISIONING_PROFILE_REJECTED',
      'APP_STORE_CONNECT_API_KEY_INVALID',
      'TESTFLIGHT_RUNTIME_CONFIG_MISSING',
      'TESTFLIGHT_RUNTIME_CONFIG_NOT_ARTIFACT_BOUND',
      'IOS_TESTFLIGHT_UPLOAD_INPUTS_VALIDATED',
    ]) {
      expect(validator, contains(boundary), reason: boundary);
    }
  });

  test('CI builds and validates an unsigned Release archive', () {
    final workflow = File(
      '$repositoryRoot/.github/workflows/ci.yml',
    ).readAsStringSync();

    final job = _yamlJobBlock(workflow, 'ios-release');
    expect(job, contains('name: iOS release candidate'));
    expect(job, contains('runs-on: macos-latest'));
    expect(job, contains('flutter build ios --release --no-codesign'));
    expect(job, contains('xcodebuild archive'));
    expect(job, contains('check-ios-release.sh'));
    expect(job, contains('CODE_SIGNING_ALLOWED=NO'));
  });

  test(
    'CI release evidence cannot be satisfied by comments outside the job',
    () {
      const workflow = '''
jobs:
  quality:
    runs-on: ubuntu-latest
# ios-release:
# iOS release candidate
# flutter build ios --release --no-codesign
# xcodebuild archive
# check-ios-release.sh
# CODE_SIGNING_ALLOWED=NO
''';

      expect(_yamlJobBlock(workflow, 'ios-release'), isEmpty);
    },
  );
}

String _yamlJobBlock(String workflow, String jobName) {
  final lines = const LineSplitter().convert(workflow);
  final start = lines.indexWhere((line) => line == '  $jobName:');
  if (start < 0) {
    return '';
  }
  final end = lines.indexWhere(
    (line) => RegExp(r'^  [a-zA-Z0-9_-]+:$').hasMatch(line),
    start + 1,
  );
  return lines
      .sublist(start, end < 0 ? lines.length : end)
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n');
}
