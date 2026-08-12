import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../account/application/customer_account_providers.dart';
import '../../reservations/application/reservation_hold_controller.dart';
import '../../reservations/application/reservation_hold_providers.dart';
import '../../storefront/domain/storefront_models.dart';
import '../domain/cart_failure.dart';
import '../domain/cart_models.dart';
import 'cart_providers.dart';
import 'cart_state.dart';

final cartControllerProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);

final class CartController extends Notifier<CartState> {
  CartState? _lastState;
  String? _contextKey;
  String? _shopSlug;
  var _generation = 0;
  var _disposed = false;
  Future<void>? _operation;
  _PendingMerge? _pendingMerge;
  _PendingMutation? _pendingMutation;
  _PendingRevalidation? _pendingRevalidation;

  @override
  CartState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    final config = ref.watch(appConfigProvider);
    final identity = ref.watch(customerAccountIdentityProvider);
    final shopSlug = config.storefrontShopSlug;
    final contextKey = '$shopSlug|${identity?.subjectId ?? 'guest'}';
    if (_contextKey == contextKey && _lastState != null) {
      return _lastState!;
    }
    _contextKey = contextKey;
    _shopSlug = shopSlug;
    _pendingMerge = null;
    _pendingMutation = null;
    _pendingRevalidation = null;
    final authenticated = identity != null;
    if (shopSlug == null) {
      final failure = CartState.failure(
        isAuthenticated: authenticated,
        failureKind: CartFailureKind.invalidInput,
      );
      _lastState = failure;
      return failure;
    }
    final loading = CartState.loading(isAuthenticated: authenticated);
    _lastState = loading;
    final generation = ++_generation;
    scheduleMicrotask(() => _load(generation));
    return loading;
  }

  Future<void> retry() {
    return _serialize(() async {
      final generation = ++_generation;
      if (_pendingMutation != null) {
        await _retryMutation(generation);
      } else if (_pendingRevalidation != null) {
        await _retryRevalidation(generation);
      } else {
        await _load(generation, preserveData: true);
      }
    });
  }

  Future<void> refresh() {
    return _serialize(() async {
      final generation = ++_generation;
      _pendingMutation = null;
      _pendingRevalidation = null;
      await _load(generation, preserveData: true);
    });
  }

  Future<void> addProduct(
    StorefrontProductSummary product, {
    int quantity = 1,
  }) {
    return _withPublicationBusy(product.id, (context) async {
      final snapshot = _requireSnapshot();
      final current = snapshot.items
          .where((item) => item.publicationId == product.id)
          .firstOrNull;
      final target = (current?.quantity ?? 0) + quantity;
      if (quantity < 1 || target > customerCartMaximumQuantity) {
        throw const CartRepositoryException(CartFailureKind.invalidInput);
      }
      if (!state.isAuthenticated) {
        final updated = await ref
            .read(guestCartStoreProvider)
            .setProduct(
              shopSlug: context.shopSlug,
              product: product,
              quantity: target,
            );
        if (!_isCurrentContext(context)) return;
        _setReady(updated, notice: CartNoticeKind.added);
        return;
      }
      await _prepareReservationMutation(context, product.id);
      if (!_isCurrentContext(context)) return;
      await _runMutation(
        context: context,
        operation: CartMutationOperation.set,
        publicationId: product.id,
        quantity: target,
        notice: CartNoticeKind.added,
      );
    });
  }

  Future<void> setQuantity(String publicationId, int quantity) {
    return _withPublicationBusy(publicationId, (context) async {
      if (quantity < 1 || quantity > customerCartMaximumQuantity) {
        throw const CartRepositoryException(CartFailureKind.invalidInput);
      }
      if (!state.isAuthenticated) {
        final updated = await ref
            .read(guestCartStoreProvider)
            .setQuantity(
              shopSlug: context.shopSlug,
              publicationId: publicationId,
              quantity: quantity,
            );
        if (!_isCurrentContext(context)) return;
        _setReady(updated, notice: CartNoticeKind.updated);
        return;
      }
      await _prepareReservationMutation(context, publicationId);
      if (!_isCurrentContext(context)) return;
      await _runMutation(
        context: context,
        operation: CartMutationOperation.set,
        publicationId: publicationId,
        quantity: quantity,
        notice: CartNoticeKind.updated,
      );
    });
  }

  Future<void> remove(String publicationId) {
    return _withPublicationBusy(publicationId, (context) async {
      if (!state.isAuthenticated) {
        final updated = await ref
            .read(guestCartStoreProvider)
            .remove(shopSlug: context.shopSlug, publicationId: publicationId);
        if (!_isCurrentContext(context)) return;
        _setReady(updated, notice: CartNoticeKind.removed);
        return;
      }
      await _prepareReservationMutation(context, publicationId);
      if (!_isCurrentContext(context)) return;
      await _runMutation(
        context: context,
        operation: CartMutationOperation.remove,
        publicationId: publicationId,
        notice: CartNoticeKind.removed,
      );
    });
  }

  Future<void> clear() {
    return _withGlobalBusy((context) async {
      if (!state.isAuthenticated) {
        final updated = await ref
            .read(guestCartStoreProvider)
            .clear(shopSlug: context.shopSlug);
        if (!_isCurrentContext(context)) return;
        _setReady(updated, notice: CartNoticeKind.cleared);
        return;
      }
      await _prepareReservationMutation(context);
      if (!_isCurrentContext(context)) return;
      await _runMutation(
        context: context,
        operation: CartMutationOperation.clear,
        notice: CartNoticeKind.cleared,
      );
    });
  }

  Future<void> revalidate() {
    return _withGlobalBusy((context) async {
      if (!state.isAuthenticated) return;
      final snapshot = _requireSnapshot();
      final pending = _PendingRevalidation(
        expectedVersion: snapshot.version,
        idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
      );
      _pendingRevalidation = pending;
      await _executeRevalidation(
        pending,
        context: context,
        allowConflictRetry: true,
      );
    });
  }

  void clearNotice() {
    _publish(state.copyWith(clearNotice: true));
  }

  Future<void> _load(int generation, {bool preserveData = false}) async {
    final shopSlug = _requireShopSlug();
    final authenticated = ref.read(customerAccountIdentityProvider) != null;
    _publish(
      CartState.loading(
        isAuthenticated: authenticated,
        previous: preserveData ? state.snapshot : null,
      ),
    );
    CustomerCartSnapshot guest;
    try {
      guest = await ref.read(guestCartStoreProvider).read(shopSlug: shopSlug);
    } on CartRepositoryException catch (error) {
      _setFailure(error.kind, generation: generation);
      return;
    }
    if (!_isCurrent(generation)) return;
    if (!authenticated) {
      _pendingMerge = null;
      _setReady(guest, generation: generation);
      return;
    }
    try {
      final remote = await ref
          .read(customerCartRepositoryProvider)
          .read(shopSlug: shopSlug);
      final snapshot = remote.snapshot;
      if (snapshot == null) throw const FormatException('cart_read_snapshot');
      if (guest.isEmpty && _pendingMerge == null) {
        _setReady(snapshot, generation: generation);
        return;
      }
      final pending =
          _pendingMerge ??
          _PendingMerge(
            items: guest.items,
            expectedVersion: snapshot.version,
            idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
          );
      _pendingMerge = pending;
      await _executeMerge(
        pending,
        fallbackSnapshot: snapshot,
        generation: generation,
        allowConflictRetry: true,
      );
    } on CartRepositoryException catch (error) {
      _setFailure(
        error.kind,
        generation: generation,
        previous: guest,
        hasPendingRetry: _pendingMerge != null,
      );
    } on Object {
      _setFailure(
        CartFailureKind.unexpected,
        generation: generation,
        previous: guest,
      );
    }
  }

  Future<void> _executeMerge(
    _PendingMerge pending, {
    required CustomerCartSnapshot fallbackSnapshot,
    required int generation,
    required bool allowConflictRetry,
  }) async {
    try {
      final response = await ref
          .read(customerCartRepositoryProvider)
          .mergeGuest(
            shopSlug: _requireShopSlug(),
            guestItems: pending.items,
            expectedVersion: pending.expectedVersion,
            idempotencyKey: pending.idempotencyKey,
          );
      if (!_isCurrent(generation)) return;
      final remote = response.snapshot;
      if (remote == null) throw const FormatException('cart_merge_snapshot');
      if (response.status == CartRemoteStatus.versionConflict) {
        if (!allowConflictRetry) {
          throw const CartRepositoryException(CartFailureKind.conflict);
        }
        final retry = _PendingMerge(
          items: pending.items,
          expectedVersion: remote.version,
          idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
        );
        _pendingMerge = retry;
        await _executeMerge(
          retry,
          fallbackSnapshot: remote,
          generation: generation,
          allowConflictRetry: false,
        );
        return;
      }
      final rejected = response.rejectedPublicationIds.toSet();
      final retained = await ref
          .read(guestCartStoreProvider)
          .retainOnly(shopSlug: _requireShopSlug(), publicationIds: rejected);
      if (!_isCurrent(generation)) return;
      _pendingMerge = null;
      _setReady(
        remote.withGuestRetained(retained.items),
        generation: generation,
        notice: rejected.isEmpty
            ? CartNoticeKind.merged
            : CartNoticeKind.partialMerge,
      );
    } on CartRepositoryException catch (error) {
      _setFailure(
        error.kind,
        generation: generation,
        previous: fallbackSnapshot.withGuestRetained(pending.items),
        hasPendingRetry: true,
      );
    }
  }

  Future<void> _runMutation({
    required _CartInvocationContext context,
    required CartMutationOperation operation,
    String? publicationId,
    int? quantity,
    required CartNoticeKind notice,
  }) async {
    final snapshot = _requireSnapshot();
    final pending = _PendingMutation(
      request: CartMutationRequest(
        shopSlug: context.shopSlug,
        operation: operation,
        publicationId: publicationId,
        quantity: quantity,
        expectedVersion: snapshot.version,
        idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
      ),
      notice: notice,
    );
    _pendingMutation = pending;
    await _executeMutation(pending, context: context, allowConflictRetry: true);
  }

  Future<void> _executeMutation(
    _PendingMutation pending, {
    required _CartInvocationContext context,
    required bool allowConflictRetry,
  }) async {
    if (!_isCurrentContext(context)) return;
    final generation = context.generation;
    try {
      final response = await ref
          .read(customerCartRepositoryProvider)
          .mutate(pending.request);
      if (!_isCurrentContext(context)) return;
      final snapshot = response.snapshot;
      if (snapshot == null) {
        throw const FormatException('cart_mutation_snapshot');
      }
      if (response.status == CartRemoteStatus.versionConflict) {
        if (!allowConflictRetry) {
          throw const CartRepositoryException(CartFailureKind.conflict);
        }
        final retry = _PendingMutation(
          request: CartMutationRequest(
            shopSlug: pending.request.shopSlug,
            operation: pending.request.operation,
            publicationId: pending.request.publicationId,
            quantity: pending.request.quantity,
            expectedVersion: snapshot.version,
            idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
          ),
          notice: pending.notice,
        );
        _pendingMutation = retry;
        await _executeMutation(
          retry,
          context: context,
          allowConflictRetry: false,
        );
        return;
      }
      _pendingMutation = null;
      if (response.status == CartRemoteStatus.unavailable) {
        _setReady(snapshot, notice: CartNoticeKind.unavailable);
      } else if (response.status == CartRemoteStatus.limitReached) {
        _setReady(snapshot, notice: CartNoticeKind.limitReached);
      } else {
        _setReady(snapshot, notice: pending.notice);
      }
    } on CartRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(
        error.kind,
        generation: generation,
        previous: state.snapshot,
        hasPendingRetry: true,
      );
    }
  }

  Future<void> _retryMutation(int generation) async {
    final pending = _pendingMutation;
    if (pending == null) return;
    _publish(
      CartState.loading(isAuthenticated: true, previous: state.snapshot),
    );
    final context = _captureContext(generation: generation);
    if (context == null) return;
    await _executeMutation(pending, context: context, allowConflictRetry: true);
    if (!_isCurrent(generation)) return;
  }

  Future<void> _executeRevalidation(
    _PendingRevalidation pending, {
    required _CartInvocationContext context,
    required bool allowConflictRetry,
  }) async {
    if (!_isCurrentContext(context)) return;
    final generation = context.generation;
    try {
      final response = await ref
          .read(customerCartRepositoryProvider)
          .revalidate(
            shopSlug: context.shopSlug,
            expectedVersion: pending.expectedVersion,
            idempotencyKey: pending.idempotencyKey,
          );
      if (!_isCurrentContext(context)) return;
      final snapshot = response.snapshot;
      if (snapshot == null) {
        throw const FormatException('cart_revalidation_snapshot');
      }
      if (response.status == CartRemoteStatus.versionConflict) {
        if (!allowConflictRetry) {
          throw const CartRepositoryException(CartFailureKind.conflict);
        }
        final retry = _PendingRevalidation(
          expectedVersion: snapshot.version,
          idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
        );
        _pendingRevalidation = retry;
        await _executeRevalidation(
          retry,
          context: context,
          allowConflictRetry: false,
        );
        return;
      }
      _pendingRevalidation = null;
      _setReady(snapshot, notice: CartNoticeKind.revalidated);
    } on CartRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(
        error.kind,
        generation: generation,
        previous: state.snapshot,
        hasPendingRetry: true,
      );
    }
  }

  Future<void> _retryRevalidation(int generation) async {
    final pending = _pendingRevalidation;
    if (pending == null) return;
    _publish(
      CartState.loading(isAuthenticated: true, previous: state.snapshot),
    );
    final context = _captureContext(generation: generation);
    if (context == null) return;
    await _executeRevalidation(
      pending,
      context: context,
      allowConflictRetry: true,
    );
    if (!_isCurrent(generation)) return;
  }

  Future<void> _prepareReservationMutation(
    _CartInvocationContext context, [
    String? publicationId,
  ]) async {
    final subjectId = context.subjectId;
    if (subjectId == null || !_isCurrentContext(context)) return;
    final affected = publicationId == null
        ? _requireSnapshot().items.map((line) => line.publicationId).toSet()
        : {publicationId};
    await ref
        .read(reservationHoldCoordinatorProvider)
        .prepareForCartMutation(
          ownerSubjectId: subjectId,
          shopSlug: context.shopSlug,
          publicationId: publicationId,
        );
    if (!_isCurrentContext(context)) return;
    for (final id in affected) {
      ref.invalidate(reservationHoldControllerProvider(id));
    }
  }

  Future<void> _withPublicationBusy(
    String publicationId,
    Future<void> Function(_CartInvocationContext context) action,
  ) {
    if (state.busyPublicationIds.contains(publicationId)) {
      return Future<void>.value();
    }
    final context = _captureContext();
    if (context == null) return Future<void>.value();
    return _serialize(() async {
      if (!_isCurrentContext(context)) return;
      _publish(
        state.copyWith(
          busyPublicationIds: {...state.busyPublicationIds, publicationId},
          clearFailure: true,
          clearNotice: true,
        ),
      );
      try {
        await action(context);
      } on CartRepositoryException catch (error) {
        if (!_isCurrentContext(context)) return;
        _setFailure(error.kind, previous: state.snapshot);
        rethrow;
      } finally {
        if (_isCurrentContext(context)) {
          final busy = {...state.busyPublicationIds}..remove(publicationId);
          _publish(state.copyWith(busyPublicationIds: busy));
        }
      }
    });
  }

  Future<void> _withGlobalBusy(
    Future<void> Function(_CartInvocationContext context) action,
  ) {
    final context = _captureContext();
    if (context == null) return Future<void>.value();
    return _serialize(() async {
      if (!_isCurrentContext(context)) return;
      _publish(
        state.copyWith(
          isGlobalBusy: true,
          clearFailure: true,
          clearNotice: true,
        ),
      );
      try {
        await action(context);
      } on CartRepositoryException catch (error) {
        if (!_isCurrentContext(context)) return;
        _setFailure(error.kind, previous: state.snapshot);
        rethrow;
      } finally {
        if (_isCurrentContext(context)) {
          _publish(state.copyWith(isGlobalBusy: false));
        }
      }
    });
  }

  Future<void> _serialize(Future<void> Function() action) {
    final previous = _operation;
    late final Future<void> next;
    next =
        (() async {
          if (previous != null) {
            try {
              await previous;
            } on Object {
              // La nuova azione non eredita l'errore dell'azione precedente.
            }
          }
          await action();
        })().whenComplete(() {
          if (identical(_operation, next)) _operation = null;
        });
    _operation = next;
    return next;
  }

  CustomerCartSnapshot _requireSnapshot() {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      throw const CartRepositoryException(CartFailureKind.unavailable);
    }
    return snapshot;
  }

  String _requireShopSlug() {
    final shopSlug = _shopSlug;
    if (shopSlug == null) {
      throw const CartRepositoryException(CartFailureKind.invalidInput);
    }
    return shopSlug;
  }

  void _setReady(
    CustomerCartSnapshot snapshot, {
    int? generation,
    CartNoticeKind? notice,
  }) {
    if (generation != null && !_isCurrent(generation)) return;
    _publish(
      CartState(
        status: CartViewStatus.ready,
        isAuthenticated: ref.read(customerAccountIdentityProvider) != null,
        snapshot: snapshot,
        notice: notice,
      ),
    );
  }

  void _setFailure(
    CartFailureKind kind, {
    int? generation,
    CustomerCartSnapshot? previous,
    bool hasPendingRetry = false,
  }) {
    if (generation != null && !_isCurrent(generation)) return;
    _publish(
      CartState.failure(
        isAuthenticated: ref.read(customerAccountIdentityProvider) != null,
        failureKind: kind,
        previous: previous,
        hasPendingRetry: hasPendingRetry,
      ),
    );
  }

  void _publish(CartState value) {
    if (_disposed) return;
    _lastState = value;
    state = value;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  _CartInvocationContext? _captureContext({int? generation}) {
    final shop = _shopSlug;
    if (shop == null) return null;
    return _CartInvocationContext(
      generation: generation ?? _generation,
      contextKey: _contextKey,
      shopSlug: shop,
      subjectId: ref.read(customerAccountIdentityProvider)?.subjectId,
    );
  }

  bool _isCurrentContext(_CartInvocationContext context) {
    return _isCurrent(context.generation) &&
        _contextKey == context.contextKey &&
        _shopSlug == context.shopSlug &&
        ref.read(customerAccountIdentityProvider)?.subjectId ==
            context.subjectId;
  }
}

final class _CartInvocationContext {
  const _CartInvocationContext({
    required this.generation,
    required this.contextKey,
    required this.shopSlug,
    required this.subjectId,
  });

  final int generation;
  final String? contextKey;
  final String shopSlug;
  final String? subjectId;
}

final class _PendingMerge {
  _PendingMerge({
    required List<CartLine> items,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : items = List.unmodifiable(items);

  final List<CartLine> items;
  final int expectedVersion;
  final String idempotencyKey;
}

final class _PendingMutation {
  const _PendingMutation({required this.request, required this.notice});

  final CartMutationRequest request;
  final CartNoticeKind notice;
}

final class _PendingRevalidation {
  const _PendingRevalidation({
    required this.expectedVersion,
    required this.idempotencyKey,
  });

  final int expectedVersion;
  final String idempotencyKey;
}
