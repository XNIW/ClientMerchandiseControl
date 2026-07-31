import 'dart:async';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_controller.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'staging avvia exactly-one check automatico senza retry manuale',
    () async {
      final repository = _FakeReadinessRepository();
      final container = ProviderContainer(
        overrides: [
          backendReadinessRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(backendReadinessControllerProvider),
        BackendReadinessState.initializing,
      );

      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, 1);

      repository.completeNext(BackendReadinessState.recoverableError);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(backendReadinessControllerProvider),
        BackendReadinessState.recoverableError,
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, 1);
    },
  );

  test('retry concorrenti condividono la stessa operazione', () async {
    final repository = _FakeReadinessRepository();
    final container = ProviderContainer(
      overrides: [
        backendReadinessRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(backendReadinessControllerProvider);

    final controller = container.read(
      backendReadinessControllerProvider.notifier,
    );
    final first = controller.retry();
    final second = controller.retry();

    expect(identical(first, second), isTrue);
    expect(repository.calls, 1);

    repository.completeNext(BackendReadinessState.offline);
    await first;
    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.offline,
    );
  });

  test('retry manuale riparte soltanto dopo il check concluso', () async {
    final repository = _FakeReadinessRepository();
    final container = ProviderContainer(
      overrides: [
        backendReadinessRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(backendReadinessControllerProvider);

    final controller = container.read(
      backendReadinessControllerProvider.notifier,
    );
    final first = controller.retry();
    repository.completeNext(BackendReadinessState.recoverableError);
    await first;

    expect(repository.calls, 1);
    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.recoverableError,
    );

    final second = controller.retry();
    expect(repository.calls, 2);
    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.initializing,
    );

    repository.completeNext(BackendReadinessState.ready);
    await second;
    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.ready,
    );
  });

  test('dispose cancella il probe e ignora un completamento tardivo', () async {
    final repository = _FakeReadinessRepository();
    final container = ProviderContainer(
      overrides: [
        backendReadinessRepositoryProvider.overrideWithValue(repository),
      ],
    );
    container.read(backendReadinessControllerProvider);
    final operation = container
        .read(backendReadinessControllerProvider.notifier)
        .retry();

    expect(repository.cancellations.single.isCancelled, isFalse);
    container.dispose();
    expect(repository.cancellations.single.isCancelled, isTrue);

    repository.completeNext(BackendReadinessState.ready);
    await operation;
  });

  test('cancelCurrentCheck non pubblica il risultato obsoleto', () async {
    final repository = _FakeReadinessRepository();
    final container = ProviderContainer(
      overrides: [
        backendReadinessRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.read(backendReadinessControllerProvider);
    final controller = container.read(
      backendReadinessControllerProvider.notifier,
    );
    final operation = controller.retry();

    controller.cancelCurrentCheck();
    repository.completeNext(BackendReadinessState.ready);
    await operation;

    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.initializing,
    );
  });

  test('unconfigured non avvia check e retry resta no-op', () async {
    final repository = _FakeReadinessRepository(
      initialState: BackendReadinessState.unconfigured,
      canCheck: false,
    );
    final container = ProviderContainer(
      overrides: [
        backendReadinessRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(backendReadinessControllerProvider),
      BackendReadinessState.unconfigured,
    );
    await container.read(backendReadinessControllerProvider.notifier).retry();
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls, 0);
  });
}

final class _FakeReadinessRepository implements BackendReadinessRepository {
  _FakeReadinessRepository({
    this.initialState = BackendReadinessState.initializing,
    this.canCheck = true,
  });

  @override
  final BackendReadinessState initialState;

  @override
  final bool canCheck;

  final List<Completer<BackendReadinessState>> _results = [];
  final List<BackendProbeCancellation> cancellations = [];

  int get calls => _results.length;

  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) {
    final result = Completer<BackendReadinessState>();
    _results.add(result);
    cancellations.add(cancellation);
    return result.future;
  }

  void completeNext(BackendReadinessState state) {
    _results.firstWhere((result) => !result.isCompleted).complete(state);
  }
}
