import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer_notification_failure.dart';
import '../domain/customer_notification_models.dart';
import 'customer_notification_providers.dart';

enum CustomerNotificationRouteStatus { signedOut, idle, resolving, failure }

final class CustomerNotificationRouteState {
  const CustomerNotificationRouteState({
    required this.status,
    this.lastDestination,
    this.failure,
    this.revision = 0,
  });

  const CustomerNotificationRouteState.signedOut()
    : this(status: CustomerNotificationRouteStatus.signedOut);

  const CustomerNotificationRouteState.idle()
    : this(status: CustomerNotificationRouteStatus.idle);

  final CustomerNotificationRouteStatus status;
  final CustomerNotificationDestination? lastDestination;
  final CustomerNotificationFailureKind? failure;
  final int revision;
}

final customerNotificationRouteControllerProvider =
    NotifierProvider<
      CustomerNotificationRouteController,
      CustomerNotificationRouteState
    >(CustomerNotificationRouteController.new);

final class CustomerNotificationRouteController
    extends Notifier<CustomerNotificationRouteState> {
  static const _maximumCachedRoutes = 32;

  final LinkedHashMap<String, CustomerNotificationDestination> _cache =
      LinkedHashMap();
  Future<CustomerNotificationDestination?>? _active;
  String? _activeKey;
  String? _subjectId;
  var _generation = 0;
  var _disposed = false;

  @override
  CustomerNotificationRouteState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
      _active = null;
      _activeKey = null;
      _cache.clear();
    });
    final subjectId = ref
        .watch(customerNotificationIdentityProvider)
        ?.subjectId;
    if (_subjectId != subjectId) {
      _subjectId = subjectId;
      _generation++;
      _active = null;
      _activeKey = null;
      _cache.clear();
    }
    return subjectId == null
        ? const CustomerNotificationRouteState.signedOut()
        : const CustomerNotificationRouteState.idle();
  }

  Future<CustomerNotificationDestination?> resolve({
    required String shopSlug,
    required String routeToken,
  }) {
    final subjectId = _subjectId;
    if (_disposed || subjectId == null) {
      return Future.value();
    }
    final key = '$shopSlug:$routeToken';
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      state = CustomerNotificationRouteState(
        status: CustomerNotificationRouteStatus.idle,
        lastDestination: cached,
        revision: state.revision + 1,
      );
      return Future.value(cached);
    }
    if (_activeKey == key && _active != null) return _active!;
    final generation = ++_generation;
    state = CustomerNotificationRouteState(
      status: CustomerNotificationRouteStatus.resolving,
      revision: state.revision + 1,
    );
    late final Future<CustomerNotificationDestination?> operation;
    operation =
        _resolve(
          subjectId: subjectId,
          key: key,
          shopSlug: shopSlug,
          routeToken: routeToken,
          generation: generation,
        ).whenComplete(() {
          if (identical(_active, operation)) {
            _active = null;
            _activeKey = null;
          }
        });
    _activeKey = key;
    _active = operation;
    return operation;
  }

  Future<CustomerNotificationDestination?> _resolve({
    required String subjectId,
    required String key,
    required String shopSlug,
    required String routeToken,
    required int generation,
  }) async {
    try {
      final destination = await ref
          .read(customerNotificationRepositoryProvider)
          .resolveRoute(shopSlug: shopSlug, routeToken: routeToken);
      if (!_isCurrent(subjectId)) return null;
      _cache[key] = destination;
      while (_cache.length > _maximumCachedRoutes) {
        _cache.remove(_cache.keys.first);
      }
      if (generation == _generation) {
        state = CustomerNotificationRouteState(
          status: CustomerNotificationRouteStatus.idle,
          lastDestination: destination,
          revision: state.revision + 1,
        );
      }
      return destination;
    } on CustomerNotificationRepositoryException catch (error) {
      if (_isCurrent(subjectId) && generation == _generation) {
        state = CustomerNotificationRouteState(
          status: CustomerNotificationRouteStatus.failure,
          failure: error.kind,
          revision: state.revision + 1,
        );
      }
      return null;
    } on Object {
      if (_isCurrent(subjectId) && generation == _generation) {
        state = CustomerNotificationRouteState(
          status: CustomerNotificationRouteStatus.failure,
          failure: CustomerNotificationFailureKind.unexpected,
          revision: state.revision + 1,
        );
      }
      return null;
    }
  }

  bool _isCurrent(String subjectId) => !_disposed && _subjectId == subjectId;
}
