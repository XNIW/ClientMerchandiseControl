import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/app_environment.dart';
import 'backend_readiness_state.dart';

typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

abstract final class SupabaseBootstrap {
  static Future<BackendReadinessState> initialize(
    AppConfig config, {
    SupabaseInitializer? initializer,
  }) async {
    if (config.environment == AppEnvironment.development) {
      return BackendReadinessState.unconfigured;
    }

    if (config.environment == AppEnvironment.production) {
      throw const AppConfigurationException(
        'Il bootstrap Supabase production non è autorizzato in questo milestone.',
      );
    }

    if (!config.isBackendConfigured) {
      return BackendReadinessState.misconfigured;
    }

    await (initializer ?? _initializeSupabase)(
      url: config.supabaseUrl!,
      publishableKey: config.supabasePublishableKey!,
    );
    return BackendReadinessState.initializing;
  }

  static Future<void> _initializeSupabase({
    required String url,
    required String publishableKey,
  }) async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _DisabledGotrueAsyncStorage(),
      ),
      debug: false,
    );
  }
}

final class _DisabledGotrueAsyncStorage extends GotrueAsyncStorage {
  const _DisabledGotrueAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
