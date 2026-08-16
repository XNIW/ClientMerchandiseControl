import 'dart:async';

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

  test('Realtime sano non esegue polling periodico', () async {
    final repository = FakeDeliveryTrackingRepository();
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
    await Future<void>.delayed(const Duration(milliseconds: 45));

    expect(repository.loadCalls, 1);
    expect(
      container.read(deliveryTrackingControllerProvider).isPollingFallback,
      isFalse,
    );
  });

  test('evento Realtime valido arresta il polling fallback', () async {
    final repository = FakeDeliveryTrackingRepository();
    final container = _container(
      repository: repository,
      cache: MemoryDeliveryTrackingCache(),
      pollInterval: const Duration(milliseconds: 10),
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
    await _waitFor(
      container,
      (state) => state.isPollingFallback && repository.loadCalls >= 2,
    );
    await _waitFor(container, (_) => repository.watchCalls >= 2);

    repository.stream.add(trackingLiveSnapshot(version: 5));
    await _waitFor(
      container,
      (state) => state.snapshot?.version == 5 && !state.isPollingFallback,
    );
    final callsAfterRecovery = repository.loadCalls;
    await Future<void>.delayed(const Duration(milliseconds: 35));

    expect(repository.loadCalls, callsAfterRecovery);
  });

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

  test('resume riattiva freshness anche con snapshot RPC invariato', () async {
    for (final lifecycle in ['foreground', 'route']) {
      final wallClock = Stopwatch()..start();
      final repository = FakeDeliveryTrackingRepository();
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        freshnessThreshold: const Duration(milliseconds: 1200),
        clock: () => trackingTestNow.add(wallClock.elapsed),
      );
      container.read(deliveryTrackingControllerProvider);
      final controller = container.read(
        deliveryTrackingControllerProvider.notifier,
      );
      await controller.open(trackingTestOrder);

      if (lifecycle == 'foreground') {
        await controller.setForeground(false);
        await controller.setForeground(true);
      } else {
        await controller.setRouteVisible(false);
        await controller.setRouteVisible(true);
      }

      expect(repository.watchCalls, 2, reason: lifecycle);
      expect(repository.watchCancelCalls, 1, reason: lifecycle);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final snapshot = container
          .read(deliveryTrackingControllerProvider)
          .snapshot;
      expect(
        snapshot?.freshness,
        DeliveryTrackingFreshness.stale,
        reason: lifecycle,
      );
      expect(snapshot?.hasFreshLiveLocation, isFalse, reason: lifecycle);

      container.dispose();
      await repository.stream.close();
    }
  });

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

  test(
    'terminal snapshot cannot be overwritten by an older concurrent live save',
    () async {
      final repository = FakeDeliveryTrackingRepository();
      final cache = _BlockingDeliveryTrackingCache();
      final container = _container(repository: repository, cache: cache);
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      final terminal = _terminalSnapshot(version: 6);
      repository.stream.add(terminal);
      await cache.terminalSaveStarted.future;
      repository.stream.add(trackingLiveSnapshot(version: 5));
      await Future<void>.delayed(Duration.zero);

      cache.releaseTerminalSave.complete();
      await _waitFor(container, (state) => state.snapshot?.version == 6);
      cache.releaseOlderLiveSave.complete();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(deliveryTrackingControllerProvider);
      expect(state.snapshot?.version, 6);
      expect(state.snapshot?.isTerminal, isTrue);
      expect(state.snapshot?.courierCoordinate, isNull);
      expect(cache.snapshot?.version, 6);
    },
  );

  test('unauthorized clears memory, cache and never starts runtime', () async {
    final repository = FakeDeliveryTrackingRepository()
      ..loadError = const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.unauthorized,
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
    expect(state.status, DeliveryTrackingStatus.failure);
    expect(state.failure, DeliveryTrackingFailureKind.unauthorized);
    expect(state.snapshot, isNull);
    expect(cache.snapshot, isNull);
    expect(cache.clearCalls, 1);
    expect(repository.watchCalls, 0);
  });

  test('route visibility stops and resumes one order-scoped runtime', () async {
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
    expect(repository.watchCalls, 1);

    await controller.setRouteVisible(false);
    expect(repository.watchCancelCalls, 1);

    await controller.setRouteVisible(true);
    expect(repository.watchCalls, 2);
  });

  test(
    'freshness expires on polling without a newer snapshot version',
    () async {
      var clock = trackingTestNow;
      final repository = FakeDeliveryTrackingRepository();
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        clock: () => clock,
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
      expect(
        container
            .read(deliveryTrackingControllerProvider)
            .snapshot
            ?.hasFreshLiveLocation,
        isTrue,
      );

      clock = trackingTestNow.add(const Duration(minutes: 3));
      await controller.refresh();

      final snapshot = container
          .read(deliveryTrackingControllerProvider)
          .snapshot;
      expect(snapshot?.version, 4);
      expect(snapshot?.freshness, DeliveryTrackingFreshness.stale);
      expect(snapshot?.hasFreshLiveLocation, isFalse);
    },
  );

  test(
    'freshness scade localmente senza eseguire una RPC di polling',
    () async {
      final repository = FakeDeliveryTrackingRepository();
      final wallClock = Stopwatch()..start();
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        pollInterval: const Duration(milliseconds: 10),
        freshnessThreshold: const Duration(milliseconds: 1050),
        clock: () => trackingTestNow.add(wallClock.elapsed),
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      final snapshot = container
          .read(deliveryTrackingControllerProvider)
          .snapshot;
      expect(snapshot?.freshness, DeliveryTrackingFreshness.stale);
      expect(repository.loadCalls, 1);
    },
  );
}

DeliveryTrackingSnapshot _terminalSnapshot({required int version}) {
  final payload = trackingLivePayload(
    version: version,
    orderStatusVersion: version,
    orderStatus: 'completed',
    trackingState: 'completed',
    freshness: 'ended',
  );
  for (final key in const [
    'trackingSessionId',
    'courierPublicLabel',
    'latitude',
    'longitude',
    'horizontalAccuracyMeters',
    'bearingDegrees',
    'speedMetersPerSecond',
    'observedAt',
    'receivedAt',
    'destinationLatitude',
    'destinationLongitude',
    'storeLatitude',
    'storeLongitude',
  ]) {
    payload[key] = null;
  }
  return parseDeliveryTrackingSnapshot(payload);
}

final class _BlockingDeliveryTrackingCache extends MemoryDeliveryTrackingCache {
  final terminalSaveStarted = Completer<void>();
  final releaseTerminalSave = Completer<void>();
  final releaseOlderLiveSave = Completer<void>();

  @override
  Future<void> save({
    required String ownerSubjectId,
    required String shopSlug,
    required DeliveryTrackingSnapshot snapshot,
  }) async {
    if (snapshot.version == 6) {
      terminalSaveStarted.complete();
      await releaseTerminalSave.future;
    } else if (snapshot.version == 5) {
      await releaseOlderLiveSave.future;
    }
    await super.save(
      ownerSubjectId: ownerSubjectId,
      shopSlug: shopSlug,
      snapshot: snapshot,
    );
  }
}

ProviderContainer _container({
  required FakeDeliveryTrackingRepository repository,
  required MemoryDeliveryTrackingCache cache,
  Duration pollInterval = const Duration(hours: 1),
  Duration reconnectBase = const Duration(seconds: 1),
  Duration freshnessThreshold = const Duration(seconds: 120),
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
      deliveryTrackingFreshnessThresholdProvider.overrideWithValue(
        freshnessThreshold,
      ),
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
