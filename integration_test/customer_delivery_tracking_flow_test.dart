import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/delivery_tracking/data/supabase_delivery_tracking_repository.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/delivery_live_map.dart';
import 'package:client_merchandise_control/features/delivery_tracking/presentation/google_delivery_map_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'owner contract live update stale e terminal redaction restano fail-closed',
    (tester) async {
      final snapshot = ValueNotifier<DeliveryTrackingSnapshot>(
        parseDeliveryTrackingSnapshot(_payload(version: 1)),
      );
      final ownerAuthenticated = ValueNotifier(false);
      final adapter = FakeDeliveryMapAdapter();
      var factoryCalls = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deliveryMapConfigurationProvider.overrideWithValue(
              const DeliveryMapConfiguration(
                enabled: true,
                nativeConfigurationPresent: true,
              ),
            ),
            deliveryMapNativeConfigurationProbeProvider.overrideWithValue(
              () async => true,
            ),
            deliveryMapAdapterFactoryProvider.overrideWithValue(() {
              factoryCalls++;
              return adapter;
            }),
            deliveryMapSurfaceBuilderProvider.overrideWithValue(
              ({
                required adapter,
                required scene,
                required labels,
                required brightness,
              }) => const ColoredBox(
                key: ValueKey('acceptance-map-surface'),
                color: Colors.transparent,
              ),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: ownerAuthenticated,
                builder: (context, owner, _) {
                  return ValueListenableBuilder<DeliveryTrackingSnapshot>(
                    valueListenable: snapshot,
                    builder: (context, current, _) => DeliveryLiveMap(
                      snapshot: current,
                      ownerAuthenticated: owner,
                      orderStatusCompatible:
                          current.orderStatus == 'out_for_delivery',
                      semanticsLabel: 'Delivery status and last update',
                      recenterLabel: 'Recenter delivery map',
                      loadingLabel: 'Loading delivery map',
                      markerLabels: const DeliveryMapMarkerLabels(
                        store: 'Store',
                        destination: 'Destination',
                        courier: 'Courier',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(factoryCalls, 0);
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);

      ownerAuthenticated.value = true;
      await _pumpUntil(
        tester,
        () => find
            .byKey(const ValueKey('acceptance-map-surface'))
            .evaluate()
            .isNotEmpty,
      );
      expect(factoryCalls, 1);
      expect(
        find.byKey(const ValueKey('acceptance-map-surface')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('delivery-live-map')), findsOneWidget);
      expect(adapter.scenes.single.snapshotVersion, 1);

      snapshot.value = parseDeliveryTrackingSnapshot(
        _payload(version: 2, latitude: -33.4455),
      );
      await _pumpUntil(tester, () => adapter.scenes.last.snapshotVersion == 2);
      expect(adapter.scenes.last.snapshotVersion, 2);
      expect(adapter.scenes.last.courier.latitude, -33.4455);

      snapshot.value = parseDeliveryTrackingSnapshot(
        _payload(version: 3, freshness: 'stale'),
      );
      await _pumpUntil(
        tester,
        () =>
            find.byKey(const ValueKey('delivery-live-map')).evaluate().isEmpty,
      );
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      expect(adapter.disposeCalls, 1);

      final terminal = parseDeliveryTrackingSnapshot(
        _payload(
          version: 4,
          orderStatus: 'completed',
          trackingState: 'completed',
          freshness: 'ended',
          redact: true,
        ),
      );
      snapshot.value = terminal;
      await tester.pump(const Duration(milliseconds: 50));
      expect(terminal.isTerminal, isTrue);
      expect(terminal.courierCoordinate, isNull);
      expect(terminal.destinationCoordinate, isNull);
      expect(terminal.storeCoordinate, isNull);
      expect(find.byKey(const ValueKey('delivery-live-map')), findsNothing);
      expect(factoryCalls, 1);
    },
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (condition()) return;
  }
  fail('La condizione asincrona non si è verificata entro il limite bounded.');
}

Map<String, Object?> _payload({
  required int version,
  double latitude = -33.446,
  String orderStatus = 'out_for_delivery',
  String trackingState = 'active',
  String freshness = 'fresh',
  bool redact = false,
}) {
  final serverTime = DateTime.utc(2026, 8, 16, 12, 0, version);
  return {
    'apiVersion': 'delivery-tracking-snapshot.v1',
    'orderId': '44000000-0000-4000-8000-000000045001',
    'orderStatus': orderStatus,
    'orderStatusVersion': orderStatus == 'completed' ? 6 : 5,
    'fulfillmentMode': 'delivery',
    'trackingMode': 'liveCourier',
    'trackingSessionId': redact ? null : '74000000-0000-4000-8000-000000045001',
    'trackingState': trackingState,
    'courierPublicLabel': redact ? null : 'Repartidor MC',
    'vehicleKind': redact ? null : 'bicycle',
    'latitude': redact ? null : latitude,
    'longitude': redact ? null : -70.655,
    'horizontalAccuracyMeters': redact ? null : 12,
    'bearingDegrees': redact ? null : 90,
    'speedMetersPerSecond': redact ? null : 4,
    'observedAt': redact
        ? null
        : serverTime.subtract(const Duration(seconds: 2)).toIso8601String(),
    'receivedAt': redact
        ? null
        : serverTime.subtract(const Duration(seconds: 1)).toIso8601String(),
    'freshness': freshness,
    'etaStartsAt': serverTime
        .add(const Duration(minutes: 30))
        .toIso8601String(),
    'etaEndsAt': serverTime.add(const Duration(minutes: 50)).toIso8601String(),
    'destinationLatitude': redact ? null : -33.447,
    'destinationLongitude': redact ? null : -70.65,
    'storeLatitude': redact ? null : -33.445,
    'storeLongitude': redact ? null : -70.66,
    'externalCarrier': null,
    'externalTrackingCodeMasked': null,
    'externalTrackingUrl': null,
    'contactCapability': 'none',
    'serverTime': serverTime.toIso8601String(),
    'version': version,
  };
}
