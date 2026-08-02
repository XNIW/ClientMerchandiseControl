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
    'avvia Home quando readiness transita da initializing a ready',
    () async {
      final storefrontRepository = _QueuedRepository()
        ..responses.add(() async => validStorefrontHomeData());
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
      expect(storefrontRepository.calls, 0);

      readinessRepository.completeNext(BackendReadinessState.ready);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(storefrontRepository.calls, 1);
      expect(
        container.read(homeControllerProvider).status,
        HomeLoadStatus.data,
      );
    },
  );
}

ProviderContainer _container(StorefrontRepository repository) {
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
      storefrontCacheRepositoryProvider.overrideWithValue(
        const DisabledStorefrontCacheRepository(),
      ),
    ],
  );
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
  final List<Completer<BackendReadinessState>> _results = [];

  int get calls => _results.length;

  @override
  BackendReadinessState get initialState => BackendReadinessState.initializing;

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
