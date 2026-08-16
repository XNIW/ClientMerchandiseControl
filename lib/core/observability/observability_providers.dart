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
      observability.recordError(
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
      observability.recordError(
        error,
        stackTrace,
        component: ObservabilityComponent.bootstrap,
        category: BackendFailureCategory.unexpected,
      );
      return previousPlatformError?.call(error, stackTrace) ?? true;
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
      widget.observability.record(
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
