import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_controller.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_providers.dart';
import 'package:client_merchandise_control/features/delivery_tracking/data/supabase_delivery_tracking_repository.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_failure.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_tracking_test_support.dart';

void main() {
  test('cache-first remains readable when initial RPC is offline', () async {
    final repository = FakeDeliveryTrackingRepository()
      ..loadError = const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.offline,
      );
    final cache = MemoryDeliveryTrackingCache()
      ..snapshot = trackingLiveSnapshot();
    final container = _container(repository: repository, cache: cache);
    addTearDown(() async {
      container.dispose();
      await repository.stream.close();
    });

    container.read(deliveryTrackingControllerProvider);
    await container
        .read(deliveryTrackingControllerProvider.notifier)
        .open(trackingTestOrder);

    final state = container.read(deliveryTrackingControllerProvider);
    expect(state.status, DeliveryTrackingStatus.offline);
    expect(state.snapshot?.orderId, trackingTestOrder);
    expect(state.failure, DeliveryTrackingFailureKind.offline);
  });

  test(
    'Realtime deduplicates older versions and accepts a newer snapshot',
    () async {
      final repository = FakeDeliveryTrackingRepository();
      final cache = MemoryDeliveryTrackingCache();
      final container = _container(repository: repository, cache: cache);
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      expect(
        container.read(deliveryTrackingControllerProvider).snapshot?.version,
        4,
      );

      repository.stream.add(trackingLiveSnapshot(version: 3));
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(deliveryTrackingControllerProvider).snapshot?.version,
        4,
      );

      repository.stream.add(trackingLiveSnapshot(version: 5));
      final state = await _waitFor(
        container,
        (state) => state.snapshot?.version == 5,
      );
      expect(state.status, DeliveryTrackingStatus.ready);
      expect(cache.saveCalls, 2);
    },
  );

  test(
    'Realtime failure enables bounded polling fallback and reconnect',
    () async {
      final repository = FakeDeliveryTrackingRepository();
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        pollInterval: const Duration(milliseconds: 15),
        reconnectBase: const Duration(milliseconds: 5),
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      repository.stream.addError(const DeliveryTrackingRealtimeException());

      final state = await _waitFor(
        container,
        (state) => state.isPollingFallback && repository.loadCalls >= 2,
      );
      expect(state.snapshot, isNotNull);
      expect(repository.loadCalls, greaterThanOrEqualTo(2));
    },
  );

  test(
    'background closes active runtime and foreground refreshes safely',
    () async {
      final repository = FakeDeliveryTrackingRepository();
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      final controller = container.read(
        deliveryTrackingControllerProvider.notifier,
      );
      await controller.open(trackingTestOrder);
      await controller.setForeground(false);
      expect(
        container.read(deliveryTrackingControllerProvider).isForeground,
        isFalse,
      );
      final callsBeforeResume = repository.loadCalls;

      await controller.setForeground(true);
      expect(repository.loadCalls, callsBeforeResume + 1);
      await controller.close();
      expect(
        container.read(deliveryTrackingControllerProvider).status,
        DeliveryTrackingStatus.idle,
      );
    },
  );

  test(
    'fresh cached coordinate becomes explicitly stale by local clock',
    () async {
      final repository = FakeDeliveryTrackingRepository()
        ..loadError = const DeliveryTrackingRepositoryException(
          DeliveryTrackingFailureKind.offline,
        );
      final cache = MemoryDeliveryTrackingCache()
        ..snapshot = trackingLiveSnapshot();
      final container = _container(
        repository: repository,
        cache: cache,
        clock: () => trackingTestNow.add(const Duration(minutes: 3)),
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);

      expect(
        container.read(deliveryTrackingControllerProvider).snapshot?.freshness,
        DeliveryTrackingFreshness.stale,
      );
    },
  );

  test(
    'snapshot for another order is rejected at controller boundary',
    () async {
      final repository = FakeDeliveryTrackingRepository()
        ..snapshot = trackingLiveSnapshot(
          orderId: '44000000-0000-4000-8000-000000044099',
        );
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);

      final state = container.read(deliveryTrackingControllerProvider);
      expect(state.status, DeliveryTrackingStatus.failure);
      expect(state.failure, DeliveryTrackingFailureKind.invalid);
      expect(state.snapshot, isNull);
    },
  );

  test('terminal snapshot does not start Realtime or polling', () async {
    final terminalPayload =
        trackingLivePayload(
            orderStatus: 'completed',
            trackingState: 'completed',
            freshness: 'ended',
          )
          ..['trackingSessionId'] = null
          ..['courierPublicLabel'] = null
          ..['latitude'] = null
          ..['longitude'] = null
          ..['horizontalAccuracyMeters'] = null
          ..['bearingDegrees'] = null
          ..['speedMetersPerSecond'] = null
          ..['observedAt'] = null
          ..['receivedAt'] = null
          ..['destinationLatitude'] = null
          ..['destinationLongitude'] = null
          ..['storeLatitude'] = null
          ..['storeLongitude'] = null;
    final repository = FakeDeliveryTrackingRepository()
      ..snapshot = parseDeliveryTrackingSnapshot(terminalPayload);
    final container = _container(
      repository: repository,
      cache: MemoryDeliveryTrackingCache(),
      pollInterval: const Duration(milliseconds: 10),
    );
    addTearDown(() async {
      container.dispose();
      await repository.stream.close();
    });

    container.read(deliveryTrackingControllerProvider);
    await container
        .read(deliveryTrackingControllerProvider.notifier)
        .open(trackingTestOrder);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(repository.watchCalls, 0);
    expect(repository.loadCalls, 1);
    expect(
      container.read(deliveryTrackingControllerProvider).snapshot?.isTerminal,
      isTrue,
    );
  });
}

ProviderContainer _container({
  required FakeDeliveryTrackingRepository repository,
  required MemoryDeliveryTrackingCache cache,
  Duration pollInterval = const Duration(hours: 1),
  Duration reconnectBase = const Duration(seconds: 1),
  DateTime Function()? clock,
}) {
  final customer = AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: trackingTestOwner,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Customer Test'},
  );
  return ProviderContainer(
    overrides: [
      deliveryTrackingIdentityProvider.overrideWithValue(customer),
      deliveryTrackingShopSlugProvider.overrideWithValue(trackingTestShop),
      deliveryTrackingRepositoryProvider.overrideWithValue(repository),
      deliveryTrackingCacheProvider.overrideWithValue(cache),
      deliveryTrackingPollIntervalProvider.overrideWithValue(pollInterval),
      deliveryTrackingReconnectBaseProvider.overrideWithValue(reconnectBase),
      deliveryTrackingClockProvider.overrideWithValue(
        clock ?? (() => trackingTestNow),
      ),
    ],
  );
}

Future<DeliveryTrackingViewState> _waitFor(
  ProviderContainer container,
  bool Function(DeliveryTrackingViewState state) predicate,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    final state = container.read(deliveryTrackingControllerProvider);
    if (predicate(state)) return state;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  throw StateError('delivery tracking state timeout');
}
