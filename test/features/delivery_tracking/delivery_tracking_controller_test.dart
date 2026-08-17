import 'dart:async';

import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/core/observability/observability_event.dart';
import 'package:client_merchandise_control/core/observability/observability_port.dart';
import 'package:client_merchandise_control/core/observability/observability_providers.dart';
import 'package:client_merchandise_control/core/time/app_scheduler.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_controller.dart';
import 'package:client_merchandise_control/features/delivery_tracking/application/delivery_tracking_providers.dart';
import 'package:client_merchandise_control/features/delivery_tracking/data/supabase_delivery_tracking_repository.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_failure.dart';
import 'package:client_merchandise_control/features/delivery_tracking/domain/delivery_tracking_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_tracking_test_support.dart';
import '../../support/manual_app_scheduler.dart';
import '../../support/collecting_observability.dart';

void main() {
  test(
    'telemetry tracking non espone ordine, coordinate o tracking URL',
    () async {
      final observability = CollectingObservabilityPort();
      final repository = FakeDeliveryTrackingRepository();
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        observability: observability,
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);

      final events = observability.events.where(
        (event) => event.name == ObservabilityEventName.trackingAvailability,
      );
      expect(events, isNotEmpty);
      final payload = observability.events
          .map((event) => event.toSafeMap(environment: 'staging'))
          .toList()
          .toString();
      expect(payload, isNot(contains(trackingTestOrder)));
      expect(payload, isNot(contains('-33.')));
      expect(payload, isNot(contains('-70.')));
      expect(payload, isNot(contains('http')));
    },
  );

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
    'RPC online invariata ripristina ready e riattiva freshness dalla cache',
    () async {
      final scheduler = ManualAppScheduler(start: trackingTestNow);
      final repository = FakeDeliveryTrackingRepository();
      final cache = MemoryDeliveryTrackingCache()
        ..snapshot = trackingLiveSnapshot();
      final container = _container(
        repository: repository,
        cache: cache,
        pollInterval: const Duration(milliseconds: 10),
        freshnessThreshold: const Duration(milliseconds: 1050),
        clock: scheduler.now,
        scheduler: scheduler,
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);

      var state = container.read(deliveryTrackingControllerProvider);
      expect(state.status, DeliveryTrackingStatus.ready);
      expect(state.failure, isNull);
      expect(state.isPollingFallback, isFalse);
      expect(repository.loadCalls, 1);
      expect(cache.saveCalls, 0);

      scheduler.advance(const Duration(milliseconds: 1050));
      await _flush();
      state = container.read(deliveryTrackingControllerProvider);
      expect(state.snapshot?.freshness, DeliveryTrackingFreshness.stale);
      expect(state.snapshot?.hasFreshLiveLocation, isFalse);
      expect(repository.loadCalls, 1);
    },
  );

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
      final scheduler = ManualAppScheduler(start: trackingTestNow);
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        pollInterval: const Duration(milliseconds: 15),
        reconnectBase: const Duration(milliseconds: 5),
        scheduler: scheduler,
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
      await _flush();
      scheduler.advance(const Duration(milliseconds: 5));
      await _flush();

      final state = container.read(deliveryTrackingControllerProvider);
      expect(state.snapshot, isNotNull);
      expect(repository.loadCalls, greaterThanOrEqualTo(2));
      expect(repository.watchCalls, greaterThanOrEqualTo(2));
    },
  );

  test('Realtime sano non esegue polling periodico', () async {
    final repository = FakeDeliveryTrackingRepository();
    final scheduler = ManualAppScheduler(start: trackingTestNow);
    final container = _container(
      repository: repository,
      cache: MemoryDeliveryTrackingCache(),
      pollInterval: const Duration(milliseconds: 10),
      scheduler: scheduler,
    );
    addTearDown(() async {
      container.dispose();
      await repository.stream.close();
    });

    container.read(deliveryTrackingControllerProvider);
    await container
        .read(deliveryTrackingControllerProvider.notifier)
        .open(trackingTestOrder);
    scheduler.advance(const Duration(milliseconds: 45));
    await _flush();

    expect(repository.loadCalls, 1);
    expect(
      container.read(deliveryTrackingControllerProvider).isPollingFallback,
      isFalse,
    );
  });

  test('evento Realtime valido arresta il polling fallback', () async {
    final repository = FakeDeliveryTrackingRepository();
    final scheduler = ManualAppScheduler(start: trackingTestNow);
    final container = _container(
      repository: repository,
      cache: MemoryDeliveryTrackingCache(),
      pollInterval: const Duration(milliseconds: 10),
      reconnectBase: const Duration(milliseconds: 5),
      scheduler: scheduler,
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
    await _flush();
    scheduler.advance(const Duration(milliseconds: 5));
    await _flush();
    expect(repository.watchCalls, greaterThanOrEqualTo(2));

    repository.stream.add(trackingLiveSnapshot(version: 5));
    await _flush();
    expect(
      container.read(deliveryTrackingControllerProvider).isPollingFallback,
      isFalse,
    );
    final callsAfterRecovery = repository.loadCalls;
    scheduler.advance(const Duration(milliseconds: 35));
    await _flush();

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
      var clock = trackingTestNow;
      final repository = FakeDeliveryTrackingRepository();
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        freshnessThreshold: const Duration(milliseconds: 1200),
        clock: () => clock,
      );
      container.read(deliveryTrackingControllerProvider);
      final controller = container.read(
        deliveryTrackingControllerProvider.notifier,
      );
      await controller.open(trackingTestOrder);
      expect(
        container.read(deliveryTrackingControllerProvider).snapshot?.freshness,
        DeliveryTrackingFreshness.fresh,
        reason: lifecycle,
      );

      if (lifecycle == 'foreground') {
        await controller.setForeground(false);
        clock = trackingTestNow.add(const Duration(seconds: 3));
        await controller.setForeground(true);
      } else {
        await controller.setRouteVisible(false);
        clock = trackingTestNow.add(const Duration(seconds: 3));
        await controller.setRouteVisible(true);
      }

      expect(repository.watchCalls, 2, reason: lifecycle);
      expect(repository.watchCancelCalls, 1, reason: lifecycle);
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
    final scheduler = ManualAppScheduler(start: trackingTestNow);
    final container = _container(
      repository: repository,
      cache: MemoryDeliveryTrackingCache(),
      pollInterval: const Duration(milliseconds: 10),
      scheduler: scheduler,
    );
    addTearDown(() async {
      container.dispose();
      await repository.stream.close();
    });

    container.read(deliveryTrackingControllerProvider);
    await container
        .read(deliveryTrackingControllerProvider.notifier)
        .open(trackingTestOrder);
    scheduler.advance(const Duration(milliseconds: 30));
    await _flush();

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
      final scheduler = ManualAppScheduler(start: trackingTestNow);
      final container = _container(
        repository: repository,
        cache: MemoryDeliveryTrackingCache(),
        pollInterval: const Duration(milliseconds: 10),
        freshnessThreshold: const Duration(milliseconds: 1050),
        clock: scheduler.now,
        scheduler: scheduler,
      );
      addTearDown(() async {
        container.dispose();
        await repository.stream.close();
      });

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      scheduler.advance(const Duration(milliseconds: 1050));
      await _flush();
      final snapshot = container
          .read(deliveryTrackingControllerProvider)
          .snapshot;
      expect(snapshot?.freshness, DeliveryTrackingFreshness.stale);
      expect(repository.loadCalls, 1);
    },
  );

  test(
    'logout durante fallback cancella runtime e ignora eventi account precedente',
    () async {
      final scheduler = ManualAppScheduler(start: trackingTestNow);
      final repository = FakeDeliveryTrackingRepository();
      final cache = _OwnerAwareDeliveryTrackingCache();
      final identity = StateProvider<AuthenticatedCustomer?>((ref) {
        return _customer(trackingTestOwner);
      });
      final container = _container(
        repository: repository,
        cache: cache,
        pollInterval: const Duration(milliseconds: 15),
        reconnectBase: const Duration(milliseconds: 5),
        scheduler: scheduler,
        identityState: identity,
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
      await _flush();
      expect(scheduler.activeTaskCount, greaterThanOrEqualTo(2));

      container.read(identity.notifier).state = null;
      await _flush();
      final callsAfterLogout = repository.loadCalls;
      final savesAfterLogout = cache.saveOwners.length;

      scheduler.advance(const Duration(minutes: 10));
      repository.stream.add(trackingLiveSnapshot(version: 99));
      await _flush();

      final state = container.read(deliveryTrackingControllerProvider);
      expect(state.status, DeliveryTrackingStatus.signedOut);
      expect(state.snapshot, isNull);
      expect(repository.watchCancelCalls, 1);
      expect(repository.loadCalls, callsAfterLogout);
      expect(cache.saveOwners.length, savesAfterLogout);
      expect(cache.clearOwners, [trackingTestOwner]);
      expect(scheduler.activeTaskCount, 0);
    },
  );

  test(
    'cambio account durante fallback non pubblica o conserva dati precedenti',
    () async {
      const nextOwner = '10000000-0000-4000-8000-000000044002';
      final scheduler = ManualAppScheduler(start: trackingTestNow);
      final repository = FakeDeliveryTrackingRepository();
      final cache = _OwnerAwareDeliveryTrackingCache();
      final identity = StateProvider<AuthenticatedCustomer?>((ref) {
        return _customer(trackingTestOwner);
      });
      final container = _container(
        repository: repository,
        cache: cache,
        pollInterval: const Duration(milliseconds: 15),
        reconnectBase: const Duration(milliseconds: 5),
        scheduler: scheduler,
        identityState: identity,
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
      await _flush();
      expect(cache.snapshotsByOwner[trackingTestOwner], isNotNull);
      expect(scheduler.activeTaskCount, greaterThanOrEqualTo(2));

      container.read(identity.notifier).state = _customer(nextOwner);
      await _flush();
      final callsAfterSwitch = repository.loadCalls;
      final savesAfterSwitch = cache.saveOwners.length;

      scheduler.advance(const Duration(minutes: 10));
      repository.stream.add(trackingLiveSnapshot(version: 99));
      await _flush();

      final state = container.read(deliveryTrackingControllerProvider);
      expect(state.status, DeliveryTrackingStatus.idle);
      expect(state.snapshot, isNull);
      expect(repository.watchCancelCalls, 1);
      expect(repository.loadCalls, callsAfterSwitch);
      expect(cache.saveOwners.length, savesAfterSwitch);
      expect(cache.clearOwners, [trackingTestOwner]);
      expect(cache.snapshotsByOwner[trackingTestOwner], isNull);
      expect(cache.snapshotsByOwner[nextOwner], isNull);
      expect(scheduler.activeTaskCount, 0);
    },
  );

  test(
    'dispose durante fallback cancella subscription e tutti i timer',
    () async {
      final scheduler = ManualAppScheduler(start: trackingTestNow);
      final repository = FakeDeliveryTrackingRepository();
      final cache = _OwnerAwareDeliveryTrackingCache();
      final container = _container(
        repository: repository,
        cache: cache,
        pollInterval: const Duration(milliseconds: 15),
        reconnectBase: const Duration(milliseconds: 5),
        scheduler: scheduler,
      );

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      repository.stream.addError(const DeliveryTrackingRealtimeException());
      await _flush();
      expect(scheduler.activeTaskCount, greaterThanOrEqualTo(2));

      container.dispose();
      await _flush();
      final callsAfterDispose = repository.loadCalls;
      final savesAfterDispose = cache.saveOwners.length;
      scheduler.advance(const Duration(minutes: 10));
      repository.stream.add(trackingLiveSnapshot(version: 99));
      await _flush();

      expect(repository.watchCancelCalls, 1);
      expect(repository.loadCalls, callsAfterDispose);
      expect(cache.saveOwners.length, savesAfterDispose);
      expect(scheduler.activeTaskCount, 0);
      await repository.stream.close();
    },
  );

  test(
    'dispose durante logout con unsubscribe asincrono completa il purge owner',
    () async {
      final scheduler = ManualAppScheduler(start: trackingTestNow);
      final cancelStarted = Completer<void>();
      final cancelRelease = Completer<void>();
      final repository = FakeDeliveryTrackingRepository()
        ..watchCancelStarted = cancelStarted
        ..watchCancelRelease = cancelRelease;
      final cache = _OwnerAwareDeliveryTrackingCache();
      final identity = StateProvider<AuthenticatedCustomer?>((ref) {
        return _customer(trackingTestOwner);
      });
      final container = _container(
        repository: repository,
        cache: cache,
        pollInterval: const Duration(milliseconds: 15),
        reconnectBase: const Duration(milliseconds: 5),
        scheduler: scheduler,
        identityState: identity,
      );

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      repository.stream.addError(const DeliveryTrackingRealtimeException());
      await _flush();

      container.read(identity.notifier).state = null;
      await cancelStarted.future;
      await _flush();

      final signedOut = container.read(deliveryTrackingControllerProvider);
      expect(signedOut.status, DeliveryTrackingStatus.signedOut);
      expect(signedOut.snapshot, isNull);
      expect(cache.clearOwners, [trackingTestOwner]);
      expect(cache.snapshotsByOwner[trackingTestOwner], isNull);
      expect(scheduler.activeTaskCount, 0);

      container.dispose();
      cancelRelease.complete();
      await _flush();

      expect(repository.watchCancelCalls, 1);
      expect(scheduler.activeTaskCount, 0);
      await repository.stream.close();
    },
  );

  test(
    'cambio account con unsubscribe asincrono invalida stato e cache subito',
    () async {
      const nextOwner = '10000000-0000-4000-8000-000000044002';
      final cancelStarted = Completer<void>();
      final cancelRelease = Completer<void>();
      final repository = FakeDeliveryTrackingRepository()
        ..watchCancelStarted = cancelStarted
        ..watchCancelRelease = cancelRelease;
      final cache = _OwnerAwareDeliveryTrackingCache();
      final identity = StateProvider<AuthenticatedCustomer?>((ref) {
        return _customer(trackingTestOwner);
      });
      final container = _container(
        repository: repository,
        cache: cache,
        identityState: identity,
      );

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);

      container.read(identity.notifier).state = _customer(nextOwner);
      await cancelStarted.future;
      await _flush();

      final switched = container.read(deliveryTrackingControllerProvider);
      expect(switched.status, DeliveryTrackingStatus.idle);
      expect(switched.snapshot, isNull);
      expect(cache.clearOwners, [trackingTestOwner]);
      expect(cache.snapshotsByOwner[trackingTestOwner], isNull);
      expect(cache.snapshotsByOwner[nextOwner], isNull);

      container.dispose();
      cancelRelease.complete();
      await _flush();
      expect(repository.watchCancelCalls, 1);
      await repository.stream.close();
    },
  );

  test(
    'dispose durante close con unsubscribe asincrono completa il purge owner',
    () async {
      final cancelStarted = Completer<void>();
      final cancelRelease = Completer<void>();
      final repository = FakeDeliveryTrackingRepository()
        ..watchCancelStarted = cancelStarted
        ..watchCancelRelease = cancelRelease;
      final cache = _OwnerAwareDeliveryTrackingCache();
      final container = _container(repository: repository, cache: cache);

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);

      final close = container
          .read(deliveryTrackingControllerProvider.notifier)
          .close(clearCache: true);
      await cancelStarted.future;
      await _flush();

      final closed = container.read(deliveryTrackingControllerProvider);
      expect(closed.status, DeliveryTrackingStatus.idle);
      expect(closed.snapshot, isNull);
      expect(cache.clearOwners, [trackingTestOwner]);
      expect(cache.snapshotsByOwner[trackingTestOwner], isNull);

      container.dispose();
      cancelRelease.complete();
      await close;

      expect(repository.watchCancelCalls, 1);
      await repository.stream.close();
    },
  );

  test(
    'dispose durante unauthorized asincrono completa il purge owner',
    () async {
      final cancelStarted = Completer<void>();
      final cancelRelease = Completer<void>();
      final repository = FakeDeliveryTrackingRepository()
        ..watchCancelStarted = cancelStarted
        ..watchCancelRelease = cancelRelease;
      final cache = _OwnerAwareDeliveryTrackingCache();
      final container = _container(repository: repository, cache: cache);

      container.read(deliveryTrackingControllerProvider);
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);
      repository.loadError = const DeliveryTrackingRepositoryException(
        DeliveryTrackingFailureKind.unauthorized,
      );

      final refresh = container
          .read(deliveryTrackingControllerProvider.notifier)
          .refresh();
      await cancelStarted.future;
      await _flush();

      final unauthorized = container.read(deliveryTrackingControllerProvider);
      expect(unauthorized.status, DeliveryTrackingStatus.failure);
      expect(unauthorized.failure, DeliveryTrackingFailureKind.unauthorized);
      expect(unauthorized.snapshot, isNull);
      expect(cache.clearOwners, [trackingTestOwner]);
      expect(cache.snapshotsByOwner[trackingTestOwner], isNull);

      container.dispose();
      cancelRelease.complete();
      await refresh;

      expect(repository.watchCancelCalls, 1);
      await repository.stream.close();
    },
  );

  test(
    'pubblicazione realtime tracking rispetta budget e non avvia request extra',
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
      await container
          .read(deliveryTrackingControllerProvider.notifier)
          .open(trackingTestOrder);

      for (var version = 5; version < 10; version++) {
        repository.stream.add(trackingLiveSnapshot(version: version));
        await _waitFor(
          container,
          (state) => state.snapshot?.version == version,
        );
      }
      final samples = <int>[];
      for (var version = 10; version < 40; version++) {
        final stopwatch = Stopwatch()..start();
        repository.stream.add(trackingLiveSnapshot(version: version));
        await _waitFor(
          container,
          (state) => state.snapshot?.version == version,
        );
        stopwatch.stop();
        samples.add(stopwatch.elapsedMicroseconds);
      }

      final p50 = _percentileMicros(samples, 0.50);
      final p95 = _percentileMicros(samples, 0.95);
      final p99 = _percentileMicros(samples, 0.99);
      debugPrint(
        'TRACKING_PUBLICATION_PERF environment=flutter_test_host '
        'warmup=5 samples=30 p50_us=$p50 p95_us=$p95 p99_us=$p99 '
        'rpc_loads=${repository.loadCalls} realtime_subscriptions=${repository.watchCalls}',
      );
      expect(p95, lessThan(100000));
      expect(repository.loadCalls, 1);
      expect(repository.watchCalls, 1);
    },
    tags: const ['performance'],
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

