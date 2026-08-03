import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer_order_failure.dart';
import '../domain/customer_order_models.dart';
import 'customer_order_providers.dart';

const _customerOrdersUnset = Object();

enum CustomerOrdersStatus { signedOut, loading, ready, offline, failure }

enum CustomerOrdersNotice { cancelled, cancellationFailed }

final class CustomerOrdersState {
  const CustomerOrdersState({
    required this.status,
    this.orders = const [],
    this.nextCursor,
    this.cachedAt,
    this.selectedOrderId,
    this.selectedOrder,
    this.failure,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isDetailLoading = false,
    this.isCancelling = false,
    this.notice,
    this.noticeRevision = 0,
  });

  const CustomerOrdersState.signedOut()
    : this(status: CustomerOrdersStatus.signedOut);

  const CustomerOrdersState.loading()
    : this(status: CustomerOrdersStatus.loading, isRefreshing: true);

  final CustomerOrdersStatus status;
  final List<CustomerOrderCard> orders;
  final CustomerOrderCursor? nextCursor;
  final DateTime? cachedAt;
  final String? selectedOrderId;
  final CustomerOrderDetail? selectedOrder;
  final CustomerOrderFailureKind? failure;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isDetailLoading;
  final bool isCancelling;
  final CustomerOrdersNotice? notice;
  final int noticeRevision;

  bool get hasMore => nextCursor != null;
  bool get hasCachedData => orders.isNotEmpty || selectedOrder != null;

  CustomerOrdersState copyWith({
    CustomerOrdersStatus? status,
    List<CustomerOrderCard>? orders,
    Object? nextCursor = _customerOrdersUnset,
    Object? cachedAt = _customerOrdersUnset,
    Object? selectedOrderId = _customerOrdersUnset,
    Object? selectedOrder = _customerOrdersUnset,
    Object? failure = _customerOrdersUnset,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isDetailLoading,
    bool? isCancelling,
    Object? notice = _customerOrdersUnset,
    int? noticeRevision,
  }) {
    return CustomerOrdersState(
      status: status ?? this.status,
      orders: List.unmodifiable(orders ?? this.orders),
      nextCursor: identical(nextCursor, _customerOrdersUnset)
          ? this.nextCursor
          : nextCursor as CustomerOrderCursor?,
      cachedAt: identical(cachedAt, _customerOrdersUnset)
          ? this.cachedAt
          : cachedAt as DateTime?,
      selectedOrderId: identical(selectedOrderId, _customerOrdersUnset)
          ? this.selectedOrderId
          : selectedOrderId as String?,
      selectedOrder: identical(selectedOrder, _customerOrdersUnset)
          ? this.selectedOrder
          : selectedOrder as CustomerOrderDetail?,
      failure: identical(failure, _customerOrdersUnset)
          ? this.failure
          : failure as CustomerOrderFailureKind?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isCancelling: isCancelling ?? this.isCancelling,
      notice: identical(notice, _customerOrdersUnset)
          ? this.notice
          : notice as CustomerOrdersNotice?,
      noticeRevision: noticeRevision ?? this.noticeRevision,
    );
  }
}

final customerOrderControllerProvider =
    NotifierProvider<CustomerOrderController, CustomerOrdersState>(
      CustomerOrderController.new,
    );

final class CustomerOrderController extends Notifier<CustomerOrdersState> {
  CustomerOrdersState? _lastState;
  CustomerOrderCacheSnapshot? _cache;
  Future<void> _tail = Future<void>.value();
  String? _subjectId;
  String? _shopSlug;
  var _generation = 0;
  var _disposed = false;

