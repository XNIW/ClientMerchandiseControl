import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../time/app_scheduler.dart';
import 'observability_event.dart';
import 'telemetry_redactor.dart';

enum TelemetryConsent { none, diagnostics, analytics }

abstract interface class AnalyticsExporter {
  Future<void> exportEvent(String serializedEvent);
}

abstract interface class CrashReporter {
  Future<void> reportCrash(String serializedCrash);
}

abstract interface class ObservabilityPort {
  SafeCorrelationId createCorrelationId();

  void record(ObservabilityEvent event);

  void recordError(
    Object error,
    StackTrace? stackTrace, {
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    SafeCorrelationId? correlationId,
  });

  Future<void> flush();
}

final class NoopObservabilityPort implements ObservabilityPort {
  const NoopObservabilityPort();

  @override
  SafeCorrelationId createCorrelationId() =>
      SafeCorrelationId.fromSafeValue('0000000000000000');

  @override
  void record(ObservabilityEvent event) {}

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    SafeCorrelationId? correlationId,
  }) {}

  @override
  Future<void> flush() => Future<void>.value();
}

final class StructuredLocalObservabilityPort implements ObservabilityPort {
  StructuredLocalObservabilityPort({
    required this.environment,
    AppClock? clock,
    void Function(String payload)? sink,
    this._serializer = const CrashSafeTelemetrySerializer(),
    int maximumBreadcrumbs = 20,
  }) : _clock = clock ?? _utcNow,
       _sink = sink ?? _developerSink,
       _breadcrumbs = _BoundedBreadcrumbs(maximumBreadcrumbs);

  final String environment;
  final AppClock _clock;
  final void Function(String payload) _sink;
  final CrashSafeTelemetrySerializer _serializer;
  final _BoundedBreadcrumbs _breadcrumbs;

  @override
  SafeCorrelationId createCorrelationId() => _newCorrelationId();

  @override
  void record(ObservabilityEvent event) {
    _breadcrumbs.add(event.name, event.occurredAt);
    _sink(_serializer.serialize(event.toSafeMap(environment: environment)));
  }

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    SafeCorrelationId? correlationId,
  }) {
    _sink(
      _serializer.serialize(
        _safeCrashPayload(
          error,
          stackTrace,
          environment: environment,
          occurredAt: _clock(),
          component: component,
          category: category,
          correlationId: correlationId,
          breadcrumbs: _breadcrumbs.values,
        ),
      ),
    );
  }

  @override
  Future<void> flush() => Future<void>.value();

  static void _developerSink(String payload) {
    developer.log(payload, name: 'cmc.observability');
  }
}

@immutable
final class ProductionObservabilityConfig {
  const ProductionObservabilityConfig({
    required this.environment,
    required this.consent,
    required this.analyticsEnabled,
    required this.crashReportingEnabled,
    this.samplePermille = 1000,
    this.maximumEventsPerMinute = 120,
    this.maximumBreadcrumbs = 20,
    this.maximumBufferedEvents = 100,
    this.maximumBufferedBytes = 64 * 1024,
  });

  final String environment;
  final TelemetryConsent consent;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final int samplePermille;
  final int maximumEventsPerMinute;
  final int maximumBreadcrumbs;
  final int maximumBufferedEvents;
  final int maximumBufferedBytes;

  void validate({
    required AnalyticsExporter? analyticsExporter,
    required CrashReporter? crashReporter,
  }) {
    if (!const {'staging', 'production'}.contains(environment) ||
        samplePermille < 0 ||
        samplePermille > 1000 ||
        maximumEventsPerMinute < 1 ||
        maximumBreadcrumbs < 1 ||
        maximumBufferedEvents < 1 ||
        maximumBufferedBytes < 256 ||
        (analyticsEnabled && analyticsExporter == null) ||
        (crashReportingEnabled && crashReporter == null)) {
      throw const FormatException('Invalid production observability config.');
    }
  }
}

