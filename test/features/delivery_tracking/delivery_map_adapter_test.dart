import 'dart:async';

import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_map_adapter.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_tracking_test_support.dart';

void main() {
  test('feature flag off fails closed without touching the provider', () async {
    final adapter = FakeDeliveryMapAdapter();
    final presenter = FailClosedDeliveryMapPresenter(
      configuration: const DeliveryMapConfiguration(
        enabled: false,
        nativeConfigurationPresent: true,
      ),
      adapter: adapter,
    );

    final result = await _present(presenter, trackingLiveSnapshot());

    expect(result, isA<DeliveryMapUnavailable>());
    expect(
      (result as DeliveryMapUnavailable).reason,
      DeliveryMapUnavailableReason.featureFlagOff,
    );
    expect(adapter.scenes, isEmpty);
  });

  test('missing native key configuration fails closed', () async {
    final adapter = FakeDeliveryMapAdapter();
    final presenter = FailClosedDeliveryMapPresenter(
      configuration: const DeliveryMapConfiguration(
        enabled: true,
        nativeConfigurationPresent: false,
      ),
      adapter: adapter,
    );

    final result = await _present(presenter, trackingLiveSnapshot());

    expect(
      (result as DeliveryMapUnavailable).reason,
      DeliveryMapUnavailableReason.missingNativeConfiguration,
    );
    expect(adapter.scenes, isEmpty);
  });

  test('fake adapter receives only the three bounded fresh markers', () async {
    final adapter = FakeDeliveryMapAdapter();
    final presenter = FailClosedDeliveryMapPresenter(
      configuration: const DeliveryMapConfiguration(
        enabled: true,
        nativeConfigurationPresent: true,
      ),
      adapter: adapter,
    );

    final result = await _present(presenter, trackingLiveSnapshot());

    expect(result, isA<DeliveryMapReady>());
    expect(adapter.scenes, hasLength(1));
    expect(adapter.scenes.single.snapshotVersion, 4);
    expect(adapter.scenes.single.store.latitude, -33.445);
    expect(adapter.scenes.single.destination.latitude, -33.447);
    expect(adapter.scenes.single.courier.latitude, -33.446);
  });

  test(
    'stale state and provider exception never produce a ready map',
    () async {
      final staleAdapter = FakeDeliveryMapAdapter();
      final stalePresenter = FailClosedDeliveryMapPresenter(
        configuration: const DeliveryMapConfiguration(
          enabled: true,
          nativeConfigurationPresent: true,
        ),
        adapter: staleAdapter,
      );
      final stale = await _present(
        stalePresenter,
        trackingLiveSnapshot(freshness: 'stale'),
      );
      expect(
        (stale as DeliveryMapUnavailable).reason,
        DeliveryMapUnavailableReason.trackingUnavailable,
      );

      final failingAdapter = FakeDeliveryMapAdapter(
        renderException: StateError('synthetic_provider_failure'),
      );
      final failingPresenter = FailClosedDeliveryMapPresenter(
        configuration: const DeliveryMapConfiguration(
          enabled: true,
          nativeConfigurationPresent: true,
        ),
        adapter: failingAdapter,
      );
      final failure = await _present(failingPresenter, trackingLiveSnapshot());
      expect(
        (failure as DeliveryMapUnavailable).reason,
        DeliveryMapUnavailableReason.providerException,
      );

      await failingPresenter.dispose();
      await failingPresenter.dispose();
      expect(failingAdapter.disposeCalls, 1);
      final disposed = await _present(failingPresenter, trackingLiveSnapshot());
      expect(
        (disposed as DeliveryMapUnavailable).reason,
        DeliveryMapUnavailableReason.disposed,
      );
    },
  );

  test(
    'statusOnly, externalCarrier and terminal snapshots never render',
    () async {
      final adapter = FakeDeliveryMapAdapter();
      final presenter = FailClosedDeliveryMapPresenter(
        configuration: const DeliveryMapConfiguration(
          enabled: true,
          nativeConfigurationPresent: true,
        ),
        adapter: adapter,
      );
      final live = trackingLiveSnapshot();

      for (final snapshot in [
        _copySnapshot(live, trackingMode: DeliveryTrackingMode.statusOnly),
        _copySnapshot(live, trackingMode: DeliveryTrackingMode.externalCarrier),
        _copySnapshot(live, orderStatus: 'completed'),
      ]) {
        final result = await _present(presenter, snapshot);
        expect(
          (result as DeliveryMapUnavailable).reason,
          DeliveryMapUnavailableReason.trackingUnavailable,
        );
      }
      expect(adapter.scenes, isEmpty);
    },
  );

  test(
    'owner, detail status, session and delivery state gate the map',
    () async {
      final adapter = FakeDeliveryMapAdapter();
      final presenter = FailClosedDeliveryMapPresenter(
        configuration: const DeliveryMapConfiguration(
          enabled: true,
          nativeConfigurationPresent: true,
        ),
        adapter: adapter,
      );
      final live = trackingLiveSnapshot();

      final results = [
        await _present(presenter, live, ownerAuthenticated: false),
        await _present(presenter, live, orderStatusCompatible: false),
        await _present(presenter, _copySnapshot(live, orderStatus: 'ready')),
        await _present(
          presenter,
          _copySnapshot(live, clearTrackingSession: true),
        ),
        await _present(
          presenter,
          _copySnapshot(live, trackingState: DeliveryTrackingState.paused),
        ),
        await _present(
          presenter,
          _copySnapshot(live, fulfillmentMode: 'pickup'),
        ),
      ];

      for (final result in results) {
        expect(
          (result as DeliveryMapUnavailable).reason,
          DeliveryMapUnavailableReason.trackingUnavailable,
        );
      }
      expect(adapter.scenes, isEmpty);
    },
  );

  test('dispose during provider render cannot publish a ready map', () async {
    final adapter = _BlockingDeliveryMapAdapter();
    final presenter = FailClosedDeliveryMapPresenter(
      configuration: const DeliveryMapConfiguration(
        enabled: true,
        nativeConfigurationPresent: true,
      ),
      adapter: adapter,
    );

    final pending = _present(presenter, trackingLiveSnapshot());
    await adapter.renderStarted.future;
    await presenter.dispose();
    adapter.releaseRender.complete();

    final result = await pending;
    expect(
      (result as DeliveryMapUnavailable).reason,
      DeliveryMapUnavailableReason.disposed,
    );
    expect(adapter.disposeCalls, 1);
  });
}

