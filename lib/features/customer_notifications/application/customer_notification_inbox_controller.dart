import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/customer_notification_failure.dart';
import '../domain/customer_notification_models.dart';
import 'customer_notification_providers.dart';

enum CustomerNotificationInboxStatus {
  signedOut,
  loading,
  ready,
  offline,
  failure,
}

final class CustomerNotificationInboxState {
  const CustomerNotificationInboxState({
    required this.status,
    this.items = const [],
    this.category,
    this.nextCursor,
    this.unreadCount = 0,
    this.failure,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isMutating = false,
    this.isFromCache = false,
  });

  final CustomerNotificationInboxStatus status;
  final List<CustomerNotification> items;
  final CustomerNotificationCategory? category;
  final CustomerNotificationCursor? nextCursor;
  final int unreadCount;
  final CustomerNotificationFailureKind? failure;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isMutating;
  final bool isFromCache;

  bool get hasMore => nextCursor != null;

  CustomerNotificationInboxState copyWith({
    CustomerNotificationInboxStatus? status,
    List<CustomerNotification>? items,
    CustomerNotificationCategory? category,
    bool clearCategory = false,
    CustomerNotificationCursor? nextCursor,
    bool clearCursor = false,
    int? unreadCount,
    CustomerNotificationFailureKind? failure,
    bool clearFailure = false,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isMutating,
    bool? isFromCache,
  }) => CustomerNotificationInboxState(
    status: status ?? this.status,
    items: List.unmodifiable(items ?? this.items),
    category: clearCategory ? null : category ?? this.category,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    unreadCount: unreadCount ?? this.unreadCount,
    failure: clearFailure ? null : failure ?? this.failure,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isMutating: isMutating ?? this.isMutating,
    isFromCache: isFromCache ?? this.isFromCache,
  );
}

final customerNotificationInboxControllerProvider =
    NotifierProvider<
      CustomerNotificationInboxController,
      CustomerNotificationInboxState
    >(CustomerNotificationInboxController.new);