final class ConfigurableProductionObservabilityPort
    implements ObservabilityPort {
  ConfigurableProductionObservabilityPort({
    required ProductionObservabilityConfig config,
    AnalyticsExporter? analyticsExporter,
    CrashReporter? crashReporter,
    AppClock? clock,
    this._serializer = const CrashSafeTelemetrySerializer(),
  }) : _config = config,
       _analyticsExporter = analyticsExporter,
       _crashReporter = crashReporter,
       _clock = clock ?? _utcNow,
       _rateLimiter = _FixedWindowRateLimiter(
         maximum: config.maximumEventsPerMinute,
         clock: clock ?? _utcNow,
       ),
       _breadcrumbs = _BoundedBreadcrumbs(config.maximumBreadcrumbs),
       _eventBuffer = _BoundedPayloadBuffer(
         maximumCount: config.maximumBufferedEvents,
         maximumBytes: config.maximumBufferedBytes,
       ),
       _crashBuffer = _BoundedPayloadBuffer(
         maximumCount: config.maximumBufferedEvents,
         maximumBytes: config.maximumBufferedBytes,
       ) {
    config.validate(
      analyticsExporter: analyticsExporter,
      crashReporter: crashReporter,
    );
  }

  final ProductionObservabilityConfig _config;
  final AnalyticsExporter? _analyticsExporter;
  final CrashReporter? _crashReporter;
  final AppClock _clock;
  final CrashSafeTelemetrySerializer _serializer;
  final _FixedWindowRateLimiter _rateLimiter;
  final _BoundedBreadcrumbs _breadcrumbs;
  final _BoundedPayloadBuffer _eventBuffer;
  final _BoundedPayloadBuffer _crashBuffer;
  Future<void> _tail = Future<void>.value();
  var _sampleCursor = 0;

  @visibleForTesting
  int get bufferedEventCount => _eventBuffer.length;

  @visibleForTesting
  int get bufferedCrashCount => _crashBuffer.length;

  @override
  SafeCorrelationId createCorrelationId() => _newCorrelationId();

  @override
  void record(ObservabilityEvent event) {
    _breadcrumbs.add(event.name, event.occurredAt);
    if (!_config.analyticsEnabled || !_allows(event.channel)) return;
    if (!_sampled() || !_rateLimiter.take()) return;
    final payload = _serializer.serialize(
      event.toSafeMap(environment: _config.environment),
    );
    _enqueue(() => _sendEvent(payload));
  }

  @override
  void recordError(
    Object error,
    StackTrace? stackTrace, {
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    SafeCorrelationId? correlationId,
  }) {
    if (!_config.crashReportingEnabled ||
        _config.consent == TelemetryConsent.none ||
        !_rateLimiter.take()) {
      return;
    }
    final payload = _serializer.serialize(
      _safeCrashPayload(
        error,
        stackTrace,
        environment: _config.environment,
        occurredAt: _clock(),
        component: component,
        category: category,
        correlationId: correlationId,
        breadcrumbs: _breadcrumbs.values,
      ),
    );
    _enqueue(() => _sendCrash(payload));
  }

  @override
  Future<void> flush() async {
    await _tail;
    if (_analyticsExporter != null) {
      final pending = _eventBuffer.takeAll();
      for (var index = 0; index < pending.length; index++) {
        try {
          await _analyticsExporter.exportEvent(pending[index]);
        } on Object {
          for (final payload in pending.skip(index)) {
            _eventBuffer.add(payload);
          }
          break;
        }
      }
    }
    if (_crashReporter != null) {
      final pending = _crashBuffer.takeAll();
      for (var index = 0; index < pending.length; index++) {
        try {
          await _crashReporter.reportCrash(pending[index]);
        } on Object {
          for (final payload in pending.skip(index)) {
            _crashBuffer.add(payload);
          }
          break;
        }
      }
    }
  }

  bool _allows(ObservabilityChannel channel) => switch (_config.consent) {
    TelemetryConsent.none => false,
    TelemetryConsent.diagnostics =>
      channel == ObservabilityChannel.diagnostics ||
          channel == ObservabilityChannel.performance,
    TelemetryConsent.analytics => true,
  };

  bool _sampled() {
    if (_config.samplePermille == 1000) return true;
    if (_config.samplePermille == 0) return false;
    final sampled = _sampleCursor % 1000 < _config.samplePermille;
    _sampleCursor++;
    return sampled;
  }

  void _enqueue(Future<void> Function() action) {
    _tail = _tail.then((_) => action()).catchError((Object _) {});
  }

  Future<void> _sendEvent(String payload) async {
    try {
      await _analyticsExporter!.exportEvent(payload);
    } on Object {
      _eventBuffer.add(payload);
    }
  }

  Future<void> _sendCrash(String payload) async {
    try {
      await _crashReporter!.reportCrash(payload);
    } on Object {
      _crashBuffer.add(payload);
    }
  }
}

