import 'dart:async';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../storefront/storefront_test_fixture.dart';

void main() {
  test('carica Home guest e pubblica soltanto il risultato corrente', () async {
    final repository = _QueuedRepository();
    final first = Completer<StorefrontHomeData>();
    final second = Completer<StorefrontHomeData>();
    repository.responses.addAll([() => first.future, () => second.future]);
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      container.read(homeControllerProvider).status,
      HomeLoadStatus.loading,
    );
    await Future<void>.delayed(Duration.zero);
    expect(repository.calls, 1);

    final retry = container.read(homeControllerProvider.notifier).retry();
    await Future<void>.delayed(Duration.zero);
    expect(repository.calls, 2);
    first.complete(
      StorefrontHomeData(
        catalogVersion: 1,
        settings: validStorefrontHomeData().settings,
        categories: const [],
        featured: const [],
        offers: const [],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(homeControllerProvider).status,
      HomeLoadStatus.loading,
    );

    second.complete(validStorefrontHomeData());
    await retry;
    expect(container.read(homeControllerProvider).status, HomeLoadStatus.data);
    expect(
      container.read(homeControllerProvider).data?.featured.single.name,
      'Café destacado',
    );
    expect(repository.cancellations.first.isCancelled, isTrue);
  });

  test(
    'mappa offline, unavailable e payload failure in stati distinti',
    () async {
      for (final entry in const [
        (StorefrontFailureKind.offline, HomeLoadStatus.offline),
        (StorefrontFailureKind.timeout, HomeLoadStatus.offline),
        (StorefrontFailureKind.unauthorized, HomeLoadStatus.unavailable),
        (StorefrontFailureKind.invalidPayload, HomeLoadStatus.failure),
      ]) {
        final repository = _QueuedRepository()
          ..responses.add(
            () => Future<StorefrontHomeData>.error(
              StorefrontFailure(entry.$1, code: 'sanitized'),
            ),
          );
        final container = _container(repository);
        container.read(homeControllerProvider);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        expect(container.read(homeControllerProvider).status, entry.$2);
        container.dispose();
      }
    },
  );

  test(
    'development non configurato resta empty e non invoca repository',
    () async {
      final repository = _QueuedRepository();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromValues()),
          backendReadinessRepositoryProvider.overrideWithValue(
            const _StaticReadinessRepository(
              BackendReadinessState.unconfigured,
            ),
          ),
          storefrontRepositoryProvider.overrideWithValue(repository),
          storefrontCacheRepositoryProvider.overrideWithValue(
            const DisabledStorefrontCacheRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(homeControllerProvider).status,
        HomeLoadStatus.empty,
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, 0);
    },
  );

  test(
    'Home pubblica non attende né viene cancellata dalla readiness Auth',
    () async {
      final storefrontResponse = Completer<StorefrontHomeData>();
      final storefrontRepository = _QueuedRepository()
        ..responses.add(() => storefrontResponse.future);
      final readinessRepository = _CompletableReadinessRepository();
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(
              appEnvironment: 'staging',
              supabaseUrl: 'https://staging.example.invalid',
              supabasePublishableKey: 'sb_publishable_staging',
              authRedirectUri: AppConfig.allowedAuthRedirectUri,
              googleAuthEnabled: 'false',
              storefrontShopSlug: 'storefront-test',
            ),
          ),
          backendReadinessRepositoryProvider.overrideWithValue(
            readinessRepository,
          ),
          backendAutomaticProbeDelayProvider.overrideWithValue(Duration.zero),
          storefrontRepositoryProvider.overrideWithValue(storefrontRepository),
          storefrontCacheRepositoryProvider.overrideWithValue(
            const DisabledStorefrontCacheRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(homeControllerProvider).status,
        HomeLoadStatus.loading,
      );
      await Future<void>.delayed(Duration.zero);
      expect(readinessRepository.calls, 1);
      expect(storefrontRepository.calls, 1);

      readinessRepository.completeNext(BackendReadinessState.offline);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(storefrontRepository.calls, 1);
      expect(storefrontRepository.cancellations.single.isCancelled, isFalse);
      expect(
        container.read(homeControllerProvider).status,
        HomeLoadStatus.loading,
      );

      storefrontResponse.complete(validStorefrontHomeData());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(homeControllerProvider).status,
        HomeLoadStatus.data,
      );
    },
  );

  test('dati live non attendono lettura o persistenza della cache', () async {
    final repository = _QueuedRepository()
      ..responses.add(() async => validStorefrontHomeData());
    final cache = _BlockingHomeCacheRepository();
    final container = _container(repository, cache: cache);
    addTearDown(container.dispose);

    expect(
      container.read(homeControllerProvider).status,
      HomeLoadStatus.loading,
    );
    for (var turn = 0; turn < 5; turn += 1) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(cache.readCalls, 1);
    expect(cache.writeCalls, 1);
    expect(cache.readResult.isCompleted, isFalse);
    expect(cache.writeResult.isCompleted, isFalse);
    expect(container.read(homeControllerProvider).status, HomeLoadStatus.data);

    cache.readResult.complete(null);
    cache.writeResult.complete();
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'reconnect attende la cache offline e poi avvia un solo fetch live',
    () async {
      final repository = _QueuedRepository()
        ..responses.add(() async => validStorefrontHomeData());
      final cache = _BlockingHomeCacheRepository();
      final readinessRepository = _CompletableReadinessRepository(
        initialState: BackendReadinessState.offline,
      );
      final container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(
              appEnvironment: 'staging',
              supabaseUrl: 'https://staging.example.invalid',
              supabasePublishableKey: 'sb_publishable_staging',
              authRedirectUri: AppConfig.allowedAuthRedirectUri,
              googleAuthEnabled: 'false',
              storefrontShopSlug: 'storefront-test',
            ),
          ),
          backendReadinessRepositoryProvider.overrideWithValue(
            readinessRepository,
          ),
          storefrontRepositoryProvider.overrideWithValue(repository),
          storefrontCacheRepositoryProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      container.read(homeControllerProvider);
      await Future<void>.delayed(Duration.zero);
      expect(cache.readCalls, 1);
      expect(repository.calls, 0);

      final reconnect = container
          .read(backendReadinessControllerProvider.notifier)
          .retry();
      readinessRepository.completeNext(BackendReadinessState.ready);
      await reconnect;
      expect(repository.calls, 0);

      cache.readResult.complete(null);
      for (var turn = 0; turn < 5; turn += 1) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(repository.calls, 1);
      expect(
        container.read(homeControllerProvider).status,
        HomeLoadStatus.data,
      );
      cache.writeResult.complete();
    },
  );

  test(
    'Home cache warm pubblica contenuto entro budget con un solo fetch live',
    () async {
      Future<int> measureOnce() async {
        final pendingLive = Completer<StorefrontHomeData>();
        final repository = _QueuedRepository()
          ..responses.add(() => pendingLive.future);
        final cache = _ImmediateHomeCacheRepository();
        final stopwatch = Stopwatch()..start();
        final container = _container(repository, cache: cache);
        container.read(homeControllerProvider);
        for (var turn = 0; turn < 100; turn++) {
          if (container.read(homeControllerProvider).status ==
              HomeLoadStatus.data) {
            break;
          }
          await Future<void>.delayed(Duration.zero);
        }
        stopwatch.stop();
        expect(
          container.read(homeControllerProvider).status,
          HomeLoadStatus.data,
        );
        expect(cache.readCalls, 1);
        expect(repository.calls, 1);
        container.dispose();
        return stopwatch.elapsedMicroseconds;
      }

      for (var warmup = 0; warmup < 5; warmup++) {
        await measureOnce();
      }
      final samples = <int>[];
      for (var sample = 0; sample < 30; sample++) {
        samples.add(await measureOnce());
      }
      final p50 = _percentileMicros(samples, 0.50);
      final p95 = _percentileMicros(samples, 0.95);
      final p99 = _percentileMicros(samples, 0.99);
      debugPrint(
        'HOME_WARM_CACHE_PERF environment=flutter_test_host '
        'warmup=5 samples=30 p50_us=$p50 p95_us=$p95 p99_us=$p99 '
        'cache_reads=1 live_fetches=1',
      );
      expect(p95, lessThan(1000000));
    },
    tags: const ['performance'],
  );
}