  @override
  CustomerOrdersState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    final identity = ref.watch(customerOrderIdentityProvider);
    final shopSlug = ref.watch(customerOrderShopSlugProvider);
    if (identity == null || shopSlug == null) {
      _subjectId = null;
      _shopSlug = null;
      _cache = null;
      const signedOut = CustomerOrdersState.signedOut();
      _lastState = signedOut;
      return signedOut;
    }
    if (_subjectId == identity.subjectId &&
        _shopSlug == shopSlug &&
        _lastState != null) {
      return _lastState!;
    }
    _subjectId = identity.subjectId;
    _shopSlug = shopSlug;
    _cache = null;
    const loading = CustomerOrdersState.loading();
    _lastState = loading;
    final generation = ++_generation;
    scheduleMicrotask(() => _loadContext(generation));
    return loading;
  }

  Future<void> retry() => refresh();

  Future<void> refresh() {
    final generation = ++_generation;
    return _serialized(() => _refreshList(generation));
  }

  Future<void> loadMore() {
    return _serialized(() async {
      final subjectId = _subjectId;
      final shopSlug = _shopSlug;
      final cursor = _lastState?.nextCursor;
      if (subjectId == null ||
          shopSlug == null ||
          cursor == null ||
          _lastState?.isLoadingMore == true) {
        return;
      }
      _publish(
        (_lastState ?? const CustomerOrdersState.loading()).copyWith(
          isLoadingMore: true,
          failure: null,
        ),
      );
      try {
        final page = await ref
            .read(customerOrderRepositoryProvider)
            .listOrders(shopSlug: shopSlug, cursor: cursor);
        if (!_isCurrent(subjectId, shopSlug)) return;
        final merged = <String, CustomerOrderCard>{
          for (final order in _lastState?.orders ?? const <CustomerOrderCard>[])
            order.id: order,
          for (final order in page.orders) order.id: order,
        }.values.toList(growable: false);
        final cachedOrders = merged
            .take(customerOrderMaximumCachedCards)
            .toList(growable: false);
        final cachedCursor = merged.length <= customerOrderMaximumCachedCards
            ? page.nextCursor
            : null;
        _cache = _currentCache(subjectId, shopSlug).copyWith(
          orders: cachedOrders,
          nextCursor: cachedCursor,
          clearNextCursor: cachedCursor == null,
          cachedAt: ref.read(customerOrderClockProvider)(),
        );
        await _saveCache(required: false);
        _publish(
          _lastState!.copyWith(
            status: CustomerOrdersStatus.ready,
            orders: merged,
            nextCursor: page.nextCursor,
            failure: null,
            isLoadingMore: false,
            cachedAt: _cache!.cachedAt,
          ),
        );
      } on Object catch (error) {
        if (!_isCurrent(subjectId, shopSlug)) return;
        _publishLoadFailure(error, isLoadingMore: true);
      }
    });
  }

  Future<void> openOrder(String orderId, {bool forceRefresh = false}) {
    return _serialized(() async {
      final subjectId = _subjectId;
      final shopSlug = _shopSlug;
      if (subjectId == null || shopSlug == null) return;
      final cached = _cache?.details[orderId];
      _publish(
        (_lastState ?? const CustomerOrdersState.loading()).copyWith(
          selectedOrderId: orderId,
          selectedOrder: cached,
          isDetailLoading: forceRefresh || cached == null,
          failure: null,
        ),
      );
      if (cached != null && !forceRefresh) {
        _publish(_lastState!.copyWith(isDetailLoading: false));
      }
      try {
        final detail = await ref
            .read(customerOrderRepositoryProvider)
            .loadOrder(shopSlug: shopSlug, orderId: orderId);
        if (!_isCurrent(subjectId, shopSlug) ||
            _lastState?.selectedOrderId != orderId) {
          return;
        }
        _rememberDetail(detail, subjectId: subjectId, shopSlug: shopSlug);
        await _saveCache(required: false);
        _publish(
          _lastState!.copyWith(
            status: CustomerOrdersStatus.ready,
            selectedOrder: detail,
            isDetailLoading: false,
            failure: null,
            cachedAt: _cache!.cachedAt,
          ),
        );
      } on Object catch (error) {
        if (!_isCurrent(subjectId, shopSlug) ||
            _lastState?.selectedOrderId != orderId) {
          return;
        }
        final failure = _failure(error);
        _publish(
          _lastState!.copyWith(
            status:
                cached != null &&
                    (failure == CustomerOrderFailureKind.offline ||
                        failure == CustomerOrderFailureKind.timeout)
                ? CustomerOrdersStatus.offline
                : CustomerOrdersStatus.failure,
            isDetailLoading: false,
            failure: failure,
          ),
        );
      }
    });
  }

  Future<void> cancelSelectedOrder() {
    return _serialized(() async {
      final subjectId = _subjectId;
      final shopSlug = _shopSlug;
      final detail = _lastState?.selectedOrder;
      if (subjectId == null ||
          shopSlug == null ||
          detail == null ||
          _lastState?.isCancelling == true ||
          !detail.cancellation.allowed) {
        return;
      }
      var pending = _cache?.pendingCancellation;
      if (pending == null ||
          pending.orderId != detail.id ||
          pending.expectedStatusVersion != detail.version) {
        pending = CustomerOrderPendingCancellation(
          orderId: detail.id,
          expectedStatusVersion: detail.version,
          idempotencyKey: ref.read(
            customerOrderIdempotencyKeyFactoryProvider,
          )(),
          createdAt: ref.read(customerOrderClockProvider)(),
        );
        _cache = _currentCache(
          subjectId,
          shopSlug,
        ).copyWith(pendingCancellation: pending);
        try {
          await _saveCache(required: true);
        } on Object {
          _publishCancellationFailure(CustomerOrderFailureKind.unexpected);
          return;
        }
      }
      _publish(
        _lastState!.copyWith(isCancelling: true, failure: null, notice: null),
      );
      try {
        final updated = await ref
            .read(customerOrderRepositoryProvider)
            .cancelOrder(
              shopSlug: shopSlug,
              orderId: detail.id,
              expectedStatusVersion: pending.expectedStatusVersion,
              idempotencyKey: pending.idempotencyKey,
            );
        if (!_isCurrent(subjectId, shopSlug) ||
            _lastState?.selectedOrderId != detail.id) {
          return;
        }
        _rememberDetail(updated, subjectId: subjectId, shopSlug: shopSlug);
        _cache = _cache!.copyWith(clearPendingCancellation: true);
        await _saveCache(required: false);
        _publish(
          _lastState!.copyWith(
            status: CustomerOrdersStatus.ready,
            selectedOrder: updated,
            orders: _replaceCard(_lastState!.orders, updated),
            isCancelling: false,
            failure: null,
            notice: CustomerOrdersNotice.cancelled,
            noticeRevision: _lastState!.noticeRevision + 1,
            cachedAt: _cache!.cachedAt,
          ),
        );
      } on Object catch (error) {
        if (!_isCurrent(subjectId, shopSlug)) return;
        final failure = _failure(error);
        final isAmbiguous =
            failure == CustomerOrderFailureKind.offline ||
            failure == CustomerOrderFailureKind.timeout;
        if (!isAmbiguous) {
          _cache = _cache?.copyWith(clearPendingCancellation: true);
          await _saveCache(required: false);
          try {
            final latest = await ref
                .read(customerOrderRepositoryProvider)
                .loadOrder(shopSlug: shopSlug, orderId: detail.id);
            if (_isCurrent(subjectId, shopSlug) &&
                _lastState?.selectedOrderId == detail.id) {
              _rememberDetail(latest, subjectId: subjectId, shopSlug: shopSlug);
              await _saveCache(required: false);
              _publish(
                _lastState!.copyWith(
                  selectedOrder: latest,
                  orders: _replaceCard(_lastState!.orders, latest),
                  cachedAt: _cache!.cachedAt,
                ),
              );
            }
          } on Object {
            // The cancellation result remains authoritative. A later explicit
            // refresh can recover when this best-effort reconciliation fails.
          }
        }
        _publishCancellationFailure(failure);
      }
    });
  }

  void clearSelection() {
    final current = _lastState;
    if (current == null) return;
    _publish(
      current.copyWith(
        selectedOrderId: null,
        selectedOrder: null,
        isDetailLoading: false,
        isCancelling: false,
        failure: null,
        notice: null,
      ),
    );
  }

  void clearNotice() {
    final current = _lastState;
    if (current != null && current.notice != null) {
      _publish(current.copyWith(notice: null));
    }
  }

  Future<void> _loadContext(int generation) {
    return _serialized(() async {
      final subjectId = _subjectId;
      final shopSlug = _shopSlug;
      if (subjectId == null || shopSlug == null || generation != _generation) {
        return;
      }
      try {
        final cached = await ref
            .read(customerOrderCacheStoreProvider)
            .read(ownerSubjectId: subjectId, shopSlug: shopSlug);
        if (!_isCurrent(subjectId, shopSlug) || generation != _generation) {
          return;
        }
        _cache = cached;
        if (cached != null) {
          final current = _lastState;
          final selectedOrderId = current?.selectedOrderId;
          _publish(
            CustomerOrdersState(
              status: CustomerOrdersStatus.loading,
              orders: cached.orders,
              nextCursor: cached.nextCursor,
              cachedAt: cached.cachedAt,
              selectedOrderId: selectedOrderId,
              selectedOrder:
                  current?.selectedOrder ??
                  (selectedOrderId == null
                      ? null
                      : cached.details[selectedOrderId]),
              isDetailLoading: current?.isDetailLoading ?? false,
              isRefreshing: true,
            ),
          );
        }
      } on Object {
        _cache = null;
      }
      await _refreshList(generation);
    });
  }

  Future<void> _refreshList(int generation) async {
    final subjectId = _subjectId;
    final shopSlug = _shopSlug;
    if (subjectId == null || shopSlug == null) return;
    _publish(
      (_lastState ?? const CustomerOrdersState.loading()).copyWith(
        isRefreshing: true,
        failure: null,
      ),
    );
    try {
      final page = await ref
          .read(customerOrderRepositoryProvider)
          .listOrders(shopSlug: shopSlug);
      if (!_isCurrent(subjectId, shopSlug) || generation != _generation) {
        return;
      }
      final previous = _currentCache(subjectId, shopSlug);
      final visibleIds = page.orders.map((order) => order.id).toSet();
      final retainedDetails = <String, CustomerOrderDetail>{
        for (final entry in previous.details.entries)
          if (visibleIds.contains(entry.key) ||
              entry.key == _lastState?.selectedOrderId)
            entry.key: entry.value,
      };
      _cache = CustomerOrderCacheSnapshot(
        ownerSubjectId: subjectId,
        shopSlug: shopSlug,
        orders: page.orders,
        details: retainedDetails,
        nextCursor: page.nextCursor,
        pendingCancellation: previous.pendingCancellation,
        cachedAt: ref.read(customerOrderClockProvider)(),
      );
      await _saveCache(required: false);
      final selectedId = _lastState?.selectedOrderId;
      _publish(
        (_lastState ?? const CustomerOrdersState.loading()).copyWith(
          status: CustomerOrdersStatus.ready,
          orders: page.orders,
          nextCursor: page.nextCursor,
          cachedAt: _cache!.cachedAt,
          selectedOrder: selectedId == null
              ? null
              : retainedDetails[selectedId],
          isRefreshing: false,
          failure: null,
        ),
      );
    } on Object catch (error) {
      if (!_isCurrent(subjectId, shopSlug) || generation != _generation) {
        return;
      }
      _publishLoadFailure(error);
    }
  }

  void _publishLoadFailure(Object error, {bool isLoadingMore = false}) {
    final current = _lastState ?? const CustomerOrdersState.loading();
    final failure = _failure(error);
    final cached = current.hasCachedData;
    final offline =
        failure == CustomerOrderFailureKind.offline ||
        failure == CustomerOrderFailureKind.timeout;
    _publish(
      current.copyWith(
        status: cached && offline
            ? CustomerOrdersStatus.offline
            : CustomerOrdersStatus.failure,
        failure: failure,
        isRefreshing: false,
        isLoadingMore: isLoadingMore ? false : current.isLoadingMore,
      ),
    );
  }

  void _publishCancellationFailure(CustomerOrderFailureKind failure) {
    final current = _lastState;
    if (current == null) return;
    final offline =
        failure == CustomerOrderFailureKind.offline ||
        failure == CustomerOrderFailureKind.timeout;
    _publish(
      current.copyWith(
        status: offline ? CustomerOrdersStatus.offline : current.status,
        isCancelling: false,
        failure: failure,
        notice: CustomerOrdersNotice.cancellationFailed,
        noticeRevision: current.noticeRevision + 1,
      ),
    );
  }

  void _rememberDetail(
    CustomerOrderDetail detail, {
    required String subjectId,
    required String shopSlug,
  }) {
    final cache = _currentCache(subjectId, shopSlug);
    final details = <String, CustomerOrderDetail>{...cache.details};
    details.remove(detail.id);
    details[detail.id] = detail;
    while (details.length > customerOrderMaximumCachedDetails) {
      details.remove(details.keys.first);
    }
    _cache = cache.copyWith(
      details: details,
      orders: _replaceCard(cache.orders, detail),
      cachedAt: ref.read(customerOrderClockProvider)(),
    );
  }

  List<CustomerOrderCard> _replaceCard(
    List<CustomerOrderCard> orders,
    CustomerOrderDetail detail,
  ) {
    if (!orders.any((order) => order.id == detail.id)) return orders;
    return orders
        .map(
          (order) => order.id == detail.id
              ? CustomerOrderCard.fromDetail(detail)
              : order,
        )
        .toList(growable: false);
  }

  CustomerOrderCacheSnapshot _currentCache(String subjectId, String shopSlug) {
    return _cache ??
        CustomerOrderCacheSnapshot(
          ownerSubjectId: subjectId,
          shopSlug: shopSlug,
          orders: const [],
          details: const {},
          nextCursor: null,
          pendingCancellation: null,
          cachedAt: ref.read(customerOrderClockProvider)(),
        );
  }

  Future<void> _saveCache({required bool required}) async {
    final cache = _cache;
    if (cache == null) return;
    try {
      await ref.read(customerOrderCacheStoreProvider).save(cache);
    } on Object {
      if (required) rethrow;
    }
  }

  CustomerOrderFailureKind _failure(Object error) {
    if (error is CustomerOrderRepositoryException) return error.kind;
    return CustomerOrderFailureKind.unexpected;
  }

  bool _isCurrent(String subjectId, String shopSlug) {
    return !_disposed && _subjectId == subjectId && _shopSlug == shopSlug;
  }

  Future<void> _serialized(Future<void> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }

  void _publish(CustomerOrdersState next) {
    if (_disposed) return;
    _lastState = next;
    state = next;
  }
}
