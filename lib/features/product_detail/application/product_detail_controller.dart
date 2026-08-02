import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../storefront/application/storefront_providers.dart';
import '../../storefront/domain/storefront_failure.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/domain/storefront_repository.dart';

enum ProductDetailLoadStatus { loading, data, offline, unavailable, failure }

class ProductDetailState {
  const ProductDetailState._(this.status, {this.product, this.failure});

  const ProductDetailState.loading() : this._(ProductDetailLoadStatus.loading);
  const ProductDetailState.offline() : this._(ProductDetailLoadStatus.offline);
  const ProductDetailState.unavailable()
    : this._(ProductDetailLoadStatus.unavailable);
  const ProductDetailState.failure(StorefrontFailure failure)
    : this._(ProductDetailLoadStatus.failure, failure: failure);
  const ProductDetailState.data(StorefrontProductSummary product)
    : this._(ProductDetailLoadStatus.data, product: product);

  final ProductDetailLoadStatus status;
  final StorefrontProductSummary? product;
  final StorefrontFailure? failure;
}

final productDetailControllerProvider = NotifierProvider.autoDispose
    .family<ProductDetailController, ProductDetailState, String>(
      ProductDetailController.new,
    );

class ProductDetailController
    extends AutoDisposeFamilyNotifier<ProductDetailState, String> {
  static final _publicationId = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  StorefrontRequestCancellation? _cancellation;
  var _generation = 0;
  var _disposed = false;

  @override
  ProductDetailState build(String publicationId) {
    _disposed = false;
    ref.onDispose(_dispose);
    if (!_publicationId.hasMatch(publicationId)) {
      return const ProductDetailState.unavailable();
    }
    final readiness = ref.read(backendReadinessControllerProvider);
    ref.listen(
      backendReadinessControllerProvider,
      (_, next) => _handleReadinessChange(next),
    );
    return switch (readiness) {
      BackendReadinessState.ready => _startAfterBuild(),
      BackendReadinessState.initializing => const ProductDetailState.loading(),
      BackendReadinessState.offline => const ProductDetailState.offline(),
      BackendReadinessState.unconfigured ||
      BackendReadinessState.misconfigured ||
      BackendReadinessState.authenticationRequired =>
        const ProductDetailState.unavailable(),
      BackendReadinessState.recoverableError => ProductDetailState.failure(
        const StorefrontFailure(
          StorefrontFailureKind.unavailable,
          code: 'backend_recoverable',
        ),
      ),
    };
  }

  Future<void> retry() {
    final readiness = ref.read(backendReadinessControllerProvider);
    if (readiness != BackendReadinessState.ready) {
      return ref.read(backendReadinessControllerProvider.notifier).retry();
    }
    return _load();
  }

  ProductDetailState _startAfterBuild() {
    scheduleMicrotask(() {
      if (!_disposed) unawaited(_load());
    });
    return const ProductDetailState.loading();
  }

  void _handleReadinessChange(BackendReadinessState readiness) {
    if (_disposed) return;
    if (readiness == BackendReadinessState.ready) {
      unawaited(_load());
      return;
    }
    _cancelCurrentRequest();
    state = switch (readiness) {
      BackendReadinessState.initializing => const ProductDetailState.loading(),
      BackendReadinessState.offline => const ProductDetailState.offline(),
      BackendReadinessState.unconfigured ||
      BackendReadinessState.misconfigured ||
      BackendReadinessState.authenticationRequired =>
        const ProductDetailState.unavailable(),
      BackendReadinessState.recoverableError => ProductDetailState.failure(
        const StorefrontFailure(
          StorefrontFailureKind.unavailable,
          code: 'backend_recoverable',
        ),
      ),
      BackendReadinessState.ready => throw StateError('unreachable'),
    };
  }

  Future<void> _load() async {
    final config = ref.read(appConfigProvider);
    final shopSlug = config.storefrontShopSlug;
    if (_disposed || shopSlug == null) {
      if (!_disposed) state = const ProductDetailState.unavailable();
      return;
    }
    final generation = ++_generation;
    _cancellation?.cancel();
    final cancellation = StorefrontRequestCancellation();
    _cancellation = cancellation;
    state = const ProductDetailState.loading();
    try {
      final product = await ref
          .read(storefrontRepositoryProvider)
          .fetchProductDetail(
            shopSlug: shopSlug,
            publicationId: arg,
            cancellation: cancellation,
          );
      if (_isStale(generation, cancellation)) return;
      state = ProductDetailState.data(product);
    } on StorefrontFailure catch (failure) {
      if (_isStale(generation, cancellation)) return;
      state = switch (failure.kind) {
        StorefrontFailureKind.cancelled => state,
        StorefrontFailureKind.offline ||
        StorefrontFailureKind.timeout => const ProductDetailState.offline(),
        StorefrontFailureKind.invalidConfiguration ||
        StorefrontFailureKind.unauthorized ||
        StorefrontFailureKind.unavailable =>
          const ProductDetailState.unavailable(),
        StorefrontFailureKind.catalogChanged ||
        StorefrontFailureKind.invalidPayload ||
        StorefrontFailureKind.unknown => ProductDetailState.failure(failure),
      };
    }
  }

  void _cancelCurrentRequest() {
    _generation += 1;
    _cancellation?.cancel();
  }

  bool _isStale(int generation, StorefrontRequestCancellation cancellation) =>
      _disposed || cancellation.isCancelled || generation != _generation;

  void _dispose() {
    _disposed = true;
    _cancelCurrentRequest();
  }
}
