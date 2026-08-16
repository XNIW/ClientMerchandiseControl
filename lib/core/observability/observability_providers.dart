import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_environment.dart';
import '../time/app_scheduler.dart';
import 'observability_event.dart';
import 'observability_port.dart';

final observabilityProvider = Provider<ObservabilityPort>((ref) {
  return const NoopObservabilityPort();
});

void recordObservabilityBestEffort(
  ObservabilityPort observability,
  ObservabilityEvent event,
) {
  try {
    observability.record(event);
  } on Object {
    // Observability must never alter the domain outcome it describes.
  }
}

void recordObservabilityFromRefBestEffort(
  Ref ref,
  ObservabilityEvent Function() event,
) {
  try {
    recordObservabilityBestEffort(ref.read(observabilityProvider), event());
  } on Object {
    // A provider may already be disposed when an in-flight operation completes.
  }
}

void withObservabilityFromRefBestEffort(
  Ref ref,
  void Function(ObservabilityPort observability) emit,
) {
  try {
    emit(ref.read(observabilityProvider));
  } on Object {
    // Observability is isolated from lifecycle and domain failures.
  }
}

void recordObservabilityErrorBestEffort(
  ObservabilityPort observability,
  Object error,
  StackTrace? stackTrace, {
  required ObservabilityComponent component,
  required BackendFailureCategory category,
}) {
  try {
    observability.recordError(
      error,
      stackTrace,
      component: component,
      category: category,
    );
  } on Object {
    // Preserve the platform/domain error path if telemetry itself fails.
  }
}

ObservabilityPort defaultObservability({
  required AppEnvironment environment,
  required AppClock clock,
}) => switch (environment) {
  AppEnvironment.development => StructuredLocalObservabilityPort(
    environment: environment.name,
    clock: clock,
  ),
  AppEnvironment.staging ||
  AppEnvironment.production => const NoopObservabilityPort(),
};

final class ObservabilityCrashBoundary {
  ObservabilityCrashBoundary._();

  static VoidCallback install(ObservabilityPort observability) {
    final previousFlutterError = FlutterError.onError;
    final previousPlatformError = PlatformDispatcher.instance.onError;

    FlutterError.onError = (details) {
      recordObservabilityErrorBestEffort(
        observability,
        details.exception,
        details.stack,
        component: ObservabilityComponent.bootstrap,
        category: BackendFailureCategory.unexpected,
      );
      if (previousFlutterError != null) {
        previousFlutterError(details);
      } else {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      recordObservabilityErrorBestEffort(
        observability,
        error,
        stackTrace,
        component: ObservabilityComponent.bootstrap,
        category: BackendFailureCategory.unexpected,
      );
      return previousPlatformError?.call(error, stackTrace) ?? false;
    };

    return () {
      FlutterError.onError = previousFlutterError;
      PlatformDispatcher.instance.onError = previousPlatformError;
    };
  }
}

final class ObservabilityLifecycle extends StatefulWidget {
  const ObservabilityLifecycle({
    required this.observability,
    required this.clock,
    required this.child,
    super.key,
  });

  final ObservabilityPort observability;
  final AppClock clock;
  final Widget child;

  @override
  State<ObservabilityLifecycle> createState() => _ObservabilityLifecycleState();
}

final class _ObservabilityLifecycleState extends State<ObservabilityLifecycle>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _lastState != null &&
        _lastState != AppLifecycleState.resumed) {
      recordObservabilityBestEffort(
        widget.observability,
        ObservabilityEvent.appStart(
          occurredAt: widget.clock(),
          kind: AppStartKind.warm,
        ),
      );
    }
    _lastState = state;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
