import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/storefront/data/http_storefront_rpc_invoker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('trasporto guest pubblico raggiunge Storefront senza auth SDK', (
    _,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    expect(config.storefrontShopSlug, 'task010-load');
    final client = http.Client();
    addTearDown(client.close);
    final invoker = HttpStorefrontRpcInvoker(
      origin: Uri.parse(config.supabaseUrl!),
      publishableKey: config.supabasePublishableKey!,
      client: client,
    );
    final stopwatch = Stopwatch()..start();
    final payload = await invoker.call('storefront_home_v1', {
      'p_shop_slug': config.storefrontShopSlug,
      'p_category_limit': 12,
      'p_featured_limit': 8,
      'p_offer_limit': 8,
    });
    stopwatch.stop();
    expect(payload, isA<Map<Object?, Object?>>());
    final home = payload! as Map<Object?, Object?>;
    expect(home['status'], 'ok');
    expect(home['featured'], isNotEmpty);
    expect(home['categories'], isNotEmpty);
    debugPrint(
      'STOREFRONT_PUBLIC_TRANSPORT elapsed_ms=${stopwatch.elapsedMilliseconds}',
    );

    binding.reportData = <String, Object?>{
      'transport': 'anonymous-http-postgrest',
      'elapsedMs': stopwatch.elapsedMilliseconds,
      'status': home['status'],
      'result': 'PASS',
    };
  });
}
