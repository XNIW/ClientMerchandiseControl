import 'dart:convert';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/core/config/release_config_attestation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'digest TEST include host e byte canonici, ordine input irrilevante',
    () {
      final original = TestReleaseConfigAttestation.fromValues(_values);
      final reordered = TestReleaseConfigAttestation.fromValues(
        Map.fromEntries(_values.entries.toList().reversed),
      );
      expect(reordered.sha256, original.sha256);
      expect(
        original.marker,
        'CMC_TEST_CONFIG_ATTESTATION_V1:${original.sha256}',
      );
      for (final changed in [
        {..._values, 'STOREFRONT_SHOP_SLUG': 'storefront-other'},
        {..._values, 'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_other'},
        {
          ..._values,
          'AUTH_CALLBACK_VERIFIED_HOST': 'other.client.example.com',
          'AUTH_REDIRECT_URI':
              'https://other.client.example.com/auth-callback/',
        },
      ]) {
        expect(
          TestReleaseConfigAttestation.fromValues(changed).sha256,
          isNot(original.sha256),
        );
      }
    },
  );

  test('parser TEST conserva reject duplicate, unknown, malformed e size', () {
    for (final source in [
      jsonEncode(_values).replaceFirst('{', '{"APP_ENV":"staging",'),
      jsonEncode({..._values, 'TEST_CONFIG_SHA256': 'a' * 64}),
      jsonEncode({..._values, 'unknown': 'value'}),
      '{"APP_ENV":true}',
      '[]',
      ' ' * 65537,
    ]) {
      expect(
        () => TestReleaseConfigAttestation.fromBytes(utf8.encode(source)),
        throwsA(isA<ReleaseConfigValidationException>()),
      );
    }
  });

  test(
    'hash TEST opzionale staging, vietato altrove e distinto da production',
    () {
      final fingerprint = TestReleaseConfigAttestation.fromValues(
        _values,
      ).sha256;
      final staging = _config(testHash: fingerprint);
      expect(staging.testConfigSha256, fingerprint);
      expect(staging.releaseConfigSha256, isNull);
      expect(staging.sanitizedDiagnostics['testConfigurationAttested'], isTrue);
      expect(staging.sanitizedDiagnostics, isNot(containsValue(fingerprint)));
      expect(_config().testConfigSha256, isNull);
      for (final invalid in ['invalid', 'A' * 64]) {
        expect(
          () => _config(testHash: invalid),
          throwsA(isA<AppConfigurationException>()),
        );
      }
      for (final environment in ['development', 'production']) {
        expect(
          () => AppConfig.fromValues(
            appEnvironment: environment,
            testConfigSha256: fingerprint,
          ),
          throwsA(isA<AppConfigurationException>()),
        );
      }
      expect(
        () => _config(releaseHash: fingerprint),
        throwsA(isA<AppConfigurationException>()),
      );
    },
  );

  test('compiled TEST hash must match all compiled inputs', () {
    const expectedTest = bool.fromEnvironment('CMC_EXPECT_COMPILED_TEST');
    const expectedFailure = bool.fromEnvironment('CMC_EXPECT_TEST_FAILURE');
    const failureMessage = String.fromEnvironment(
      'CMC_EXPECT_FAILURE_CONTAINS',
    );
    if (expectedFailure) {
      expect(
        AppConfig.fromEnvironment,
        throwsA(
          isA<AppConfigurationException>().having(
            (error) => error.message,
            'message',
            contains(failureMessage),
          ),
        ),
      );
    } else if (expectedTest) {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.staging);
      expect(
        config.testConfigSha256,
        TestReleaseConfigAttestation.fromValues(_values).sha256,
      );
      expect(config.googleAuthEnabled, isTrue);
    } else {
      final config = AppConfig.fromEnvironment();
      expect(config.environment, AppEnvironment.development);
      expect(config.testConfigSha256, isNull);
    }
  });
}

AppConfig _config({String testHash = '', String releaseHash = ''}) =>
    AppConfig.fromValues(
      appEnvironment: _values['APP_ENV']!,
      supabaseUrl: _values['SUPABASE_URL']!,
      supabasePublishableKey: _values['SUPABASE_PUBLISHABLE_KEY']!,
      authRedirectUri: _values['AUTH_REDIRECT_URI']!,
      googleAuthEnabled: _values['GOOGLE_AUTH_ENABLED']!,
      storefrontShopSlug: _values['STOREFRONT_SHOP_SLUG']!,
      authCallbackVerifiedHost: _values['AUTH_CALLBACK_VERIFIED_HOST']!,
      testConfigSha256: testHash,
      releaseConfigSha256: releaseHash,
    );

const _values = <String, String>{
  'APP_ENV': 'staging',
  'SUPABASE_URL': 'https://jpgoimipbothfgkokyvm.supabase.co',
  'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_synthetic',
  'AUTH_REDIRECT_URI': 'https://auth.client.example.com/auth-callback/',
  'GOOGLE_AUTH_ENABLED': 'true',
  'STOREFRONT_SHOP_SLUG': 'storefront-synthetic',
  'DELIVERY_MAPS_ENABLED': 'false',
  'DELIVERY_MAPS_NATIVE_CONFIGURED': 'false',
  'AUTH_CALLBACK_VERIFIED_HOST': 'auth.client.example.com',
};
