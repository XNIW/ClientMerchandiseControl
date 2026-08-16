import 'package:flutter/foundation.dart';

enum ObservabilityEventName {
  appStart,
  screenView,
  catalogQueryResult,
  addToCartOutcome,
  checkoutStep,
  orderCreated,
  orderStatus,
  notificationRouting,
  trackingAvailability,
  trackingSignal,
  backendFailure,
  performanceBudgetViolation,
}

enum ObservabilityChannel { diagnostics, analytics, performance }

enum ObservabilityOutcome { success, failure, cancelled, ignored, pending }

enum BackendFailureCategory {
  offline,
  timeout,
  unauthorized,
  invalidInput,
  conflict,
  unavailable,
  invalidPayload,
  rateLimited,
  unexpected,
}

enum ObservabilityComponent {
  bootstrap,
  auth,
  catalog,
  cart,
  checkout,
  orders,
  notifications,
  tracking,
  backend,
}

enum AppStartKind { cold, warm }

enum AppScreen {
  home,
  catalog,
  productDetail,
  orders,
  orderDetail,
  cart,
  checkout,
  favorites,
  account,
  unknown,
}

enum CatalogQueryKind { browse, search, filter, pageAppend, refresh }

enum CacheDisposition { none, fresh, stale, offline }

enum ResultCountBucket { zero, oneToTen, elevenToFifty, overFifty }

enum QuantityBucket { one, twoToFive, sixToTen, overTen }

enum CheckoutTelemetryStep { mode, destination, slot, review, payment, order }

enum OrderStatusGroup { open, processing, fulfilled, cancelled, unknown }

enum OrderStatusSource { initialLoad, refresh, realtime, push, recovery }

enum NotificationDestination { order, cart, unsupported }

enum TrackingModeTelemetry {
  statusOnly,
  externalCarrier,
  liveCourier,
  unavailable,
}

enum TrackingAvailabilityTelemetry { available, stale, disabled, failed }

enum TrackingSignalTelemetry {
  disconnected,
  reconnecting,
  reconnected,
  duplicate,
  outOfOrder,
}

enum PerformanceOperation {
  coldLaunch,
  warmLaunch,
  storefrontContent,
  catalogSearch,
  catalogFilter,
  catalogPageAppend,
  productDetail,
  cartOpen,
  checkoutNavigation,
  orderList,
  orderDetail,
  trackingUpdate,
  imageDecode,
}

enum DurationBucket { under100ms, under500ms, under1s, under3s, over3s }

@immutable
final class SafeCorrelationId {
  const SafeCorrelationId._(this.value);

  factory SafeCorrelationId.fromSafeValue(String value) {
    if (!RegExp(r'^[a-f0-9]{16,32}$').hasMatch(value)) {
      throw ArgumentError.value(value, 'value', 'Unsafe correlation id.');
    }
    return SafeCorrelationId._(value);
  }

  @visibleForTesting
  factory SafeCorrelationId.forTesting(String value) =
      SafeCorrelationId.fromSafeValue;

  final String value;
}

@immutable
final class ObservabilityEvent {
  ObservabilityEvent._({
    required this.name,
    required this.channel,
    required this.occurredAt,
    required Map<String, Object> attributes,
    this.correlationId,
  }) : attributes = Map.unmodifiable(attributes);

