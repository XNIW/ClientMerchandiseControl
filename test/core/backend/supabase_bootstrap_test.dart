import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/backend/secure_supabase_auth_storage.dart';
import 'package:client_merchandise_control/core/backend/supabase_bootstrap.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    expect(status, BackendReadinessState.unconfigured);
    expect(initializationCalls, 0);
  });

  test('opzioni Auth sono PKCE, auto-refresh e storage sicuro unico', () {
    final storage = SecureSupabaseAuthStorage(
      secureStore: _NoopSecureStore(),
      installationMarkerStore: _MarkedInstall(),
      cleanupJournalStore: _NoopCleanupJournalStore(),
    );

    final options = SupabaseBootstrap.buildAuthOptions(storage);

    expect(options.authFlowType, AuthFlowType.pkce);
    expect(options.autoRefreshToken, isTrue);
    expect(options.detectSessionInUri, isFalse);
    expect(options.localStorage, same(storage));
    expect(options.pkceAsyncStorage, same(storage));
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
        storefrontShopSlug: 'storefront-test',
      ),
      initializer: ({required url, required publishableKey}) async {
        initializationCalls += 1;
        receivedUrl = url;
        receivedKey = publishableKey;
      },
    );

    expect(status, BackendReadinessState.initializing);
    expect(initializationCalls, 1);
    expect(receivedUrl, expectedUrl);
    expect(receivedKey, expectedKey);
  });

  test('rifiuta production completa senza chiamare l’initializer', () async {
    const productionUrl = 'https://production.example.invalid';
    const productionKey = 'sb_publishable_production';
    var initializationCalls = 0;

    final future = SupabaseBootstrap.initialize(
      AppConfig.fromValues(
        appEnvironment: 'production',
        supabaseUrl: productionUrl,
        supabasePublishableKey: productionKey,
        authRedirectUri: callback,
        googleAuthEnabled: 'false',
        storefrontShopSlug: 'storefront-test',
        releaseConfigSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ),
      initializer: ({required url, required publishableKey}) async {
        initializationCalls += 1;
      },
    );

    await expectLater(
      future,
      throwsA(
        isA<AppConfigurationException>()
            .having(
              (error) => error.toString(),
              'URL sanitizzato',
              isNot(contains(productionUrl)),
            )
            .having(
              (error) => error.toString(),
              'key sanitizzata',
              isNot(contains(productionKey)),
            )
            .having(
              (error) => error.toString(),
              'callback sanitizzata',
              isNot(contains(callback)),
            ),
      ),
    );
    expect(initializationCalls, 0);
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
          storefrontShopSlug: 'storefront-test',
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

final class _NoopSecureStore implements SecureAuthKeyValueStore {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}
}

final class _MarkedInstall implements AuthInstallationMarkerStore {
  @override
  Future<void> clearCleanupPending(AuthCleanupTarget target) async {}

  @override
  Future<bool> isCleanupPending(AuthCleanupTarget target) async => false;

  @override
  Future<bool> isCurrentInstallMarked() async => true;

  @override
  Future<void> markCurrentInstall() async {}

  @override
  Future<void> markCleanupPending(AuthCleanupTarget target) async {}
}

final class _NoopCleanupJournalStore implements AuthCleanupJournalStore {
  @override
  Future<bool> isCleanupPending(AuthCleanupTarget target) async => false;

  @override
  Future<void> markCleanupPending(AuthCleanupTarget target) async {}

  @override
  Future<void> clearCleanupPending(AuthCleanupTarget target) async {}
}
