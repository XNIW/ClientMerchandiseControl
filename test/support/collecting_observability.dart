import 'package:client_merchandise_control/core/observability/observability_event.dart';
import 'package:client_merchandise_control/core/observability/observability_port.dart';

final class CollectingObservabilityPort implements ObservabilityPort {
  final events = <ObservabilityEvent>[];
  final errors = <BackendFailureCategory>[];

  @override
  SafeCorrelationId createCorrelationId() =>
      SafeCorrelationId.fromSafeValue('0123456789abcdef');

  @override
  Future<void> flush() async {}

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
    errors.add(category);
  }
}

final class ThrowingObservabilityPort implements ObservabilityPort {
  ThrowingObservabilityPort({this.onlyFor});

  final ObservabilityEventName? onlyFor;

  @override
  SafeCorrelationId createCorrelationId() =>
      SafeCorrelationId.fromSafeValue('0123456789abcdef');

  @override
  Future<void> flush() async => throw StateError('telemetry unavailable');

  @override
  void record(ObservabilityEvent event) {
    if (onlyFor == null || event.name == onlyFor) {
      throw StateError('telemetry unavailable');
    }
  }

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    SafeCorrelationId? correlationId,
  }) => throw StateError('telemetry unavailable');
}
