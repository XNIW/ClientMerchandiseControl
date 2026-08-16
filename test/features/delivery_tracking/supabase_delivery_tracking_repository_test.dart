import 'package:client_merchandise_control/features/delivery_tracking/data/supabase_delivery_tracking_repository.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_failure.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_tracking_test_support.dart';

void main() {
  test('parses owner-scoped liveCourier snapshot with server ETA', () async {
    final port = FakeDeliveryTrackingPort()
      ..response = {
        'ok': true,
        'code': 'success',
        'snapshot': trackingLivePayload(),
      };
    final repository = SupabaseDeliveryTrackingRepository(port: port);

    final snapshot = await repository.load(
      shopSlug: trackingTestShop,
      orderId: trackingTestOrder,
    );

    expect(port.function, 'storefront_order_tracking_v1');
    expect(port.parameters, {
      'p_shop_slug': trackingTestShop,
      'p_order_id': trackingTestOrder,
    });
    expect(snapshot.trackingMode, DeliveryTrackingMode.liveCourier);
    expect(snapshot.hasFreshLiveLocation, isTrue);
    expect(snapshot.externalTrackingUrl, isNull);
  });

  test('maps only the filtered safe Realtime feed shape', () async {
    final port = FakeDeliveryTrackingPort();
    final repository = SupabaseDeliveryTrackingRepository(port: port);
    final future = repository.watch(orderId: trackingTestOrder).first;
    port.stream.add(trackingRealtimeRecord());

    final snapshot = await future;
    expect(snapshot.version, 5);
    expect(snapshot.courierCoordinate?.latitude, -33.446);
  });

  test('rejects extra internal UUIDs and terminal precise coordinates', () {
    final leaked = {...trackingLivePayload(), 'shopId': trackingTestSession};
    expect(() => parseDeliveryTrackingSnapshot(leaked), throwsFormatException);
    final terminal = {
      ...trackingLivePayload(orderStatus: 'completed', freshness: 'ended'),
      'trackingState': 'completed',
    };
    expect(
      () => parseDeliveryTrackingSnapshot(terminal),
      throwsFormatException,
    );
  });

  test('validates external carrier URL and statusOnly without marker', () {
    final external = parseDeliveryTrackingSnapshot({
      'apiVersion': 'delivery-tracking-snapshot.v1',
      'orderId': trackingTestOrder,
      'orderStatus': 'preparing',
      'orderStatusVersion': 3,
      'fulfillmentMode': 'delivery',
      'trackingMode': 'externalCarrier',
      'trackingSessionId': trackingTestSession,
      'trackingState': 'active',
      'freshness': 'unavailable',
      'externalCarrier': 'Synthetic Carrier',
      'externalTrackingCodeMasked': '****4401',
      'externalTrackingUrl': 'https://carrier.example.invalid/track/4401',
      'contactCapability': 'none',
      'serverTime': trackingTestNow.toIso8601String(),
      'version': 2,
    });
    expect(external.trackingMode, DeliveryTrackingMode.externalCarrier);
    expect(external.courierCoordinate, isNull);

    expect(
      () => parseDeliveryTrackingSnapshot({
        ...trackingLivePayload(),
        'trackingMode': 'externalCarrier',
        'externalCarrier': 'Bad',
        'externalTrackingUrl': 'https://127.0.0.1/private',
      }),
      throwsFormatException,
    );
  });

  test('maps not_found without exposing remote details', () async {
    final port = FakeDeliveryTrackingPort()
      ..response = {'ok': false, 'code': 'not_found'};
    final repository = SupabaseDeliveryTrackingRepository(port: port);

    await expectLater(
      repository.load(shopSlug: trackingTestShop, orderId: trackingTestOrder),
      throwsA(
        isA<DeliveryTrackingRepositoryException>().having(
          (error) => error.kind,
          'kind',
          DeliveryTrackingFailureKind.notFound,
        ),
      ),
    );
  });
}
