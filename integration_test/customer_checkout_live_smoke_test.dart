import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/checkout/data/supabase_checkout_repository.dart';
import 'package:client_merchandise_control/features/checkout/domain/checkout_models.dart';
import 'package:client_merchandise_control/features/storefront/data/http_storefront_rpc_invoker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('adapter checkout legge il contratto pubblico staging reale', (
    _,
  ) async {
    final config = AppConfig.fromEnvironment();
    expect(config.environment, AppEnvironment.staging);
    final client = http.Client();
    addTearDown(client.close);
    final invoker = HttpStorefrontRpcInvoker(
      origin: Uri.parse(config.supabaseUrl!),
      publishableKey: config.supabasePublishableKey!,
      client: client,
    );
    final repository = SupabaseCheckoutRepository(
      port: _HttpCheckoutPort(invoker),
    );
    final stopwatch = Stopwatch()..start();
    final options = await repository.loadOptions(
      shopSlug: config.storefrontShopSlug!,
    );
    stopwatch.stop();

    expect(options.status, FulfillmentOptionsStatus.ok);
    expect(options.shopSlug, config.storefrontShopSlug);
    expect(options.currencyCode, 'CLP');
    expect(options.modes, hasLength(3));
    expect(options.modes.map((mode) => mode.mode).toSet(), {
      CheckoutFulfillmentMode.pickup,
      CheckoutFulfillmentMode.reservation,
      CheckoutFulfillmentMode.delivery,
    });
    debugPrint(
      'CUSTOMER_CHECKOUT_LIVE elapsed_ms=${stopwatch.elapsedMilliseconds} '
      'points=${options.pickupPoints.length} '
      'zones=${options.deliveryZones.length} slots=${options.slots.length}',
    );
    binding.reportData = <String, Object?>{
      'transport': 'anonymous-http-postgrest',
      'adapter': 'SupabaseCheckoutRepository',
      'apiVersion': 'storefront-fulfillment.v1',
      'status': options.status.name,
      'modeCount': options.modes.length,
      'pickupPointCount': options.pickupPoints.length,
      'deliveryZoneCount': options.deliveryZones.length,
      'slotCount': options.slots.length,
      'elapsedMs': stopwatch.elapsedMilliseconds,
      'internalIdentifiers': 'absent-by-strict-parser',
      'result': 'PASS',
    };
  });
}

final class _HttpCheckoutPort implements CheckoutPort {
  const _HttpCheckoutPort(this.invoker);

  final HttpStorefrontRpcInvoker invoker;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return invoker.call(function, parameters);
  }
}
