import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/app_environment.dart';
import 'backend_readiness_state.dart';
import 'secure_supabase_auth_storage.dart';

typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

abstract final class SupabaseBootstrap {
  static Future<void>? _defaultInitialization;

  static Future<BackendReadinessState> initialize(
    AppConfig config, {
    SupabaseInitializer? initializer,
    SecureSupabaseAuthStorage? authStorage,
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

    if (initializer != null) {
      await initializer(
        url: config.supabaseUrl!,
        publishableKey: config.supabasePublishableKey!,
      );
    } else {
      await _initializeDefault(
        url: config.supabaseUrl!,
        publishableKey: config.supabasePublishableKey!,
        authStorage: authStorage ?? SecureSupabaseAuthStorage.standardInstance,
      );
    }
    return BackendReadinessState.initializing;
  }

  static FlutterAuthClientOptions buildAuthOptions(
    SecureSupabaseAuthStorage authStorage,
  ) {
    return FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
      detectSessionInUri: false,
      localStorage: authStorage,
      pkceAsyncStorage: authStorage,
    );
  }

  static Future<void> _initializeDefault({
    required String url,
    required String publishableKey,
    required SecureSupabaseAuthStorage authStorage,
  }) async {
    final inFlight = _defaultInitialization;
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<void> operation;
    operation =
        Supabase.initialize(
          url: url,
          publishableKey: publishableKey,
          authOptions: buildAuthOptions(authStorage),
          debug: false,
        ).then<void>((_) {}).catchError((Object error, StackTrace stackTrace) {
          if (identical(_defaultInitialization, operation)) {
            _defaultInitialization = null;
          }
          Error.throwWithStackTrace(error, stackTrace);
        });
    _defaultInitialization = operation;
    return operation;
  }
}