final class CustomerNotificationInboxController
    extends Notifier<CustomerNotificationInboxState> {
  String? _owner;
  String? _shop;
  var _initialized = false;
  var _generation = 0;
  var _disposed = false;

  @override
  CustomerNotificationInboxState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    final owner = ref.watch(customerNotificationIdentityProvider)?.subjectId;
    final shop = ref.watch(customerNotificationShopSlugProvider);
    if (_initialized && owner == _owner && shop == _shop) return state;
    _initialized = true;
    _owner = owner;
    _shop = shop;
    if (owner == null || shop == null) {
      return const CustomerNotificationInboxState(
        status: CustomerNotificationInboxStatus.signedOut,
      );
    }
    final generation = ++_generation;
    scheduleMicrotask(() => _load(generation, allowCache: true));
    return const CustomerNotificationInboxState(
      status: CustomerNotificationInboxStatus.loading,
      isRefreshing: true,
    );
  }

  Future<void> refresh() => _load(++_generation, allowCache: false);

  Future<void> selectCategory(CustomerNotificationCategory? category) async {
    if (category == CustomerNotificationCategory.system ||
        category == state.category) {
      return;
    }
    state = CustomerNotificationInboxState(
      status: CustomerNotificationInboxStatus.loading,
      category: category,
      unreadCount: state.unreadCount,
      isRefreshing: true,
    );
    await _load(++_generation, allowCache: category == null);
  }

  Future<void> loadMore() async {
    final owner = _owner;
    final shop = _shop;
    final cursor = state.nextCursor;
    if (owner == null ||
        shop == null ||
        cursor == null ||
        state.isLoadingMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    try {
      final page = await ref
          .read(customerNotificationRepositoryProvider)
          .list(shopSlug: shop, category: state.category, before: cursor);
      if (!_current(owner, shop)) return;
      final merged = <String, CustomerNotification>{
        for (final item in state.items) item.id: item,
        for (final item in page.items) item.id: item,
      }.values.toList(growable: false);
      state = state.copyWith(
        status: CustomerNotificationInboxStatus.ready,
        items: merged,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        unreadCount: page.unreadCount,
        isLoadingMore: false,
      );
      await _saveCache(owner, shop);
    } on Object catch (error) {
      if (_current(owner, shop)) {
        state = state.copyWith(
          failure: _failureKind(error),
          isLoadingMore: false,
        );
      }
    }
  }

  Future<void> markRead(String id) async {
    final owner = _owner;
    final shop = _shop;
    final current = state.items.where((item) => item.id == id).firstOrNull;
    if (owner == null ||
        shop == null ||
        current == null ||
        !current.isUnread ||
        state.isMutating) {
      return;
    }
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      final readAt = await ref
          .read(customerNotificationRepositoryProvider)
          .markRead(id);
      if (!_current(owner, shop)) return;
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == id) item.markRead(readAt) else item,
        ],
        unreadCount: (state.unreadCount - 1).clamp(0, 1 << 31),
        isMutating: false,
      );
      await _saveCache(owner, shop);
    } on Object catch (error) {
      if (_current(owner, shop)) {
        state = state.copyWith(failure: _failureKind(error), isMutating: false);
      }
    }
  }

  Future<void> markAllRead() async {
    final owner = _owner;
    final shop = _shop;
    if (owner == null || shop == null || state.isMutating) return;
    state = state.copyWith(isMutating: true, clearFailure: true);
    try {
      await ref.read(customerNotificationRepositoryProvider).markAllRead(shop);
      if (!_current(owner, shop)) return;
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        items: state.items.map((item) => item.markRead(now)).toList(),
        unreadCount: 0,
        isMutating: false,
      );
      await _saveCache(owner, shop);
    } on Object catch (error) {
      if (_current(owner, shop)) {
        state = state.copyWith(failure: _failureKind(error), isMutating: false);
      }
    }
  }

  Future<void> _load(int generation, {required bool allowCache}) async {
    final owner = _owner;
    final shop = _shop;
    if (owner == null || shop == null) return;
    if (allowCache && state.category == null) {
      final cached = await ref
          .read(customerNotificationCacheProvider)
          .read(ownerSubjectId: owner, shopSlug: shop);
      if (!_current(owner, shop) || generation != _generation) return;
      if (cached.isNotEmpty) {
        state = state.copyWith(
          status: CustomerNotificationInboxStatus.loading,
          items: cached,
          unreadCount: cached.where((item) => item.isUnread).length,
          isFromCache: true,
          isRefreshing: true,
        );
      }
    }
    try {
      final page = await ref
          .read(customerNotificationRepositoryProvider)
          .list(shopSlug: shop, category: state.category);
      if (!_current(owner, shop) || generation != _generation) return;
      state = state.copyWith(
        status: CustomerNotificationInboxStatus.ready,
        items: page.items,
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        unreadCount: page.unreadCount,
        isRefreshing: false,
        isFromCache: false,
        clearFailure: true,
      );
      await _saveCache(owner, shop);
    } on Object catch (error) {
      if (!_current(owner, shop) || generation != _generation) return;
      final failure = _failureKind(error);
      final cached = state.items.isNotEmpty;
      state = state.copyWith(
        status:
            cached &&
                (failure == CustomerNotificationFailureKind.offline ||
                    failure == CustomerNotificationFailureKind.timeout)
            ? CustomerNotificationInboxStatus.offline
            : CustomerNotificationInboxStatus.failure,
        failure: failure,
        isRefreshing: false,
      );
    }
  }

  Future<void> _saveCache(String owner, String shop) async {
    if (state.category != null) return;
    try {
      await ref
          .read(customerNotificationCacheProvider)
          .write(ownerSubjectId: owner, shopSlug: shop, items: state.items);
    } on Object {
      // Read-only cache failure never changes the server-authoritative inbox.
    }
  }

  bool _current(String owner, String shop) =>
      !_disposed && _owner == owner && _shop == shop;

  CustomerNotificationFailureKind _failureKind(Object error) =>
      error is CustomerNotificationRepositoryException
      ? error.kind
      : CustomerNotificationFailureKind.unexpected;
}
