import 'dart:convert';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig', () {
    test('usa development non configurato come default', () {
      final config = AppConfig.fromValues();

      expect(config.environment, AppEnvironment.development);
      expect(config.isBackendConfigured, isFalse);
      expect(config.supabaseUrl, isNull);
      expect(config.supabasePublishableKey, isNull);
    });

    test('parsa development, staging e production', () {
      expect(
        AppConfig.fromValues(appEnvironment: 'development').environment,
        AppEnvironment.development,
      );
      expect(
        AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'https://staging.example.invalid',
          supabasePublishableKey: 'sb_publishable_staging',
        ).environment,
        AppEnvironment.staging,
      );
      expect(
        AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://production.example.invalid',
          supabasePublishableKey: 'sb_publishable_production',
        ).environment,
        AppEnvironment.production,
      );
    });

    test('rileva un backend configurato soltanto con entrambi i valori', () {
      final config = AppConfig.fromValues(
        supabaseUrl: 'https://localhost:54321/',
        supabasePublishableKey: 'sb_publishable_local',
      );

      expect(config.isBackendConfigured, isTrue);
      expect(config.supabaseUrl, 'https://localhost:54321');
    });

    test('rifiuta staging e production senza backend', () {
      for (final environment in ['staging', 'production']) {
        expect(
          () => AppConfig.fromValues(appEnvironment: environment),
          throwsA(isA<AppConfigurationException>()),
          reason: environment,
        );
      }
    });

    test('rifiuta una configurazione parziale', () {
      expect(
        () => AppConfig.fromValues(supabaseUrl: 'https://example.invalid'),
        throwsA(isA<AppConfigurationException>()),
      );
      expect(
        () => AppConfig.fromValues(
          supabasePublishableKey: 'sb_publishable_example',
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('rifiuta APP_ENV esplicitamente vuoto', () {
      expect(
        () => AppConfig.fromValues(appEnvironment: '   '),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('accetta e normalizza soltanto origin HTTPS', () {
      final config = AppConfig.fromValues(
        supabaseUrl: ' HTTPS://Example.Invalid:443/ ',
        supabasePublishableKey: 'sb_publishable_example',
      );

      expect(config.supabaseUrl, 'https://example.invalid');
    });

    test('rifiuta URL che non sono origin HTTPS canoniche', () {
      const invalidUrls = [
        'not-an-absolute-url',
        'http://example.invalid',
        'ftp://example.invalid',
        'https://user@example.invalid',
        'https://example.invalid/path',
        'https://example.invalid:99999',
        'https://example.invalid?',
        'https://example.invalid?key=value',
        'https://example.invalid#',
        'https://example.invalid#fragment',
      ];

      for (final url in invalidUrls) {
        expect(
          () => AppConfig.fromValues(
            supabaseUrl: url,
            supabasePublishableKey: 'sb_publishable_example',
          ),
          throwsA(isA<AppConfigurationException>()),
          reason: url,
        );
      }
    });

    test('accetta una chiave moderna sb_publishable_ con suffisso', () {
      final config = AppConfig.fromValues(
        supabaseUrl: 'https://example.invalid',
        supabasePublishableKey: 'sb_publishable_Abc-123_xyz',
      );

      expect(config.supabasePublishableKey, 'sb_publishable_Abc-123_xyz');
    });

    test('accetta un JWT legacy decodificabile con role anon', () {
      final key = _legacyJwt(role: 'anon');
      final config = AppConfig.fromValues(
        supabaseUrl: 'https://example.invalid',
        supabasePublishableKey: key,
      );

      expect(config.supabasePublishableKey, key);
    });

    test('rifiuta chiavi privilegiate, arbitrarie o malformate', () {
      final invalidKeys = [
        'sb_secret_example',
        'sb_publishable_',
        'publishable-placeholder',
        _legacyJwt(role: 'service_role'),
        'not.a.jwt',
        'only.two',
      ];

      for (final key in invalidKeys) {
        expect(
          () => AppConfig.fromValues(
            supabaseUrl: 'https://example.invalid',
            supabasePublishableKey: key,
          ),
          throwsA(isA<AppConfigurationException>()),
          reason: key.startsWith('sb_secret_')
              ? 'chiave segreta'
              : 'chiave non ammessa',
        );
      }
    });

    test('non include una chiave rifiutata nell’errore', () {
      const rejectedKey = 'sb_secret_do-not-disclose';

      expect(
        () => AppConfig.fromValues(
          supabaseUrl: 'https://example.invalid',
          supabasePublishableKey: rejectedKey,
        ),
        throwsA(
          isA<AppConfigurationException>().having(
            (error) => error.toString(),
            'messaggio sanitizzato',
            isNot(contains(rejectedKey)),
          ),
        ),
      );
    });

    test('rifiuta ambienti sconosciuti', () {
      expect(
        () => AppConfig.fromValues(appEnvironment: 'preview'),
        throwsA(isA<AppConfigurationException>()),
      );
    });
  });
}

String _legacyJwt({required String role}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return [
    encode({'alg': 'HS256', 'typ': 'JWT'}),
    encode({'role': role, 'iss': 'supabase'}),
    base64Url.encode([1, 2, 3]).replaceAll('=', ''),
  ].join('.');
}
