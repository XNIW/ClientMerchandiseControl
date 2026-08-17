import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = Directory.current;

  test('release usa R8, resource shrink e signing esterno fail-closed', () {
    final gradle = File(
      '${repositoryRoot.path}/android/app/build.gradle.kts',
    ).readAsStringSync();

    expect(gradle, contains('isMinifyEnabled = true'));
    expect(gradle, contains('isShrinkResources = true'));
    expect(gradle, contains('proguard-android-optimize.txt'));
    expect(gradle, contains('proguard-rules.pro'));
    expect(gradle, contains('ANDROID_KEYSTORE_PATH'));
    expect(gradle, contains('ANDROID_KEYSTORE_PASSWORD'));
    expect(gradle, contains('ANDROID_KEY_ALIAS'));
    expect(gradle, contains('ANDROID_KEY_PASSWORD'));
    expect(gradle, contains('releaseSigningValues.none'));
    expect(gradle, isNot(contains('signingConfigs.getByName("debug")')));
  });

  test('manifest release vieta cleartext con sole CA di sistema', () {
    final manifest = File(
      '${repositoryRoot.path}/android/app/src/release/AndroidManifest.xml',
    ).readAsStringSync();
    final networkPolicy = File(
      '${repositoryRoot.path}/android/app/src/release/res/xml/network_security_config.xml',
    ).readAsStringSync();

    expect(manifest, contains('android:usesCleartextTraffic="false"'));
    expect(
      manifest,
      contains('android:networkSecurityConfig="@xml/network_security_config"'),
    );
    expect(networkPolicy, contains('cleartextTrafficPermitted="false"'));
    expect(networkPolicy, contains('<certificates src="system" />'));
    expect(networkPolicy, isNot(contains('src="user"')));
  });

  test(
    'production release template is public, provider-off and incomplete',
    () {
      final file = File(
        '${repositoryRoot.path}/config/app_config.production.release.json',
      );
      final values =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(values['APP_ENV'], 'production');
      expect(values['GOOGLE_AUTH_ENABLED'], 'false');
      expect(values['DELIVERY_MAPS_ENABLED'], 'false');
      expect(values['DELIVERY_MAPS_NATIVE_CONFIGURED'], 'false');
      expect(values, isNot(contains('SUPABASE_URL')));
      expect(values, isNot(contains('SUPABASE_PUBLISHABLE_KEY')));
      expect(values, isNot(contains('AUTH_REDIRECT_URI')));
      expect(values, isNot(contains('STOREFRONT_SHOP_SLUG')));
    },
  );

  test('validator separa firme AAB/APK e verifica identita bundle', () {
    final validator = File(
      '${repositoryRoot.path}/scripts/check-android-release.sh',
    ).readAsStringSync();

    expect(validator, contains('jarsigner -J-Duser.language=en'));
    expect(validator, contains('verify --print-certs'));
    expect(validator, contains('check_android_bundle_manifest.dart'));
    expect(validator, contains('AAB_APK_PAYLOAD_MISMATCH'));
    expect(validator, contains('AAB_APK_SIGNER_MISMATCH'));
    expect(
      'cmc_android_release_normalize_fingerprint'.allMatches(validator),
      hasLength(3),
    );
    expect(
      validator,
      contains("tr -d '[:space:]:' | tr '[:upper:]' '[:lower:]'"),
    );
    expect(validator, contains('AAB_SIGNING_FINGERPRINT_UNREADABLE'));
    expect(validator, contains('APK_SIGNING_FINGERPRINT_UNREADABLE'));
    expect(validator, isNot(contains('/Users/')));
  });

  test('upload preflight richiede signer e service account approvati', () {
    final validator = File(
      '${repositoryRoot.path}/scripts/check-android-release.sh',
    ).readAsStringSync();

    expect(validator, contains('ANDROID_SIGNING_CERT_SHA256'));
    expect(validator, contains('PLAY_SERVICE_ACCOUNT_EXPECTED_EMAIL'));
    expect(validator, contains('PLAY_SERVICE_ACCOUNT_EXPECTED_PROJECT_ID'));
    expect(validator, contains('PLAY_SERVICE_ACCOUNT_INVALID'));
    expect(validator, contains('ANDROID_INTERNAL_UPLOAD_INPUTS_VALIDATED'));
    expect(validator, isNot(contains('ANDROID_INTERNAL_UPLOAD_READY')));
  });
}
