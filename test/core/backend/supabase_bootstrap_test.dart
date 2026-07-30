import 'package:client_merchandise_control/core/backend/backend_status.dart';
import 'package:client_merchandise_control/core/backend/supabase_bootstrap.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callback = AppConfig.allowedAuthRedirectUri;

  test('non inizializza la rete in development senza backend', () async {
    var initializationCalls = 0;

    final status = await SupabaseBootstrap.initialize(
      AppConfig.fromValues(),
      initializer: ({required url, required publishableKey}) async {
        initializationCalls += 1;
      },
    );

    expect(status, BackendStatus.notConfigured);
    expect(initializationCalls, 0);
  });

  test('rifiuta development configurato prima dell’initializer', () async {
    var initializationCalls = 0;

    final attempt = Future<void>.sync(() async {
      final config = AppConfig.fromValues(
        supabaseUrl: 'https://project.example.invalid',
        supabasePublishableKey: 'sb_publishable_test_key',
      );
      await SupabaseBootstrap.initialize(
        config,
        initializer: ({required url, required publishableKey}) async {
          initializationCalls += 1;
        },
      );
    });

    await expectLater(attempt, throwsA(isA<AppConfigurationException>()));
    expect(initializationCalls, 0);
  });

  test('inizializza una volta con gli argomenti configurati esatti', () async {
    const expectedUrl = 'https://project.example.invalid';
    const expectedKey = 'sb_publishable_test_key';
    var initializationCalls = 0;
    String? receivedUrl;
    String? receivedKey;

    final status = await SupabaseBootstrap.initialize(
      AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: '$expectedUrl/',
        supabasePublishableKey: expectedKey,
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
      ),
      initializer: ({required url, required publishableKey}) async {
        initializationCalls += 1;
        receivedUrl = url;
        receivedKey = publishableKey;
      },
    );

    expect(status, BackendStatus.ready);
    expect(initializationCalls, 1);
    expect(receivedUrl, expectedUrl);
    expect(receivedKey, expectedKey);
  });

  test(
    'propaga un errore dell’initializer senza ripetere la chiamata',
    () async {
      final initializationError = StateError(
        'inizializzazione non disponibile',
      );
      var initializationCalls = 0;

      final future = SupabaseBootstrap.initialize(
        AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'https://project.example.invalid',
          supabasePublishableKey: 'sb_publishable_test_key',
          authRedirectUri: callback,
          googleAuthEnabled: 'false',
        ),
        initializer: ({required url, required publishableKey}) async {
          initializationCalls += 1;
          throw initializationError;
        },
      );

      await expectLater(future, throwsA(same(initializationError)));
      expect(initializationCalls, 1);
    },
  );
}