final class _OwnerAwareDeliveryTrackingCache
    extends MemoryDeliveryTrackingCache {
  final Map<String, DeliveryTrackingSnapshot> snapshotsByOwner = {};
  final List<String> saveOwners = [];
  final List<String> clearOwners = [];

  @override
  Future<void> clear({required String ownerSubjectId}) async {
    clearOwners.add(ownerSubjectId);
    snapshotsByOwner.remove(ownerSubjectId);
  }

  @override
  Future<DeliveryTrackingSnapshot?> read({
    required String ownerSubjectId,
    required String shopSlug,
    required String orderId,
  }) async {
    final snapshot = snapshotsByOwner[ownerSubjectId];
    return snapshot?.orderId == orderId ? snapshot : null;
  }

  @override
  Future<void> save({
    required String ownerSubjectId,
    required String shopSlug,
    required DeliveryTrackingSnapshot snapshot,
  }) async {
    saveOwners.add(ownerSubjectId);
    snapshotsByOwner[ownerSubjectId] = snapshot;
  }
}

AuthenticatedCustomer _customer(String subjectId) {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: subjectId,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Customer Test'},
  );
}

ProviderContainer _container({
  required FakeDeliveryTrackingRepository repository,
  required MemoryDeliveryTrackingCache cache,
  Duration pollInterval = const Duration(hours: 1),
  Duration reconnectBase = const Duration(seconds: 1),
  Duration freshnessThreshold = const Duration(seconds: 120),
  DateTime Function()? clock,
  AppScheduler? scheduler,
  StateProvider<AuthenticatedCustomer?>? identityState,
  ObservabilityPort? observability,
}) {
  final customer = _customer(trackingTestOwner);
  return ProviderContainer(
    overrides: [
      if (identityState == null)
        deliveryTrackingIdentityProvider.overrideWithValue(customer)
      else
        deliveryTrackingIdentityProvider.overrideWith(
          (ref) => ref.watch(identityState),
        ),
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
      if (scheduler != null) appSchedulerProvider.overrideWithValue(scheduler),
      if (observability != null)
        observabilityProvider.overrideWithValue(observability),
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
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('delivery tracking state timeout');
}

Future<void> _flush() async {
  for (var iteration = 0; iteration < 12; iteration++) {
    await Future<void>.delayed(Duration.zero);
  }
}

int _percentileMicros(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * percentile).ceil()];
}
