import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../storefront/application/storefront_providers.dart';
import '../../storefront/cache/storefront_cache_repository.dart';
import '../../storefront/domain/storefront_failure.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/domain/storefront_repository.dart';

enum HomeLoadStatus { loading, data, empty, offline, unavailable, failure }

class HomeState {
  const HomeState._(
    this.status, {
    this.data,
    this.failure,
    this.isFromCache = false,
    this.isStale = false,
    this.isRefreshing = false,
    this.cachedAt,
  });

  const HomeState.loading() : this._(HomeLoadStatus.loading);
  const HomeState.empty({
    bool isFromCache = false,
    bool isStale = false,
    bool isRefreshing = false,
    DateTime? cachedAt,
  }) : this._(
         HomeLoadStatus.empty,
         isFromCache: isFromCache,
         isStale: isStale,
         isRefreshing: isRefreshing,
         cachedAt: cachedAt,
       );
  const HomeState.offline() : this._(HomeLoadStatus.offline);
  const HomeState.unavailable() : this._(HomeLoadStatus.unavailable);
  const HomeState.failure(StorefrontFailure failure)
    : this._(HomeLoadStatus.failure, failure: failure);
  const HomeState.data(
    StorefrontHomeData data, {
    StorefrontFailure? failure,
    bool isFromCache = false,
    bool isStale = false,
    bool isRefreshing = false,
    DateTime? cachedAt,
  }) : this._(
         HomeLoadStatus.data,
         data: data,
         failure: failure,
         isFromCache: isFromCache,
         isStale: isStale,
         isRefreshing: isRefreshing,
         cachedAt: cachedAt,
       );

  final HomeLoadStatus status;
  final StorefrontHomeData? data;
  final StorefrontFailure? failure;
  final bool isFromCache;
  final bool isStale;
  final bool isRefreshing;
  final DateTime? cachedAt;
}

final homeControllerProvider = NotifierProvider<HomeController, HomeState>(
  HomeController.new,
);

class HomeController extends Notifier<HomeState> {
  StorefrontRequestCancellation? _cancellation;
  var _generation = 0;
  var _disposed = false;

  @override
  HomeState build() {
    _disposed = false;
    final readiness = ref.read(backendReadinessControllerProvider);
    ref.listen(
      backendReadinessControllerProvider,
      (_, next) => _handleReadinessChange(next),
    );
    ref.onDispose(_dispose);
    return switch (readiness) {
      BackendReadinessState.ready => _startAfterBuild(),
      BackendReadinessState.initializing => const HomeState.loading(),
      BackendReadinessState.offline => _startCacheAfterBuild(),
      BackendReadinessState.unconfigured => const HomeState.empty(),
      BackendReadinessState.misconfigured ||
      BackendReadinessState.authenticationRequired =>
        const HomeState.unavailable(),
      BackendReadinessState.recoverableError => HomeState.failure(
        const StorefrontFailure(
          StorefrontFailureKind.unavailable,
          code: 'backend_recoverable',
        ),
      ),
    };
  }

  void _handleReadinessChange(BackendReadinessState readiness) {
    if (_disposed) return;
    if (readiness == BackendReadinessState.ready) {
      unawaited(_load());
      return;
    }
    if (readiness == BackendReadinessState.offline) {
      unawaited(_load(cacheOnly: true));
      return;
    }
    _generation += 1;
    _cancellation?.cancel();
    state = switch (readiness) {
      BackendReadinessState.initializing => const HomeState.loading(),
      BackendReadinessState.offline => const HomeState.offline(),
      BackendReadinessState.unconfigured => const HomeState.empty(),
      BackendReadinessState.misconfigured ||
      BackendReadinessState.authenticationRequired =>
        const HomeState.unavailable(),
      BackendReadinessState.recoverableError => HomeState.failure(
        const StorefrontFailure(
          StorefrontFailureKind.unavailable,
          code: 'backend_recoverable',
        ),
      ),
      BackendReadinessState.ready => throw StateError('unreachable'),
    };
  }

  Future<void> retry() => _load();

  HomeState _startAfterBuild() {
    scheduleMicrotask(() {
      if (!_disposed) unawaited(_load());
    });
    return const HomeState.loading();
  }

  HomeState _startCacheAfterBuild() {
    scheduleMicrotask(() {
      if (!_disposed) unawaited(_load(cacheOnly: true));
    });
    return const HomeState.offline();
  }

