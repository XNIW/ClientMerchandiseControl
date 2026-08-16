import 'dart:ui';

import 'package:client_merchandise_control/core/observability/observability_event.dart';
import 'package:client_merchandise_control/core/observability/observability_port.dart';
import 'package:client_merchandise_control/core/observability/observability_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crash boundary preserva previous handler e fallback embedder', () {
    final dispatcher = PlatformDispatcher.instance;
    final originalPlatformError = dispatcher.onError;
    final originalFlutterError = FlutterError.onError;
    addTearDown(() {
      dispatcher.onError = originalPlatformError;
      FlutterError.onError = originalFlutterError;
    });

    dispatcher.onError = null;
    var uninstall = ObservabilityCrashBoundary.install(
      _CollectingPort(throwOnError: true),
    );
    expect(
      dispatcher.onError!(StateError('root'), StackTrace.current),
      isFalse,
    );
    uninstall();

    for (final expected in [false, true]) {
      dispatcher.onError = (_, _) => expected;
      uninstall = ObservabilityCrashBoundary.install(
        _CollectingPort(throwOnError: true),
      );
      expect(
        dispatcher.onError!(StateError('root'), StackTrace.current),
        expected,
      );
      uninstall();
    }
  });

  test('helper best-effort isola port throwing e Ref già disposed', () {
    final event = ObservabilityEvent.appStart(
      occurredAt: DateTime.utc(2026, 8, 16, 12),
      kind: AppStartKind.cold,
    );
    final throwing = _ThrowingPort();
    expect(
      () => recordObservabilityBestEffort(throwing, event),
      returnsNormally,
    );

    late Ref capturedRef;
    final captureProvider = Provider<void>((ref) {
      capturedRef = ref;
    });
    final container = ProviderContainer(
      overrides: [observabilityProvider.overrideWithValue(throwing)],
    );
    container.read(captureProvider);
    container.dispose();

    expect(
      () => recordObservabilityFromRefBestEffort(capturedRef, () => event),
      returnsNormally,
    );
  });

  testWidgets('resume dopo background emette un solo warm start bounded', (
    tester,
  ) async {
    final port = _CollectingPort();
    final instant = DateTime.utc(2026, 8, 16, 12);
    await tester.pumpWidget(
      ObservabilityLifecycle(
        observability: port,
        clock: () => instant,
        child: const SizedBox(),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(port.events, hasLength(1));
    expect(port.events.single.name, ObservabilityEventName.appStart);
    expect(port.events.single.attributes, {'kind': 'warm'});
  });
}

final class _CollectingPort implements ObservabilityPort {
  _CollectingPort({this.throwOnError = false});

  final bool throwOnError;
  final events = <ObservabilityEvent>[];

  @override
  SafeCorrelationId createCorrelationId() =>
      SafeCorrelationId.forTesting('0123456789abcdef');

  @override
  void record(ObservabilityEvent event) => events.add(event);

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    SafeCorrelationId? correlationId,
  }) {
    if (throwOnError) throw StateError('telemetry unavailable');
  }

  @override
  Future<void> flush() async {}
}

final class _ThrowingPort implements ObservabilityPort {
  @override
  SafeCorrelationId createCorrelationId() => throw StateError('telemetry');

  @override
  Future<void> flush() => throw StateError('telemetry');

  @override
  void record(ObservabilityEvent event) => throw StateError('telemetry');

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    SafeCorrelationId? correlationId,
  }) => throw StateError('telemetry');
}