Map<String, Object> _safeCrashPayload(
  Object error,
  StackTrace? stackTrace, {
  required String environment,
  required DateTime occurredAt,
  required ObservabilityComponent component,
  required BackendFailureCategory category,
  required SafeCorrelationId? correlationId,
  required List<Map<String, Object>> breadcrumbs,
}) {
  final fingerprintSource = '${error.runtimeType}|${stackTrace ?? ''}';
  final fingerprint = sha256.convert(utf8.encode(fingerprintSource)).toString();
  return {
    'schema': 1,
    'name': 'crash',
    'environment': environment,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'component': component.name,
    'category': category.name,
    'fingerprint': fingerprint.substring(0, 24),
    if (correlationId != null) 'correlationId': correlationId.value,
    'breadcrumbs': breadcrumbs,
  };
}

SafeCorrelationId _newCorrelationId() {
  final random = Random.secure();
  final buffer = StringBuffer();
  for (var index = 0; index < 12; index++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return SafeCorrelationId.fromSafeValue(buffer.toString());
}

DateTime _utcNow() => DateTime.now().toUtc();

final class _FixedWindowRateLimiter {
  _FixedWindowRateLimiter({required this.maximum, required this.clock});

  final int maximum;
  final AppClock clock;
  DateTime? _windowStart;
  var _count = 0;

  bool take() {
    final now = clock().toUtc();
    final start = _windowStart;
    if (start == null || now.difference(start) >= const Duration(minutes: 1)) {
      _windowStart = now;
      _count = 0;
    }
    if (_count >= maximum) return false;
    _count++;
    return true;
  }
}

final class _BoundedBreadcrumbs {
  _BoundedBreadcrumbs(this.maximum);

  final int maximum;
  final List<Map<String, Object>> _values = [];

  List<Map<String, Object>> get values => List.unmodifiable(_values);

  void add(ObservabilityEventName name, DateTime occurredAt) {
    _values.add({
      'name': name.name,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
    });
    if (_values.length > maximum) _values.removeAt(0);
  }
}

final class _BoundedPayloadBuffer {
  _BoundedPayloadBuffer({
    required this.maximumCount,
    required this.maximumBytes,
  });

  final int maximumCount;
  final int maximumBytes;
  final List<String> _values = [];
  var _bytes = 0;

  int get length => _values.length;

  void add(String payload) {
    final size = utf8.encode(payload).length;
    if (size > maximumBytes) return;
    while (_values.isNotEmpty &&
        (_values.length >= maximumCount || _bytes + size > maximumBytes)) {
      _bytes -= utf8.encode(_values.removeAt(0)).length;
    }
    _values.add(payload);
    _bytes += size;
  }

  List<String> takeAll() {
    final values = List<String>.of(_values);
    _values.clear();
    _bytes = 0;
    return values;
  }
}