  Future<void> _load({bool cacheOnly = false}) async {
    final config = ref.read(appConfigProvider);
    final shopSlug = config.storefrontShopSlug;
    if (_disposed || shopSlug == null) {
      if (!_disposed) state = const HomeState.unavailable();
      return;
    }
    final generation = ++_generation;
    _cancellation?.cancel();
    final cancellation = StorefrontRequestCancellation();
    _cancellation = cancellation;
    state = const HomeState.loading();
    StorefrontCacheSnapshot<StorefrontHomeData>? cached;
    try {
      cached = await ref
          .read(storefrontCacheRepositoryProvider)
          .readHome(shopSlug: shopSlug);
    } on Object {
      cached = null;
    }
    if (_isStale(generation, cancellation)) return;
    if (cached != null) {
      final fresh = cached.isFreshAt(DateTime.now());
      state = cached.value.isEmpty
          ? HomeState.empty(
              isFromCache: true,
              isStale: !fresh,
              isRefreshing: !cacheOnly,
              cachedAt: cached.refreshedAt,
            )
          : HomeState.data(
              cached.value,
              isFromCache: true,
              isStale: !fresh,
              isRefreshing: !cacheOnly,
              cachedAt: cached.refreshedAt,
            );
    }
    if (cacheOnly) {
      if (cached == null) state = const HomeState.offline();
      return;
    }
    try {
      final data = await ref
          .read(storefrontRepositoryProvider)
          .fetchHome(shopSlug: shopSlug, cancellation: cancellation);
      if (_isStale(generation, cancellation)) return;
      await _persistHome(shopSlug, data);
      if (_isStale(generation, cancellation)) return;
      state = data.isEmpty ? const HomeState.empty() : HomeState.data(data);
    } on StorefrontFailure catch (failure) {
      if (_isStale(generation, cancellation)) return;
      if (cached != null &&
          (failure.kind == StorefrontFailureKind.offline ||
              failure.kind == StorefrontFailureKind.timeout)) {
        state = cached.value.isEmpty
            ? HomeState.empty(
                isFromCache: true,
                isStale: true,
                cachedAt: cached.refreshedAt,
              )
            : HomeState.data(
                cached.value,
                failure: failure,
                isFromCache: true,
                isStale: true,
                cachedAt: cached.refreshedAt,
              );
        return;
      }
      if (_requiresCacheInvalidation(failure)) {
        await _invalidateCache(shopSlug);
        if (_isStale(generation, cancellation)) return;
      }
      state = switch (failure.kind) {
        StorefrontFailureKind.cancelled => state,
        StorefrontFailureKind.offline ||
        StorefrontFailureKind.timeout => const HomeState.offline(),
        StorefrontFailureKind.invalidConfiguration ||
        StorefrontFailureKind.unauthorized ||
        StorefrontFailureKind.unavailable => const HomeState.unavailable(),
        StorefrontFailureKind.catalogChanged ||
        StorefrontFailureKind.invalidPayload ||
        StorefrontFailureKind.unknown => HomeState.failure(failure),
      };
    }
  }

  Future<void> _persistHome(String shopSlug, StorefrontHomeData data) async {
    try {
      final cache = ref.read(storefrontCacheRepositoryProvider);
      await cache.writeHome(shopSlug: shopSlug, data: data);
      await cache.cleanup(shopSlug: shopSlug);
    } on Object {
      // La cache è ricostruibile: un errore locale non degrada dati live validi.
    }
  }

  bool _requiresCacheInvalidation(StorefrontFailure failure) =>
      failure.kind == StorefrontFailureKind.invalidConfiguration ||
      failure.kind == StorefrontFailureKind.unauthorized ||
      failure.kind == StorefrontFailureKind.unavailable ||
      failure.kind == StorefrontFailureKind.invalidPayload;

  Future<void> _invalidateCache(String shopSlug) async {
    try {
      await ref
          .read(storefrontCacheRepositoryProvider)
          .clearShop(shopSlug: shopSlug);
    } on Object {
      // La UI fallisce chiusa anche quando il file locale non è cancellabile.
    }
  }

  bool _isStale(int generation, StorefrontRequestCancellation cancellation) =>
      _disposed || cancellation.isCancelled || generation != _generation;

  void _dispose() {
    _disposed = true;
    _generation += 1;
    _cancellation?.cancel();
  }
}
