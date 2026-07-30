import 'package:client_merchandise_control/core/backend/backend_status.dart';
import 'package:client_merchandise_control/core/backend/supabase_bootstrap.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('non inizializza la rete in development senza backend', () async {
    final status = await SupabaseBootstrap.initialize(AppConfig.fromValues());

    expect(status, BackendStatus.notConfigured);
  });
}
