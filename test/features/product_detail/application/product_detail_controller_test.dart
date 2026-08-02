import 'dart:async';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/product_detail/application/product_detail_controller.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../storefront/storefront_test_fixture.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';

void main() {
  test('carica dettaglio route-scoped con publication ID esatto', () async {
    final repository = _DetailRepository([
      () async => validStorefrontHomeData().featured.single,
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      productDetailControllerProvider(_publicationId),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await _flush();

    final state = container.read(
      productDetailControllerProvider(_publicationId),
    );
    expect(state.status, ProductDetailLoadStatus.data);
    expect(state.product?.name, 'Café destacado');
    expect(repository.calls.single, _publicationId);
  });

  test('route ID invalido fallisce chiusa senza rete', () async {
    final repository = _DetailRepository(const []);
    final container = _container(repository);
    addTearDown(container.dispose);

    final state = container.read(
      productDetailControllerProvider('../inventory'),
    );

    expect(state.status, ProductDetailLoadStatus.unavailable);
    expect(repository.calls, isEmpty);
  });

  test('timeout produce offline e retry carica il prodotto', () async {
    final repository = _DetailRepository([
      () => Future.error(
        const StorefrontFailure(
          StorefrontFailureKind.timeout,
          code: 'request_timeout',
        ),
      ),
      () async => validStorefrontHomeData().featured.single,
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      productDetailControllerProvider(_publicationId),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await _flush();

    expect(
      container.read(productDetailControllerProvider(_publicationId)).status,
      ProductDetailLoadStatus.offline,
    );

    await container
        .read(productDetailControllerProvider(_publicationId).notifier)
        .retry();

    expect(
      container.read(productDetailControllerProvider(_publicationId)).status,
      ProductDetailLoadStatus.data,
    );
    expect(repository.calls, hasLength(2));
  });

  test('dispose cancella la richiesta e ignora la risposta tardiva', () async {
    final pending = Completer<StorefrontProductSummary>();
    final repository = _DetailRepository([() => pending.future]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      productDetailControllerProvider(_publicationId),
      (_, _) {},
      fireImmediately: true,
    );
    await _flush();
    expect(repository.cancellations, hasLength(1));

    subscription.close();
    await container.pump();
    expect(repository.cancellations.single.isCancelled, isTrue);

    pending.complete(validStorefrontHomeData().featured.single);
    await _flush();
    expect(repository.cancellations.single.isCancelled, isTrue);
  });

  test('unavailable non espone se shop o prodotto esiste', () async {
    final repository = _DetailRepository([
      () => Future.error(
        const StorefrontFailure(
          StorefrontFailureKind.unavailable,
          code: 'storefront_unavailable',
        ),
      ),
    ]);
    final container = _container(repository);
    addTearDown(container.dispose);
    final subscription = container.listen(
      productDetailControllerProvider(_publicationId),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await _flush();

    final state = container.read(
      productDetailControllerProvider(_publicationId),
    );
    expect(state.status, ProductDetailLoadStatus.unavailable);
    expect(state.product, isNull);
    expect(state.failure, isNull);
  });
}

ProviderContainer _container(_DetailRepository repository) => ProviderContainer(
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
      const _ReadyRepository(),
    ),
    storefrontRepositoryProvider.overrideWithValue(repository),
  ],
);

Future<void> _flush() async {
  for (var index = 0; index < 6; index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

typedef _DetailResponse = Future<StorefrontProductSummary> Function();

final class _DetailRepository extends HomeOnlyStorefrontRepository {
  _DetailRepository(this.responses);

  final List<_DetailResponse> responses;
  final List<String> calls = [];
  final List<StorefrontRequestCancellation> cancellations = [];

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) {
    calls.add(publicationId);
    cancellations.add(cancellation);
    return responses[calls.length - 1]();
  }

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchHome is outside this test');
}

final class _ReadyRepository implements BackendReadinessRepository {
  const _ReadyRepository();

  @override
  BackendReadinessState get initialState => BackendReadinessState.ready;

  @override
  bool get canCheck => false;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => BackendReadinessState.ready;
}