ProviderContainer _container(
  StorefrontRepository repository, {
  StorefrontCacheRepository cache = const DisabledStorefrontCacheRepository(),
}) {
  return ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'https://staging.example.invalid',
          supabasePublishableKey: 'sb_publishable_staging',
          authRedirectUri: AppConfig.allowedAuthRedirectUri,
          googleAuthEnabled: 'false',
          storefrontShopSlug: 'storefront-test',
        ),
      ),
      backendReadinessRepositoryProvider.overrideWithValue(
        const _StaticReadinessRepository(BackendReadinessState.ready),
      ),
      storefrontRepositoryProvider.overrideWithValue(repository),
      storefrontCacheRepositoryProvider.overrideWithValue(cache),
    ],
  );
}

final class _BlockingHomeCacheRepository implements StorefrontCacheRepository {
  final readResult = Completer<StorefrontCacheSnapshot<StorefrontHomeData>?>();
  final writeResult = Completer<void>();
  var readCalls = 0;
  var writeCalls = 0;

  @override
  Future<StorefrontCacheSnapshot<StorefrontHomeData>?> readHome({
    required String shopSlug,
  }) {
    readCalls += 1;
    return readResult.future;
  }

  @override
  Future<void> writeHome({
    required String shopSlug,
    required StorefrontHomeData data,
  }) {
    writeCalls += 1;
    return writeResult.future;
  }

  @override
  Future<void> cleanup({required String shopSlug}) async {}

  @override
  Future<void> clearShop({required String shopSlug}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ImmediateHomeCacheRepository implements StorefrontCacheRepository {
  var readCalls = 0;

  @override
  Future<StorefrontCacheSnapshot<StorefrontHomeData>?> readHome({
    required String shopSlug,
  }) async {
    readCalls++;
    return StorefrontCacheSnapshot(
      value: validStorefrontHomeData(),
      refreshedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> cleanup({required String shopSlug}) async {}

  @override
  Future<void> clearShop({required String shopSlug}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _QueuedRepository extends HomeOnlyStorefrontRepository {
  final List<Future<StorefrontHomeData> Function()> responses = [];
  final List<StorefrontRequestCancellation> cancellations = [];
  var calls = 0;

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) {
    cancellations.add(cancellation);
    return responses[calls++]();
  }
}

final class _StaticReadinessRepository implements BackendReadinessRepository {
  const _StaticReadinessRepository(this.initialState);

  @override
  final BackendReadinessState initialState;

  @override
  bool get canCheck => false;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => initialState;
}

final class _CompletableReadinessRepository
    implements BackendReadinessRepository {
  _CompletableReadinessRepository({
    this.initialState = BackendReadinessState.initializing,
  });

  final List<Completer<BackendReadinessState>> _results = [];

  int get calls => _results.length;

  @override
  final BackendReadinessState initialState;

  @override
  bool get canCheck => true;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) {
    final result = Completer<BackendReadinessState>();
    _results.add(result);
    return result.future;
  }

  void completeNext(BackendReadinessState state) {
    _results.firstWhere((result) => !result.isCompleted).complete(state);
  }
}

int _percentileMicros(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * percentile).ceil()];
}
