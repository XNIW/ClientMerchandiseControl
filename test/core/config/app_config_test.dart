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
          supabasePublishableKey: 'publishable-placeholder',
        ).environment,
        AppEnvironment.staging,
      );
      expect(
        AppConfig.fromValues(
          appEnvironment: 'production',
          supabaseUrl: 'https://production.example.invalid',
          supabasePublishableKey: 'publishable-placeholder',
        ).environment,
        AppEnvironment.production,
      );
    });

    test('rileva un backend configurato soltanto con entrambi i valori', () {
      final config = AppConfig.fromValues(
        supabaseUrl: 'http://localhost:54321',
        supabasePublishableKey: 'publishable-placeholder',
      );

      expect(config.isBackendConfigured, isTrue);
    });

    test('rifiuta production incompleta', () {
      expect(
        () => AppConfig.fromValues(appEnvironment: 'production'),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('rifiuta una configurazione parziale', () {
      expect(
        () => AppConfig.fromValues(supabaseUrl: 'https://example.invalid'),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('rifiuta URL non valido', () {
      expect(
        () => AppConfig.fromValues(
          supabaseUrl: 'not-an-absolute-url',
          supabasePublishableKey: 'publishable-placeholder',
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('richiede HTTPS fuori da development', () {
      expect(
        () => AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'http://staging.example.invalid',
          supabasePublishableKey: 'publishable-placeholder',
        ),
        throwsA(isA<AppConfigurationException>()),
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
