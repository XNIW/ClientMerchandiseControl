import 'dart:convert';
import 'dart:io';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callback = AppConfig.allowedAuthRedirectUri;
  const stagingUrl = 'https://staging.example.invalid';
  const stagingKey = 'sb_publishable_staging';

  group('AppConfig', () {
    test('usa development non configurato come default', () {
      final config = AppConfig.fromValues();

      expect(config.environment, AppEnvironment.development);
      expect(config.isBackendConfigured, isFalse);
      expect(config.supabaseUrl, isNull);
      expect(config.supabasePublishableKey, isNull);
      expect(config.authRedirectUri, isNull);
      expect(config.googleAuthEnabled, isFalse);
    });

    test('costruisce dal compile-time environment corrente', () {
      const expectedEnvironment = String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      );
      final config = AppConfig.fromEnvironment();
      final expectsRemoteConfig =
          expectedEnvironment.trim().toLowerCase() != 'development';

      expect(config.environment.name, expectedEnvironment.trim().toLowerCase());
      expect(config.isBackendConfigured, expectsRemoteConfig);
      expect(config.isAuthRedirectConfigured, expectsRemoteConfig);
    });

    test('parsa development, staging e production', () {
      expect(
        AppConfig.fromValues(appEnvironment: 'development').environment,
        AppEnvironment.development,
      );
      expect(
        AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: stagingUrl,
          supabasePublishableKey: stagingKey,
          authRedirectUri: callback,
          googleAuthEnabled: 'true',
        ).environment,
        AppEnvironment.staging,
      );
      expect(
        AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://production.example.invalid',
          supabasePublishableKey: 'sb_publishable_production',
          authRedirectUri: callback,
          googleAuthEnabled: 'false',
        ).environment,
        AppEnvironment.production,
      );
    });

    test('rileva un backend configurato soltanto con entrambi i valori', () {
      final config = AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://localhost:54321/',
        supabasePublishableKey: 'sb_publishable_local',
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
      );

      expect(config.isBackendConfigured, isTrue);
      expect(config.supabaseUrl, 'https://localhost:54321');
    });

    test('rifiuta staging e production senza configurazione completa', () {
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

    test('development rifiuta backend, callback e OAuth reale', () {
      final attempts = [
        () => AppConfig.fromValues(
          supabaseUrl: stagingUrl,
          supabasePublishableKey: stagingKey,
        ),
        () => AppConfig.fromValues(authRedirectUri: callback),
        () => AppConfig.fromValues(googleAuthEnabled: 'true'),
      ];

      for (final attempt in attempts) {
        expect(attempt, throwsA(isA<AppConfigurationException>()));
      }

      expect(
        AppConfig.fromValues(googleAuthEnabled: 'false').googleAuthEnabled,
        isFalse,
      );
    });

    test('staging accetta auth abilitata o disabilitata', () {
      for (final flag in ['true', 'false']) {
        final config = AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: stagingUrl,
          supabasePublishableKey: stagingKey,
          authRedirectUri: callback,
          googleAuthEnabled: flag,
        );

        expect(config.googleAuthEnabled, flag == 'true');
        expect(config.authRedirectUri, callback);
      }
    });

    test('staging rifiuta ogni campo obbligatorio mancante', () {
      final attempts = [
        () => AppConfig.fromValues(
          appEnvironment: 'staging',
          supabasePublishableKey: stagingKey,
          authRedirectUri: callback,
          googleAuthEnabled: 'true',
        ),
        () => AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: stagingUrl,
          authRedirectUri: callback,
          googleAuthEnabled: 'true',
        ),
        () => AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: stagingUrl,
          supabasePublishableKey: stagingKey,
          googleAuthEnabled: 'true',
        ),
        () => AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: stagingUrl,
          supabasePublishableKey: stagingKey,
          authRedirectUri: callback,
        ),
      ];

      for (final attempt in attempts) {
        expect(attempt, throwsA(isA<AppConfigurationException>()));
      }
    });

    test('production è fail-closed e vieta Google OAuth', () {
      final valid = AppConfig.fromValues(
        appEnvironment: 'production',
        supabaseUrl: 'https://production.example.invalid',
        supabasePublishableKey: 'sb_publishable_production',
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
      );

      expect(valid.environment, AppEnvironment.production);
      expect(valid.googleAuthEnabled, isFalse);

      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://production.example.invalid',
          supabasePublishableKey: 'sb_publishable_production',
          authRedirectUri: callback,
          googleAuthEnabled: 'true',
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
        appEnvironment: 'staging',
        supabaseUrl: ' HTTPS://Example.Invalid:443/ ',
        supabasePublishableKey: 'sb_publishable_example',
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
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
            appEnvironment: 'staging',
            supabaseUrl: url,
            supabasePublishableKey: 'sb_publishable_example',
            authRedirectUri: callback,
            googleAuthEnabled: 'false',
          ),
          throwsA(isA<AppConfigurationException>()),
          reason: url,
        );
      }
    });

    test('accetta una chiave moderna sb_publishable_ con suffisso', () {
      final config = AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://example.invalid',
        supabasePublishableKey: 'sb_publishable_Abc-123_xyz',
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
      );

      expect(config.supabasePublishableKey, 'sb_publishable_Abc-123_xyz');
    });

    test('accetta un JWT legacy decodificabile con role anon', () {
      final key = _legacyJwt(role: 'anon');
      final config = AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://example.invalid',
        supabasePublishableKey: key,
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
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
            appEnvironment: 'staging',
            supabaseUrl: 'https://example.invalid',
            supabasePublishableKey: key,
            authRedirectUri: callback,
            googleAuthEnabled: 'false',
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
          appEnvironment: 'staging',
          supabaseUrl: 'https://example.invalid',
          supabasePublishableKey: rejectedKey,
          authRedirectUri: callback,
          googleAuthEnabled: 'false',
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

    test('accetta soltanto la callback canonica esatta', () {
      final valid = AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: stagingUrl,
        supabasePublishableKey: stagingKey,
        authRedirectUri: callback,
        googleAuthEnabled: 'true',
      );
      expect(valid.authRedirectUri, callback);

      const invalidCallbacks = [
        'http://auth-callback/',
        'https://auth-callback/',
        'com.xniw.clientmerchandisecontrol:/auth-callback/',
        'other.scheme://auth-callback/',
        'com.xniw.clientmerchandisecontrol://wrong-host/',
        'com.xniw.clientmerchandisecontrol://auth-callback',
        'com.xniw.clientmerchandisecontrol://auth-callback/extra',
        'com.xniw.clientmerchandisecontrol://user@auth-callback/',
        'com.xniw.clientmerchandisecontrol://auth-callback:8443/',
        'com.xniw.clientmerchandisecontrol://auth-callback/?code=value',
        'com.xniw.clientmerchandisecontrol://auth-callback/#fragment',
        'com.xniw.clientmerchandisecontrol://*/',
        'auth-callback/',
      ];

      for (final redirectUri in invalidCallbacks) {
        expect(
          () => AppConfig.fromValues(
            appEnvironment: 'staging',
            supabaseUrl: stagingUrl,
            supabasePublishableKey: stagingKey,
            authRedirectUri: redirectUri,
            googleAuthEnabled: 'true',
          ),
          throwsA(isA<AppConfigurationException>()),
          reason: redirectUri,
        );
      }
    });

    test('parsa il flag Google in modo stretto', () {
      for (final invalidValue in ['TRUE', 'False', '1', 'yes', 'enabled']) {
        expect(
          () => AppConfig.fromValues(
            appEnvironment: 'staging',
            supabaseUrl: stagingUrl,
            supabasePublishableKey: stagingKey,
            authRedirectUri: callback,
            googleAuthEnabled: invalidValue,
          ),
          throwsA(isA<AppConfigurationException>()),
          reason: invalidValue,
        );
      }
    });

    test('espone soltanto diagnostica sanitizzata', () {
      const rawUrl = 'https://sensitive.example.invalid';
      const rawKey = 'sb_publishable_sensitive-marker';
      final config = AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: rawUrl,
        supabasePublishableKey: rawKey,
        authRedirectUri: callback,
        googleAuthEnabled: 'true',
      );

      expect(config.sanitizedDiagnostics, {
        'environment': 'staging',
        'backendConfigured': true,
        'authRedirectConfigured': true,
        'googleAuthEnabled': true,
      });
      expect(config.sanitizedDiagnostics, isNot(containsValue(rawUrl)));
      expect(config.sanitizedDiagnostics, isNot(containsValue(rawKey)));
      expect(config.sanitizedDiagnostics, isNot(containsValue(callback)));
      expect(config.toString(), isNot(contains(rawUrl)));
      expect(config.toString(), isNot(contains(rawKey)));
      expect(config.toString(), isNot(contains(callback)));
    });

    test('non ripete input rifiutati nei messaggi di errore', () {
      const rejectedUrl = 'http://sensitive-url.invalid/path';
      const rejectedRedirect =
          'com.xniw.clientmerchandisecontrol://sensitive-host/';
      const rejectedFlag = 'sensitive-flag';

      final attempts = <(String, void Function())>[
        (
          rejectedUrl,
          () => AppConfig.fromValues(
            appEnvironment: 'staging',
            supabaseUrl: rejectedUrl,
            supabasePublishableKey: stagingKey,
            authRedirectUri: callback,
            googleAuthEnabled: 'true',
          ),
        ),
        (
          rejectedRedirect,
          () => AppConfig.fromValues(
            appEnvironment: 'staging',
            supabaseUrl: stagingUrl,
            supabasePublishableKey: stagingKey,
            authRedirectUri: rejectedRedirect,
            googleAuthEnabled: 'true',
          ),
        ),
        (
          rejectedFlag,
          () => AppConfig.fromValues(
            appEnvironment: 'staging',
            supabaseUrl: stagingUrl,
            supabasePublishableKey: stagingKey,
            authRedirectUri: callback,
            googleAuthEnabled: rejectedFlag,
          ),
        ),
      ];

      for (final (marker, attempt) in attempts) {
        expect(
          attempt,
          throwsA(
            isA<AppConfigurationException>().having(
              (error) => error.toString(),
              'messaggio sanitizzato',
              isNot(contains(marker)),
            ),
          ),
        );
      }
    });

    test('rifiuta ambienti sconosciuti', () {
      expect(
        () => AppConfig.fromValues(appEnvironment: 'preview'),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('gli esempi hanno esattamente i cinque input contrattuali', () {
      const expectedKeys = {
        'APP_ENV',
        'SUPABASE_URL',
        'SUPABASE_PUBLISHABLE_KEY',
        'AUTH_REDIRECT_URI',
        'GOOGLE_AUTH_ENABLED',
      };
      final development = _readJsonObject('config/app_config.example.json');
      final staging = _readJsonObject('config/app_config.staging.example.json');

      expect(development.keys.toSet(), expectedKeys);
      expect(development['APP_ENV'], 'development');
      expect(development['SUPABASE_URL'], isEmpty);
      expect(development['SUPABASE_PUBLISHABLE_KEY'], isEmpty);
      expect(development['AUTH_REDIRECT_URI'], isEmpty);
      expect(development['GOOGLE_AUTH_ENABLED'], 'false');

      expect(staging.keys.toSet(), expectedKeys);
      expect(staging['APP_ENV'], 'staging');
      expect(staging['SUPABASE_URL'], isEmpty);
      expect(staging['SUPABASE_PUBLISHABLE_KEY'], isEmpty);
      expect(staging['AUTH_REDIRECT_URI'], callback);
      expect(staging['GOOGLE_AUTH_ENABLED'], 'true');
    });
  });
}

Map<String, dynamic> _readJsonObject(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    fail('$path deve contenere un oggetto JSON.');
  }
  return decoded;
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
