import 'package:client_merchandise_control/core/observability/observability_event.dart';
import 'package:client_merchandise_control/core/observability/observability_port.dart';
import 'package:client_merchandise_control/core/observability/observability_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
  }) {}

  @override
  Future<void> flush() async {}
}
