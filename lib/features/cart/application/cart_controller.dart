import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/observability/observability_event.dart';
import '../../../core/observability/observability_providers.dart';
import '../../../core/time/app_scheduler.dart';
import '../../account/application/customer_account_providers.dart';
import '../../reservations/application/reservation_hold_controller.dart';
import '../../reservations/application/reservation_hold_providers.dart';
import '../../storefront/domain/storefront_models.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../domain/cart_action_result.dart';
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
  final _adding = <(int, String)>{};
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
    ref.listen(authControllerProvider, (previous, next) {
      String? owner(AuthState? value) => switch (value) {
        AuthAuthenticated(:final customer) => customer.subjectId,
        _ => null,
      };
      if (owner(previous) != owner(next)) {
        ++_generation;
        _contextKey = null;
        _lastState = null;
        _pendingMerge = null;
        _pendingMutation = null;
        _pendingRevalidation = null;
        state = CartState.loading(isAuthenticated: owner(next) != null);
        ref.invalidateSelf();
      }
    });
    final shopSlug = ref.watch(
      appConfigProvider.select((config) => config.storefrontShopSlug),
    );
    final subjectId = ref.watch(
      customerAccountIdentityProvider.select((identity) => identity?.subjectId),
    );
    final contextKey = '$shopSlug|${subjectId ?? 'guest'}';
    if (_contextKey == contextKey && _lastState != null) {
      return _lastState!;
    }
    _contextKey = contextKey;
    _shopSlug = shopSlug;
    _pendingMerge = null;
    _pendingMutation = null;
    _pendingRevalidation = null;
    final authenticated = subjectId != null;
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
    final context = _captureContext();
    return _serialize(() async {
      if (context == null || !_isCurrentContext(context)) return;
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
    final context = _captureContext();
    return _serialize(() async {
      if (context == null || !_isCurrentContext(context)) return;
      final generation = ++_generation;
      if (_pendingMutation != null) {
        await _retryMutation(generation);
        return;
      }
      if (_pendingRevalidation != null) {
        await _retryRevalidation(generation);
        return;
      }
      await _load(generation, preserveData: true);
    });
  }

  Future<CartActionResult> addProduct(
    StorefrontProductSummary product, {
    int quantity = 1,
  }) async {
    final context = _captureContext();
    if (context == null) {
      return CartActionResult(
        outcome: CartActionOutcome.rejected,
        generation: _generation,
        shopSlug: null,
        subjectId: null,
        failureKind: CartFailureKind.invalidInput,
      );
    }
    final slot = (context.generation, product.id);
    if (state.busyPublicationIds.contains(product.id) || !_adding.add(slot)) {
      return _result(context, CartActionOutcome.ignored);
    }
    final clock = ref.read(appClockProvider);
    final result = await _serialize(() async {
      if (!_isCurrentContext(context)) {
        return _result(context, CartActionOutcome.contextChanged);
      }
      // Il retry riconcilia la mutation ambigua con la stessa chiave. Un nuovo
      // add non può sostituire l'intent o sommare di nuovo una quantità già accettata.
      final pendingFailure = _pendingFailure;
      if (pendingFailure != null) {
        return _result(
          context,
          CartActionOutcome.pendingConfirmation,
          failure: pendingFailure,
        );
      }
      _publish(
        state.copyWith(
          busyPublicationIds: {...state.busyPublicationIds, product.id},
          clearFailure: true,
          clearNotice: true,
        ),
      );
      try {
        final snapshot = _requireSnapshot();
        final current = snapshot.items
            .where((item) => item.publicationId == product.id)
            .firstOrNull;
        final target = (current?.quantity ?? 0) + quantity;
        if (quantity < 1 || target > customerCartMaximumQuantity) {
          throw const CartRepositoryException(CartFailureKind.limitReached);
        }
        if (context.subjectId == null) {
          final updated = await ref
              .read(guestCartStoreProvider)
              .setProduct(
                shopSlug: context.shopSlug,
                product: product,
                quantity: target,
              );
          if (!_isCurrentContext(context)) {
            return _result(context, CartActionOutcome.contextChanged);
          }
          _setReady(updated);
          return _result(context, CartActionOutcome.localSaved);
        }
        await _prepareReservationMutation(context, product.id);
        if (!_isCurrentContext(context)) {
          return _result(context, CartActionOutcome.contextChanged);
        }
        return await _runMutation(
          context: context,
          operation: CartMutationOperation.set,
          publicationId: product.id,
          quantity: target,
          notice: CartNoticeKind.added,
        );
      } on CartRepositoryException catch (error) {
        if (!_isCurrentContext(context)) {
          return _result(context, CartActionOutcome.contextChanged);
        }
        _setFailure(error.kind, previous: state.snapshot);
        return _result(
          context,
          CartActionOutcome.rejected,
          failure: error.kind,
        );
      } on Object {
        if (!_isCurrentContext(context)) {
          return _result(context, CartActionOutcome.contextChanged);
        }
        _setFailure(CartFailureKind.unexpected, previous: state.snapshot);
        return _result(
          context,
          CartActionOutcome.rejected,
          failure: CartFailureKind.unexpected,
        );
      } finally {
        if (_isCurrentContext(context)) {
          _publish(
            state.copyWith(
              busyPublicationIds: {...state.busyPublicationIds}
                ..remove(product.id),
            ),
          );
        }
      }
    }).whenComplete(() => _adding.remove(slot));
    _recordAddOutcome(
      occurredAt: clock(),
      quantity: quantity,
      outcome: switch (result.outcome) {
        CartActionOutcome.localSaved ||
        CartActionOutcome.accountConfirmed => ObservabilityOutcome.success,
        CartActionOutcome.rejected ||
        CartActionOutcome.pendingConfirmation => ObservabilityOutcome.failure,
        _ => ObservabilityOutcome.ignored,
      },
      failure: result.failureKind == null
          ? null
          : _cartFailureCategory(result.failureKind!),
    );
    return result;
  }

  bool isCurrentActionResult(CartActionResult result) =>
      !_disposed &&
      result.generation == _generation &&
      result.shopSlug == _shopSlug &&
      result.shopSlug == ref.read(appConfigProvider).storefrontShopSlug &&
      result.subjectId == ref.read(customerAccountIdentityProvider)?.subjectId;

  CartFailureKind? get _pendingFailure =>
      _pendingMutation?.failureKind ??
      _pendingMerge?.failureKind ??
      _pendingRevalidation?.failureKind;

  CartActionResult _result(
    _CartInvocationContext context,
    CartActionOutcome outcome, {
    CartFailureKind? failure,
  }) => CartActionResult(
    outcome: outcome,
    generation: context.generation,
    shopSlug: context.shopSlug,
    subjectId: context.subjectId,
    failureKind: failure,
  );

  void _recordAddOutcome({
    required DateTime occurredAt,
    required int quantity,
    required ObservabilityOutcome outcome,
    BackendFailureCategory? failure,
  }) {
    recordObservabilityFromRefBestEffort(
      ref,
      () => ObservabilityEvent.addToCartOutcome(
        occurredAt: occurredAt,
        outcome: outcome,
        quantity: quantityBucket(quantity),
        failure: failure,
      ),
    );
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
    final context = _captureContext(generation: generation);
    if (context == null || !_isCurrentContext(context)) return;
    final shopSlug = context.shopSlug;
    final authenticated = context.subjectId != null;
    final previous = preserveData && state.snapshot?.shopSlug == shopSlug
        ? state.snapshot
        : null;
    _publish(
      CartState.loading(isAuthenticated: authenticated, previous: previous),
    );
    CustomerCartSnapshot guest;
    try {
      guest = await ref.read(guestCartStoreProvider).read(shopSlug: shopSlug);
    } on CartRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(error.kind, generation: generation, previous: previous);
      return;
    }
    if (!_isCurrentContext(context)) return;
    if (!authenticated) {
      _pendingMerge = null;
      _setReady(guest, generation: generation);
      return;
    }
    try {
      final remote = await ref
          .read(customerCartRepositoryProvider)
          .read(shopSlug: shopSlug);
      if (!_isCurrentContext(context)) return;
      final snapshot = remote.snapshot;
      if (snapshot == null ||
          snapshot.shopSlug != shopSlug ||
          snapshot.source != CartSource.account) {
        throw const FormatException('cart_read_snapshot');
      }
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
        context: context,
        allowConflictRetry: true,
      );
    } on CartRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _setFailure(
        error.kind,
        generation: generation,
        previous: previous ?? guest,
        hasPendingRetry: _pendingMerge != null,
      );
    } on Object {
      if (!_isCurrentContext(context)) return;
      _setFailure(
        CartFailureKind.unexpected,
        generation: generation,
        previous: previous ?? guest,
      );
    }
  }

  Future<void> _executeMerge(
    _PendingMerge pending, {
    required CustomerCartSnapshot fallbackSnapshot,
    required _CartInvocationContext context,
    required bool allowConflictRetry,
  }) async {
    if (!_isCurrentContext(context)) return;
    try {
      final response = await ref
          .read(customerCartRepositoryProvider)
          .mergeGuest(
            shopSlug: context.shopSlug,
            guestItems: pending.items,
            expectedVersion: pending.expectedVersion,
            idempotencyKey: pending.idempotencyKey,
          );
      if (!_isCurrentContext(context)) return;
      final remote = response.snapshot;
      if (remote == null ||
          remote.shopSlug != context.shopSlug ||
          remote.source != CartSource.account) {
        throw const FormatException('cart_merge_snapshot');
      }
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
          context: context,
          allowConflictRetry: false,
        );
        return;
      }
      var current = remote;
      if (remote.idempotent) {
        // Il ledger riconferma l'intent, ma il suo snapshot può precedere un
        // ordine o un edit di un altro dispositivo. La read non avvia un merge.
        final readback = await _readCurrentAccount(
          context,
          minimumVersion: remote.version,
        );
        if (readback == null) return;
        current = readback;
      }
      final rejected = response.rejectedPublicationIds.toSet();
      final retained = await ref
          .read(guestCartStoreProvider)
          .retainOnly(shopSlug: context.shopSlug, publicationIds: rejected);
      if (!_isCurrentContext(context)) return;
      _pendingMerge = null;
      _setReady(
        current.withGuestRetained(retained.items),
        generation: context.generation,
        notice: rejected.isEmpty
            ? CartNoticeKind.merged
            : CartNoticeKind.partialMerge,
      );
    } on CartRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      pending.failureKind = error.kind;
      _setFailure(
        error.kind,
        generation: context.generation,
        previous: fallbackSnapshot.withGuestRetained(pending.items),
        hasPendingRetry: true,
      );
    }
  }

  Future<CartActionResult> _runMutation({
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
    return _executeMutation(
      pending,
      context: context,
      allowConflictRetry: true,
    );
  }

  Future<CartActionResult> _executeMutation(
    _PendingMutation pending, {
    required _CartInvocationContext context,
    required bool allowConflictRetry,
    bool readCurrentBeforeCompletion = false,
  }) async {
    if (!_isCurrentContext(context)) {
      return _result(context, CartActionOutcome.contextChanged);
    }
    try {
      final response = await ref
          .read(customerCartRepositoryProvider)
          .mutate(pending.request);
      if (!_isCurrentContext(context)) {
        return _result(context, CartActionOutcome.contextChanged);
      }
      final snapshot = response.snapshot;
      if (snapshot == null ||
          snapshot.shopSlug != context.shopSlug ||
          snapshot.source != CartSource.account) {
        throw const CartRepositoryException(CartFailureKind.unexpected);
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
        return _executeMutation(
          retry,
          context: context,
          allowConflictRetry: false,
          readCurrentBeforeCompletion: readCurrentBeforeCompletion,
        );
      }
      final rejected = response.status == CartRemoteStatus.unavailable ||
          response.status == CartRemoteStatus.limitReached;
      if (!rejected &&
          (response.status != CartRemoteStatus.ok ||
              (pending.request.operation == CartMutationOperation.set &&
              !snapshot.items.any(
                (line) =>
                    line.publicationId == pending.request.publicationId &&
                    line.quantity == pending.request.quantity &&
                    line.isAvailable,
              )))) {
        throw const CartRepositoryException(CartFailureKind.unexpected);
      }
      var current = snapshot;
      if (readCurrentBeforeCompletion || snapshot.idempotent) {
        // Il retry riconferma l'intent ma non rende corrente l'ACK del ledger.
        // Tenere il pending fino alla read evita nuovi add su quantità storiche.
        final readback = await _readCurrentAccount(
          context,
          minimumVersion: snapshot.version,
        );
        if (readback == null) {
          return _result(context, CartActionOutcome.contextChanged);
        }
        current = readback;
      }
      if (rejected) {
        _pendingMutation = null;
        final failure = response.status == CartRemoteStatus.unavailable
            ? CartFailureKind.unavailable
            : CartFailureKind.limitReached;
        _setReady(
          current,
          notice: failure == CartFailureKind.unavailable
              ? CartNoticeKind.unavailable
              : CartNoticeKind.limitReached,
        );
        return _result(context, CartActionOutcome.rejected, failure: failure);
      }
      _pendingMutation = null;
      // AddToCartButton riceve il risultato direttamente: nessun listener può
      // cancellare l'ACK leggendo/azzerando una notice condivisa.
      _setReady(
        current,
        notice: pending.notice == CartNoticeKind.added ? null : pending.notice,
      );
      return _result(context, CartActionOutcome.accountConfirmed);
    } on Object catch (error) {
      if (!_isCurrentContext(context)) {
        return _result(context, CartActionOutcome.contextChanged);
      }
      final failure = error is CartRepositoryException
          ? error.kind
          : CartFailureKind.unexpected;
      pending.failureKind = failure;
      _setFailure(failure, previous: state.snapshot, hasPendingRetry: true);
      return _result(
        context,
        CartActionOutcome.pendingConfirmation,
        failure: failure,
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
    await _executeMutation(
      pending,
      context: context,
      allowConflictRetry: true,
      readCurrentBeforeCompletion: true,
    );
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
      var current = snapshot;
      if (snapshot.idempotent) {
        final readback = await _readCurrentAccount(
          context,
          minimumVersion: snapshot.version,
        );
        if (readback == null) return;
        current = readback;
      }
      _pendingRevalidation = null;
      _setReady(current, notice: CartNoticeKind.revalidated);
    } on CartRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      pending.failureKind = error.kind;
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

  Future<CustomerCartSnapshot?> _readCurrentAccount(
    _CartInvocationContext context, {
    required int minimumVersion,
  }) async {
    if (!_isCurrentContext(context)) return null;
    final response = await ref
        .read(customerCartRepositoryProvider)
        .read(shopSlug: context.shopSlug);
    if (!_isCurrentContext(context)) return null;
    final snapshot = response.snapshot;
    if (response.status != CartRemoteStatus.ok ||
        snapshot == null ||
        snapshot.shopSlug != context.shopSlug ||
        snapshot.source != CartSource.account ||
        snapshot.version < minimumVersion) {
      throw const CartRepositoryException(CartFailureKind.unexpected);
    }
    return snapshot;
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
      final pendingFailure = _pendingFailure;
      if (pendingFailure != null) {
        _setFailure(
          pendingFailure,
          previous: state.snapshot,
          hasPendingRetry: true,
        );
        return;
      }
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
      final pendingFailure = _pendingFailure;
      if (pendingFailure != null) {
        _setFailure(
          pendingFailure,
          previous: state.snapshot,
          hasPendingRetry: true,
        );
        return;
      }
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

  Future<T> _serialize<T>(Future<T> Function() action) {
    final previous = _operation;
    final next = (() async {
      if (previous != null) await previous;
      return action();
    })();
    // La coda attende anche gli errori senza trasferirli alla richiesta seguente.
    late final Future<void> tail;
    tail = next
        .then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .whenComplete(() {
          if (identical(_operation, tail)) _operation = null;
        });
    _operation = tail;
    return next;
  }

  CustomerCartSnapshot _requireSnapshot() {
    final snapshot = state.snapshot;
    if (snapshot == null) {
      throw const CartRepositoryException(CartFailureKind.unavailable);
    }
    return snapshot;
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
        ref.read(appConfigProvider).storefrontShopSlug == context.shopSlug &&
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
  CartFailureKind failureKind = CartFailureKind.timeout;
}

final class _PendingMutation {
  _PendingMutation({required this.request, required this.notice});

  final CartMutationRequest request;
  final CartNoticeKind notice;
  CartFailureKind failureKind = CartFailureKind.timeout;
}

final class _PendingRevalidation {
  _PendingRevalidation({
    required this.expectedVersion,
    required this.idempotencyKey,
  });

  final int expectedVersion;
  final String idempotencyKey;
  CartFailureKind failureKind = CartFailureKind.timeout;
}

BackendFailureCategory _cartFailureCategory(CartFailureKind kind) =>
    switch (kind) {
      CartFailureKind.offline => BackendFailureCategory.offline,
      CartFailureKind.timeout => BackendFailureCategory.timeout,
      CartFailureKind.unauthorized => BackendFailureCategory.unauthorized,
      CartFailureKind.invalidInput ||
      CartFailureKind.limitReached => BackendFailureCategory.invalidInput,
      CartFailureKind.conflict => BackendFailureCategory.conflict,
      CartFailureKind.unavailable => BackendFailureCategory.unavailable,
      CartFailureKind.unexpected => BackendFailureCategory.unexpected,
    };