  factory ObservabilityEvent.appStart({
    required DateTime occurredAt,
    required AppStartKind kind,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.appStart,
    channel: ObservabilityChannel.diagnostics,
    occurredAt: occurredAt,
    attributes: {'kind': kind.name},
  );

  factory ObservabilityEvent.screenView({
    required DateTime occurredAt,
    required AppScreen screen,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.screenView,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    attributes: {'screen': screen.name},
  );

  factory ObservabilityEvent.catalogQueryResult({
    required DateTime occurredAt,
    required CatalogQueryKind kind,
    required ObservabilityOutcome outcome,
    required ResultCountBucket resultCount,
    required CacheDisposition cache,
    required DurationBucket duration,
    BackendFailureCategory? failure,
    SafeCorrelationId? correlationId,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.catalogQueryResult,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    correlationId: correlationId,
    attributes: {
      'kind': kind.name,
      'outcome': outcome.name,
      'resultCount': resultCount.name,
      'cache': cache.name,
      'duration': duration.name,
      if (failure != null) 'failure': failure.name,
    },
  );

  factory ObservabilityEvent.addToCartOutcome({
    required DateTime occurredAt,
    required ObservabilityOutcome outcome,
    required QuantityBucket quantity,
    BackendFailureCategory? failure,
    SafeCorrelationId? correlationId,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.addToCartOutcome,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    correlationId: correlationId,
    attributes: {
      'outcome': outcome.name,
      'quantity': quantity.name,
      if (failure != null) 'failure': failure.name,
    },
  );

  factory ObservabilityEvent.checkoutStep({
    required DateTime occurredAt,
    required CheckoutTelemetryStep step,
    required ObservabilityOutcome outcome,
    BackendFailureCategory? failure,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.checkoutStep,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    attributes: {
      'step': step.name,
      'outcome': outcome.name,
      if (failure != null) 'failure': failure.name,
    },
  );

  factory ObservabilityEvent.orderCreated({
    required DateTime occurredAt,
    required ObservabilityOutcome outcome,
    BackendFailureCategory? failure,
    SafeCorrelationId? correlationId,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.orderCreated,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    correlationId: correlationId,
    attributes: {
      'outcome': outcome.name,
      if (failure != null) 'failure': failure.name,
    },
  );

  factory ObservabilityEvent.orderStatus({
    required DateTime occurredAt,
    required OrderStatusGroup status,
    required OrderStatusSource source,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.orderStatus,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    attributes: {'status': status.name, 'source': source.name},
  );

  factory ObservabilityEvent.notificationRouting({
    required DateTime occurredAt,
    required NotificationDestination destination,
    required ObservabilityOutcome outcome,
    BackendFailureCategory? failure,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.notificationRouting,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    attributes: {
      'destination': destination.name,
      'outcome': outcome.name,
      if (failure != null) 'failure': failure.name,
    },
  );

  factory ObservabilityEvent.trackingAvailability({
    required DateTime occurredAt,
    required TrackingModeTelemetry mode,
    required TrackingAvailabilityTelemetry availability,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.trackingAvailability,
    channel: ObservabilityChannel.analytics,
    occurredAt: occurredAt,
    attributes: {'mode': mode.name, 'availability': availability.name},
  );

  factory ObservabilityEvent.trackingSignal({
    required DateTime occurredAt,
    required TrackingSignalTelemetry signal,
    required ObservabilityOutcome outcome,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.trackingSignal,
    channel: ObservabilityChannel.diagnostics,
    occurredAt: occurredAt,
    attributes: {'signal': signal.name, 'outcome': outcome.name},
  );

  factory ObservabilityEvent.backendFailure({
    required DateTime occurredAt,
    required ObservabilityComponent component,
    required BackendFailureCategory category,
    required bool retryable,
    SafeCorrelationId? correlationId,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.backendFailure,
    channel: ObservabilityChannel.diagnostics,
    occurredAt: occurredAt,
    correlationId: correlationId,
    attributes: {
      'component': component.name,
      'category': category.name,
      'retryable': retryable,
    },
  );

  factory ObservabilityEvent.performanceBudgetViolation({
    required DateTime occurredAt,
    required PerformanceOperation operation,
    required DurationBucket budget,
    required DurationBucket observed,
  }) => ObservabilityEvent._(
    name: ObservabilityEventName.performanceBudgetViolation,
    channel: ObservabilityChannel.performance,
    occurredAt: occurredAt,
    attributes: {
      'operation': operation.name,
      'budget': budget.name,
      'observed': observed.name,
    },
  );

  final ObservabilityEventName name;
  final ObservabilityChannel channel;
  final DateTime occurredAt;
  final Map<String, Object> attributes;
  final SafeCorrelationId? correlationId;

  Map<String, Object> toSafeMap({required String environment}) => {
    'schema': 1,
    'name': name.name,
    'channel': channel.name,
    'environment': environment,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    if (correlationId != null) 'correlationId': correlationId!.value,
    'attributes': attributes,
  };
}

ResultCountBucket resultCountBucket(int count) {
  if (count <= 0) return ResultCountBucket.zero;
  if (count <= 10) return ResultCountBucket.oneToTen;
  if (count <= 50) return ResultCountBucket.elevenToFifty;
  return ResultCountBucket.overFifty;
}

QuantityBucket quantityBucket(int quantity) {
  if (quantity <= 1) return QuantityBucket.one;
  if (quantity <= 5) return QuantityBucket.twoToFive;
  if (quantity <= 10) return QuantityBucket.sixToTen;
  return QuantityBucket.overTen;
}

DurationBucket durationBucket(Duration duration) {
  if (duration < const Duration(milliseconds: 100)) {
    return DurationBucket.under100ms;
  }
  if (duration < const Duration(milliseconds: 500)) {
    return DurationBucket.under500ms;
  }
  if (duration < const Duration(seconds: 1)) return DurationBucket.under1s;
  if (duration < const Duration(seconds: 3)) return DurationBucket.under3s;
  return DurationBucket.over3s;
}
