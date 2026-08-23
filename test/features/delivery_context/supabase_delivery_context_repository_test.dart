import 'package:client_merchandise_control/features/delivery_context/data/supabase_delivery_context_repository.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _shop = 'storefront-test';
const _point = '51000000-0000-4000-8000-000000000001';

void main() {
  test(
    'preview conserva fee, fascia e copertura server-authoritative',
    () async {
      final port = _Port(_payload());
      final value = await SupabaseDeliveryContextRepository(port: port).preview(
        shopSlug: _shop,
        mode: CustomerDeliveryMode.pickup,
        pickupPointId: _point,
      );

      expect(
        value.serviceabilityStatus,
        DeliveryServiceabilityStatus.serviceable,
      );
      expect(value.estimatedFeeClp, 2990);
      expect(value.version, 4);
      expect(value.isCheckoutReady, isTrue);
      expect(port.function, 'storefront_delivery_context_preview_v1');
      expect(port.parameters, containsPair('p_pickup_point_id', _point));
    },
  );

  test('identità shop diversa fallisce chiusa', () async {
    final repository = SupabaseDeliveryContextRepository(
      port: _Port({..._payload(), 'shopSlug': 'other-shop'}),
    );

    await expectLater(
      repository.preview(
        shopSlug: _shop,
        mode: CustomerDeliveryMode.pickup,
        pickupPointId: _point,
      ),
      throwsA(
        isA<DeliveryContextRepositoryException>().having(
          (error) => error.kind,
          'kind',
          DeliveryContextFailureKind.unexpected,
        ),
      ),
    );
  });

  test('shape delivery invalida non raggiunge il server', () async {
    final port = _Port(_payload());
    await expectLater(
      SupabaseDeliveryContextRepository(port: port).preview(
        shopSlug: _shop,
        mode: CustomerDeliveryMode.delivery,
        pickupPointId: _point,
      ),
      throwsA(isA<DeliveryContextRepositoryException>()),
    );
    expect(port.calls, 0);
  });
}

Map<String, Object?> _payload() => {
  'apiVersion': 'storefront-delivery-context.v1',
  'status': 'ok',
  'shopSlug': _shop,
  'mode': 'pickup',
  'addressId': null,
  'pickupPointId': _point,
  'pickupPointName': 'Negozio principale',
  'serviceabilityStatus': 'serviceable',
  'deliveryZoneId': null,
  'deliveryZoneName': null,
  'estimatedFeeClp': 2990,
  'earliestSlotStartsAt': '2026-08-24T14:00:00Z',
  'earliestSlotEndsAt': '2026-08-24T16:00:00Z',
  'contextVersion': 4,
  'selectedAt': '2026-08-23T12:00:00Z',
  'serverTime': '2026-08-23T12:00:00Z',
};

final class _Port implements DeliveryContextPort {
  _Port(this.response);

  final Object? response;
  String? function;
  Map<String, Object?>? parameters;
  int calls = 0;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    calls++;
    this.function = function;
    this.parameters = parameters;
    return response;
  }
}