Future<DeliveryMapPresentation> _present(
  FailClosedDeliveryMapPresenter presenter,
  DeliveryTrackingSnapshot snapshot, {
  bool ownerAuthenticated = true,
  bool orderStatusCompatible = true,
}) => presenter.present(
  snapshot,
  ownerAuthenticated: ownerAuthenticated,
  orderStatusCompatible: orderStatusCompatible,
);

DeliveryTrackingSnapshot _copySnapshot(
  DeliveryTrackingSnapshot source, {
  DeliveryTrackingMode? trackingMode,
  String? orderStatus,
  bool clearTrackingSession = false,
  DeliveryTrackingState? trackingState,
  String? fulfillmentMode,
}) {
  return DeliveryTrackingSnapshot(
    orderId: source.orderId,
    orderStatus: orderStatus ?? source.orderStatus,
    orderStatusVersion: source.orderStatusVersion,
    fulfillmentMode: fulfillmentMode ?? source.fulfillmentMode,
    trackingMode: trackingMode ?? source.trackingMode,
    trackingState: trackingState ?? source.trackingState,
    freshness: source.freshness,
    contactCapability: source.contactCapability,
    serverTime: source.serverTime,
    version: source.version,
    trackingSessionId: clearTrackingSession ? null : source.trackingSessionId,
    courierPublicLabel: source.courierPublicLabel,
    vehicleKind: source.vehicleKind,
    courierCoordinate: source.courierCoordinate,
    horizontalAccuracyMeters: source.horizontalAccuracyMeters,
    bearingDegrees: source.bearingDegrees,
    speedMetersPerSecond: source.speedMetersPerSecond,
    observedAt: source.observedAt,
    receivedAt: source.receivedAt,
    etaStartsAt: source.etaStartsAt,
    etaEndsAt: source.etaEndsAt,
    destinationCoordinate: source.destinationCoordinate,
    storeCoordinate: source.storeCoordinate,
    externalCarrier: source.externalCarrier,
    externalTrackingCodeMasked: source.externalTrackingCodeMasked,
    externalTrackingUrl: source.externalTrackingUrl,
  );
}

final class _BlockingDeliveryMapAdapter implements DeliveryMapAdapter {
  final renderStarted = Completer<void>();
  final releaseRender = Completer<void>();
  var disposeCalls = 0;

  @override
  Future<void> render(DeliveryMapScene scene) async {
    renderStarted.complete();
    await releaseRender.future;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}
