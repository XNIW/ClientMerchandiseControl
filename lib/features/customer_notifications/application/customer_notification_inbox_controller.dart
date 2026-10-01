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
    this.unreadOnly = false,
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
  final bool unreadOnly;

  List<CustomerNotification> get visibleItems => unreadOnly
      ? items.where((item) => item.isUnread).toList(growable: false)
      : items;

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
    bool? unreadOnly,
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
    unreadOnly: unreadOnly ?? this.unreadOnly,
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
  Future<void> _cacheOperations = Future.value();

  @override
  CustomerNotificationInboxState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
    });
    final owner = ref.watch(customerNotificationIdentityProvider)?.subjectId;
    final shop = ref.watch(customerNotificationShopSlugProvider);
    if (_initialized && owner == _owner && shop == _shop) return state;
    _initialized = true;
    _owner = owner;
    _shop = shop;
    final generation = ++_generation;
    if (owner == null || shop == null) {
      return const CustomerNotificationInboxState(
        status: CustomerNotificationInboxStatus.signedOut,
      );
    }
    scheduleMicrotask(() => _load(generation, allowCache: true));
    return const CustomerNotificationInboxState(
      status: CustomerNotificationInboxStatus.loading,
      isRefreshing: true,
    );
  }

  Future<void> refresh() async {
    if (state.isMutating) return;
    await _load(++_generation, allowCache: false);
  }

  void selectUnreadOnly(bool value) {
    state = state.copyWith(unreadOnly: value);
  }

  Future<void> selectCategory(CustomerNotificationCategory? category) async {
    if (state.isMutating ||
        category == CustomerNotificationCategory.system ||
        category == state.category) {
      return;
    }
    state = CustomerNotificationInboxState(
      status: CustomerNotificationInboxStatus.loading,
      category: category,
      unreadOnly: state.unreadOnly,
      unreadCount: state.unreadCount,
      isRefreshing: true,
    );
    await _load(++_generation, allowCache: category == null);
  }

  Future<void> loadMore() async {
    final owner = _owner;
    final shop = _shop;
    final generation = _generation;
    final cursor = state.nextCursor;
    if (owner == null ||
        shop == null ||
        cursor == null ||
        state.isLoadingMore ||
        state.isMutating) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    try {
      final page = await ref
          .read(customerNotificationRepositoryProvider)
          .list(shopSlug: shop, category: state.category, before: cursor);
      if (!_current(owner, shop, generation)) return;
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
      await _recordFailure(error, owner, shop, generation);
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
    // Le letture precedenti non possono ripubblicare uno snapshot pre-mutation.
    // Il cursore resta valido per una nuova pagina autorevole dopo il risultato.
    final generation = ++_generation;
    state = state.copyWith(
      isMutating: true,
      isRefreshing: false,
      isLoadingMore: false,
      clearFailure: true,
    );
    try {
      final readAt = await ref
          .read(customerNotificationRepositoryProvider)
          .markRead(id);
      if (!_current(owner, shop, generation)) return;
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
      await _recordFailure(error, owner, shop, generation);
    }
  }

  Future<void> markAllRead() async {
    final owner = _owner;
    final shop = _shop;
    if (owner == null ||
        shop == null ||
        state.isMutating ||
        (state.status == CustomerNotificationInboxStatus.loading &&
            state.items.isEmpty)) {
      return;
    }
    // Le letture precedenti non possono ripubblicare uno snapshot pre-mutation.
    // Il cursore resta valido per una nuova pagina autorevole dopo il risultato.
    final generation = ++_generation;
    state = state.copyWith(
      isMutating: true,
      isRefreshing: false,
      isLoadingMore: false,
      clearFailure: true,
    );
    try {
      await ref.read(customerNotificationRepositoryProvider).markAllRead(shop);
      if (!_current(owner, shop, generation)) return;
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        items: state.items.map((item) => item.markRead(now)).toList(),
        unreadCount: 0,
        isMutating: false,
      );
      await _saveCache(owner, shop);
    } on Object catch (error) {
      await _recordFailure(error, owner, shop, generation);
    }
  }

  Future<void> _load(int generation, {required bool allowCache}) async {
    final owner = _owner;
    final shop = _shop;
    if (owner == null ||
        shop == null ||
        generation != _generation ||
        _disposed) {
      return;
    }
    state = state.copyWith(
      isRefreshing: true,
      isLoadingMore: false,
      isMutating: false,
    );
    if (allowCache && state.category == null) {
      final cached = await ref
          .read(customerNotificationCacheProvider)
          .read(ownerSubjectId: owner, shopSlug: shop);
      if (!_current(owner, shop, generation)) return;
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
      if (!_current(owner, shop, generation)) return;
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
      await _recordFailure(error, owner, shop, generation, loading: true);
    }
  }

  Future<void> _recordFailure(
    Object error,
    String owner,
    String shop,
    int generation, {
    bool loading = false,
  }) async {
    if (!_current(owner, shop, generation)) return;
    final failure = _failureKind(error);
    final transient =
        failure == CustomerNotificationFailureKind.offline ||
        failure == CustomerNotificationFailureKind.timeout;
    final clear = !transient;
    if (clear) _generation++;
    state = state.copyWith(
      status: clear
          ? CustomerNotificationInboxStatus.failure
          : loading
          ? (state.items.isNotEmpty
                ? CustomerNotificationInboxStatus.offline
                : CustomerNotificationInboxStatus.failure)
          : state.status,
      items: clear ? const [] : null,
      unreadCount: clear ? 0 : null,
      clearCursor: clear,
      isFromCache: clear ? false : null,
      failure: failure,
      isRefreshing: false,
      isLoadingMore: false,
      isMutating: false,
    );
    if (clear) {
      final cache = ref.read(customerNotificationCacheProvider);
      await _queueCacheOperation(
        () => cache.remove(ownerSubjectId: owner, shopSlug: shop),
      );
    }
  }

  Future<void> _saveCache(String owner, String shop) async {
    if (state.category != null) return;
    final cache = ref.read(customerNotificationCacheProvider);
    final generation = _generation;
    final items = state.items;
    await _queueCacheOperation(() async {
      if (!_current(owner, shop, generation)) return;
      await cache.write(ownerSubjectId: owner, shopSlug: shop, items: items);
    });
  }

  Future<void> _queueCacheOperation(Future<void> Function() operation) {
    // Una write già avviata deve finire prima del nuovo snapshot o del purge.
    // L'epoch scarta quelle accodate ma non ancora iniziate.
    final result = _cacheOperations.then((_) async {
      try {
        await operation();
      } on Object {
        // La cache best-effort non modifica lo stato autorevole della UI.
      }
    });
    _cacheOperations = result;
    return result;
  }

  bool _current(String owner, String shop, int generation) =>
      !_disposed &&
      _generation == generation &&
      _owner == owner &&
      _shop == shop;

  CustomerNotificationFailureKind _failureKind(Object error) =>
      error is CustomerNotificationRepositoryException
      ? error.kind
      : CustomerNotificationFailureKind.unexpected;
}
