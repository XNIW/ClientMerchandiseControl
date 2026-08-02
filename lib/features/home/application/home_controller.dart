import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/backend_readiness_controller.dart';
import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/config/app_config.dart';
import '../../storefront/application/storefront_providers.dart';
import '../../storefront/domain/storefront_failure.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../storefront/domain/storefront_repository.dart';

enum HomeLoadStatus { loading, data, empty, offline, unavailable, failure }

class HomeState {
  const HomeState._(this.status, {this.data, this.failure});

  const HomeState.loading() : this._(HomeLoadStatus.loading);
  const HomeState.empty() : this._(HomeLoadStatus.empty);
  const HomeState.offline() : this._(HomeLoadStatus.offline);
  const HomeState.unavailable() : this._(HomeLoadStatus.unavailable);
  const HomeState.failure(StorefrontFailure failure)
    : this._(HomeLoadStatus.failure, failure: failure);
  const HomeState.data(StorefrontHomeData data)
    : this._(HomeLoadStatus.data, data: data);

  final HomeLoadStatus status;
  final StorefrontHomeData? data;
  final StorefrontFailure? failure;
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
    };
  }

  void _handleReadinessChange(BackendReadinessState readiness) {
    if (_disposed) return;
    if (readiness == BackendReadinessState.ready) {
      unawaited(_load());
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

  Future<void> _load() async {
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
    try {
      final data = await ref
          .read(storefrontRepositoryProvider)
          .fetchHome(shopSlug: shopSlug, cancellation: cancellation);
      if (_isStale(generation, cancellation)) return;
      state = data.isEmpty ? const HomeState.empty() : HomeState.data(data);
    } on StorefrontFailure catch (failure) {
      if (_isStale(generation, cancellation)) return;
      state = switch (failure.kind) {
        StorefrontFailureKind.cancelled => state,
        StorefrontFailureKind.offline ||
        StorefrontFailureKind.timeout => const HomeState.offline(),
        StorefrontFailureKind.invalidConfiguration ||
        StorefrontFailureKind.unauthorized ||
        StorefrontFailureKind.unavailable => const HomeState.unavailable(),
        StorefrontFailureKind.invalidPayload ||
        StorefrontFailureKind.unknown => HomeState.failure(failure),
      };
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
