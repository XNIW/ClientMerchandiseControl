import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/app_environment.dart';
import 'backend_status.dart';

typedef SupabaseInitializer =
    Future<void> Function({
      required String url,
      required String publishableKey,
    });

abstract final class SupabaseBootstrap {
  static Future<BackendStatus> initialize(
    AppConfig config, {
    SupabaseInitializer? initializer,
  }) async {
    if (config.environment == AppEnvironment.development) {
      return BackendStatus.notConfigured;
    }

    if (config.environment == AppEnvironment.production) {
      throw const AppConfigurationException(
        'Il bootstrap Supabase production non è autorizzato in questo milestone.',
      );
    }

    if (!config.isBackendConfigured) {
      return BackendStatus.notConfigured;
    }

    await (initializer ?? _initializeSupabase)(
      url: config.supabaseUrl!,
      publishableKey: config.supabasePublishableKey!,
    );
    return BackendStatus.ready;
  }

  static Future<void> _initializeSupabase({
    required String url,
    required String publishableKey,
  }) async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
