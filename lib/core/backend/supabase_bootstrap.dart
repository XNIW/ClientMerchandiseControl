import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'backend_status.dart';

abstract final class SupabaseBootstrap {
  static Future<BackendStatus> initialize(AppConfig config) async {
    if (!config.isBackendConfigured) {
      return BackendStatus.notConfigured;
    }

    await Supabase.initialize(
      url: config.supabaseUrl!,
      publishableKey: config.supabasePublishableKey!,
    );
    return BackendStatus.ready;
  }
}
