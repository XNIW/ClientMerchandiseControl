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
  Future<void> _cachePersistence = Future<void>.value();
  var _cacheOnlyInFlight = false;
  var _refreshWhenCacheCompletes = false;
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
      BackendReadinessState.initializing => _startAfterBuild(),
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

  Future<void> retry() => _load();

  void _handleReadinessChange(BackendReadinessState readiness) {
    if (_disposed || readiness != BackendReadinessState.ready) return;
    if (_cacheOnlyInFlight) {
      _refreshWhenCacheCompletes = true;
      return;
    }
    final shouldRefresh =
        state.status == HomeLoadStatus.offline ||
        state.status == HomeLoadStatus.unavailable ||
        state.status == HomeLoadStatus.failure ||
        (state.isFromCache && !state.isRefreshing);
    if (shouldRefresh) unawaited(_load());
  }

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
    final cacheFuture = _readCachedHome(shopSlug);
    if (cacheOnly) {
      _cacheOnlyInFlight = true;
      final cached = (await cacheFuture).snapshot;
      if (_isStale(generation, cancellation)) {
        _finishCacheOnlyLoad();
        return;
      }
      _publishCached(cached, isRefreshing: false);
      if (cached == null) state = const HomeState.offline();
      _finishCacheOnlyLoad();
      return;
    }
    final remoteFuture = _fetchRemoteHome(shopSlug, cancellation);
    final first = await Future.any<_HomeLoadCandidate>([
      cacheFuture,
      remoteFuture,
    ]);
    if (_isStale(generation, cancellation)) return;

    StorefrontCacheSnapshot<StorefrontHomeData>? cached;
    if (first case _HomeCacheCandidate(:final snapshot)) {
      cached = snapshot;
      _publishCached(cached, isRefreshing: true);
    }

    final remote = first is _HomeRemoteCandidate ? first : await remoteFuture;
    if (_isStale(generation, cancellation)) return;
    if (remote.data case final data?) {
      state = data.isEmpty ? const HomeState.empty() : HomeState.data(data);
      _queuePersistHome(shopSlug, data);
      return;
    }

    if (cached == null) {
      cached = (await cacheFuture).snapshot;
      if (_isStale(generation, cancellation)) return;
    }
    await _publishFailure(
      shopSlug: shopSlug,
      failure: remote.failure!,
      cached: cached,
      generation: generation,
      cancellation: cancellation,
    );
  }

  Future<_HomeCacheCandidate> _readCachedHome(String shopSlug) async {
    try {
      return _HomeCacheCandidate(
        await ref
            .read(storefrontCacheRepositoryProvider)
            .readHome(shopSlug: shopSlug),
      );
    } on Object {
      return const _HomeCacheCandidate(null);
    }
  }

  Future<_HomeRemoteCandidate> _fetchRemoteHome(
    String shopSlug,
    StorefrontRequestCancellation cancellation,
  ) async {
    try {
      return _HomeRemoteCandidate.data(
        await ref
            .read(storefrontRepositoryProvider)
            .fetchHome(shopSlug: shopSlug, cancellation: cancellation),
      );
    } on StorefrontFailure catch (failure) {
      return _HomeRemoteCandidate.failure(failure);
    } on Object {
      return _HomeRemoteCandidate.failure(
        const StorefrontFailure(
          StorefrontFailureKind.unknown,
          code: 'storefront_unknown',
        ),
      );
    }
  }

  void _publishCached(
    StorefrontCacheSnapshot<StorefrontHomeData>? cached, {
    required bool isRefreshing,
  }) {
    if (cached == null) return;
    final fresh = cached.isFreshAt(DateTime.now());
    state = cached.value.isEmpty
        ? HomeState.empty(
            isFromCache: true,
            isStale: !fresh,
            isRefreshing: isRefreshing,
            cachedAt: cached.refreshedAt,
          )
        : HomeState.data(
            cached.value,
            isFromCache: true,
            isStale: !fresh,
            isRefreshing: isRefreshing,
            cachedAt: cached.refreshedAt,
          );
  }

  Future<void> _publishFailure({
    required String shopSlug,
    required StorefrontFailure failure,
    required StorefrontCacheSnapshot<StorefrontHomeData>? cached,
    required int generation,
    required StorefrontRequestCancellation cancellation,
  }) async {
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

  void _queuePersistHome(String shopSlug, StorefrontHomeData data) {
    _cachePersistence = _cachePersistence.then(
      (_) => _persistHome(shopSlug, data),
    );
  }

  void _finishCacheOnlyLoad() {
    _cacheOnlyInFlight = false;
    if (!_refreshWhenCacheCompletes || _disposed) return;
    _refreshWhenCacheCompletes = false;
    unawaited(_load());
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
    _cacheOnlyInFlight = false;
    _refreshWhenCacheCompletes = false;
    _generation += 1;
    _cancellation?.cancel();
  }
}

sealed class _HomeLoadCandidate {
  const _HomeLoadCandidate();
}

final class _HomeCacheCandidate extends _HomeLoadCandidate {
  const _HomeCacheCandidate(this.snapshot);

  final StorefrontCacheSnapshot<StorefrontHomeData>? snapshot;
}

final class _HomeRemoteCandidate extends _HomeLoadCandidate {
  const _HomeRemoteCandidate._({this.data, this.failure});

  const _HomeRemoteCandidate.data(StorefrontHomeData data) : this._(data: data);

  const _HomeRemoteCandidate.failure(StorefrontFailure failure)
    : this._(failure: failure);

  final StorefrontHomeData? data;
  final StorefrontFailure? failure;
}
