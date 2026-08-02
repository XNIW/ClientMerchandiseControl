import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'backend_health_service.dart';
import 'backend_readiness_repository.dart';
import 'backend_readiness_state.dart';

final backendHealthServiceProvider = Provider<BackendHealthService>((ref) {
  final service = HttpBackendHealthService();
  ref.onDispose(service.close);
  return service;
});

final backendReadinessRepositoryProvider = Provider<BackendReadinessRepository>(
  (ref) {
    return SupabaseBackendReadinessRepository(
      config: ref.watch(appConfigProvider),
      healthService: ref.watch(backendHealthServiceProvider),
    );
  },
);

final backendReadinessControllerProvider =
    NotifierProvider<BackendReadinessController, BackendReadinessState>(
      BackendReadinessController.new,
    );

class BackendReadinessController extends Notifier<BackendReadinessState> {
  BackendReadinessRepository? _repository;
  BackendProbeCancellation? _activeCancellation;
  Future<void>? _activeCheck;
  var _generation = 0;
  var _disposed = false;

  @override
  BackendReadinessState build() {
    final repository = ref.watch(backendReadinessRepositoryProvider);
    _repository = repository;
    ref.onDispose(_dispose);

    final initialState = repository.initialState;
    if (initialState == BackendReadinessState.initializing) {
      scheduleMicrotask(() {
        if (!_disposed) {
          unawaited(retry());
        }
      });
    }
    return initialState;
  }

  Future<void> retry() {
    final activeCheck = _activeCheck;
    if (activeCheck != null) {
      return activeCheck;
    }

    final repository = _repository;
    if (_disposed || repository == null || !repository.canCheck) {
      return Future<void>.value();
    }

    final cancellation = BackendProbeCancellation();
    final generation = ++_generation;
    _activeCancellation = cancellation;
    state = BackendReadinessState.initializing;

    late final Future<void> operation;
    operation =
        _runCheck(
          repository: repository,
          cancellation: cancellation,
          generation: generation,
        ).whenComplete(() {
          if (identical(_activeCheck, operation)) {
            _activeCheck = null;
            _activeCancellation = null;
          }
        });
    _activeCheck = operation;
    return operation;
  }

  void cancelCurrentCheck() {
    _generation += 1;
    _activeCancellation?.cancel();
  }

  Future<void> _runCheck({
    required BackendReadinessRepository repository,
    required BackendProbeCancellation cancellation,
    required int generation,
  }) async {
    final nextState = await repository.check(cancellation: cancellation);
    if (_disposed || cancellation.isCancelled || generation != _generation) {
      return;
    }
    state = nextState;
  }

  void _dispose() {
    _disposed = true;
    cancelCurrentCheck();
  }
}
