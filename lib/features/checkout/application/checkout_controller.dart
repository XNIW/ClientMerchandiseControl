import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/observability/observability_event.dart';
import '../../../core/observability/observability_providers.dart';
import '../../../core/time/app_scheduler.dart';
import '../../account/application/customer_account_providers.dart';
import '../../account/domain/customer_account_models.dart';
import '../../cart/domain/cart_models.dart';
import '../domain/checkout_failure.dart';
import '../domain/checkout_models.dart';
import 'checkout_providers.dart';
import 'checkout_state.dart';

final checkoutControllerProvider =
    NotifierProvider<CheckoutController, CheckoutState>(CheckoutController.new);

final class CheckoutController extends Notifier<CheckoutState> {
  CheckoutState? _lastState;
  String? _contextKey;
  String? _ownerSubjectId;
  String? _shopSlug;
  Future<void>? _operation;
  var _generation = 0;
  var _disposed = false;

  @override
  CheckoutState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _generation++;
    });
    final config = ref.watch(appConfigProvider);
    final identity = ref.watch(customerAccountIdentityProvider);
    final cartState = ref.watch(checkoutCartStateProvider);
    final accountState = ref.watch(checkoutAccountStateProvider);
    final shopSlug = config.storefrontShopSlug;
    final cart = cartState.snapshot;

    if (shopSlug == null) {
      return _remember(
        CheckoutState.failure(
          failureKind: CheckoutFailureKind.invalidInput,
          cart: cart,
        ),
      );
    }
    if (cart == null) {
      return _remember(CheckoutState.loading());
    }
    if (cart.isEmpty && identity == null) {
      return _remember(
        CheckoutState.failure(
          failureKind: CheckoutFailureKind.cartUnavailable,
          cart: cart,
        ),
      );
    }
    if (identity == null) {
      _ownerSubjectId = null;
      _shopSlug = shopSlug;
      _contextKey = '$shopSlug|guest|${cart.version}';
      return _remember(CheckoutState.authRequired(cart));
    }
    if (cart.source != CartSource.account) {
      return _remember(CheckoutState.loading(cart: cart));
    }
    _ownerSubjectId = identity.subjectId;
    _shopSlug = shopSlug;
    if (cart.isEmpty) {
      final rememberedOrder = _lastState?.order;
      if (rememberedOrder != null &&
          rememberedOrder.shopSlug == shopSlug &&
          (_contextKey?.startsWith('$shopSlug|${identity.subjectId}|') ??
              false)) {
        return _lastState!;
      }
      final nextContext =
          '$shopSlug|${identity.subjectId}|receipt|${cart.version}';
      if (_contextKey == nextContext && _lastState != null) {
        return _lastState!;
      }
      _contextKey = nextContext;
      final loading = CheckoutState.loading(cart: cart);
      _lastState = loading;
      final generation = ++_generation;
      scheduleMicrotask(() => _loadReceipt(generation, cart: cart));
      return loading;
    }
    if (cart.unavailableItemCount > 0) {
      return _remember(
        CheckoutState.failure(
          failureKind: CheckoutFailureKind.cartUnavailable,
          cart: cart,
        ),
      );
    }
    final accountSnapshot = accountState.snapshot;
    if (accountSnapshot == null) {
      return _remember(CheckoutState.loading(cart: cart));
    }
    final addresses = accountSnapshot.addresses;
    final addressRevision = [
      for (final address in addresses) '${address.id}:${address.updatedAt}',
    ].join('|');
    final nextContext =
        '$shopSlug|${identity.subjectId}|${cart.version}|$addressRevision';
    if (_contextKey == nextContext && _lastState != null) {
      return _lastState!;
    }
    _contextKey = nextContext;
    final loading = CheckoutState.loading(
      cart: cart,
    ).copyWith(addresses: addresses);
    _lastState = loading;
    final generation = ++_generation;
    scheduleMicrotask(
      () => _load(
        generation,
        cart: cart,
        addresses: addresses,
        restoreNotice: true,
      ),
    );
    return loading;
  }

  Future<void> retry() {
    final context = _captureContext();
    if (context == null) return Future<void>.value();
    return _serialize(() async {
      if (!_isCurrentContext(context)) return;
      final pending = state.pendingOperation;
      if (pending != null) {
        switch (pending.kind) {
          case CheckoutPendingOperationKind.create:
            await _executeCreate(pending, context);
          case CheckoutPendingOperationKind.confirm:
            await _executeConfirm(pending, context);
          case CheckoutPendingOperationKind.order:
            await _executeOrder(pending, context);
        }
        return;
      }
      if (state.failureKind == CheckoutFailureKind.staleCart ||
          state.failureKind == CheckoutFailureKind.cartUnavailable) {
        await ref.read(checkoutCartRefreshProvider)();
        return;
      }
      final cart = state.cart;
      if (cart == null) return;
      await _load(
        ++_generation,
        cart: cart,
        addresses: state.addresses,
        restoreNotice: false,
      );
    });
  }

  Future<void> selectMode(CheckoutFulfillmentMode mode) async {
    final options = state.options;
    if (state.isBusy || options == null || !options.isEnabled(mode)) return;
    await _replaceDraftState(
      state.copyWith(
        selection: CheckoutSelection(mode: mode),
        quote: null,
        pendingOperation: null,
        failureKind: null,
        notice: null,
      ),
    );
  }

  Future<void> selectPickupPoint(String pointId) async {
    final options = state.options;
    final mode = state.selection.mode;
    if (state.isBusy ||
        options?.pickupPoint(pointId) == null ||
        (mode != CheckoutFulfillmentMode.pickup &&
            mode != CheckoutFulfillmentMode.reservation)) {
      return;
    }
    await _replaceDraftState(
      state.copyWith(
        selection: CheckoutSelection(mode: mode, pickupPointId: pointId),
        quote: null,
        pendingOperation: null,
        failureKind: null,
        notice: null,
      ),
    );
  }

  Future<void> selectAddress(String addressId) async {
    if (state.isBusy ||
        state.selection.mode != CheckoutFulfillmentMode.delivery ||
        !state.addresses.any((address) => address.id == addressId)) {
      return;
    }
    final next = state.copyWith(
      selection: CheckoutSelection(
        mode: CheckoutFulfillmentMode.delivery,
        addressId: addressId,
      ),
      quote: null,
      pendingOperation: null,
      failureKind: null,
      notice: null,
    );
    await _replaceDraftState(next);
  }

  Future<void> selectSlot(String slotId) async {
    if (state.isBusy ||
        !state.selectableSlots.any((slot) => slot.id == slotId)) {
      return;
    }
    await _replaceDraftState(
      state.copyWith(
        selection: state.selection.copyWith(slotId: slotId),
        quote: null,
        pendingOperation: null,
        failureKind: null,
        notice: null,
      ),
    );
  }

  Future<void> selectPaymentMethod(CheckoutPaymentMethod method) async {
    final mode = state.selection.mode;
    if (state.isBusy ||
        state.pendingOperation != null ||
        mode == null ||
        !(state.paymentOptions?.isEnabled(method, mode) ?? false)) {
      return;
    }
    await _replaceDraftState(
      state.copyWith(
        selection: state.selection.copyWith(paymentMethod: method),
        quote: null,
        order: null,
        failureKind: null,
        notice: null,
      ),
    );
  }

  Future<void> nextStep() async {
    if (state.isBusy) return;
    final next = switch (state.step) {
      CheckoutStep.mode when state.selection.mode != null =>
        CheckoutStep.destination,
      CheckoutStep.destination when _hasDestination(state) => CheckoutStep.slot,
      CheckoutStep.slot when state.selection.slotId != null =>
        CheckoutStep.review,
      _ => null,
    };
    if (next == null) return;
    await _replaceDraftState(
      state.copyWith(step: next, failureKind: null, notice: null),
    );
  }

  Future<void> previousStep() async {
    if (state.isBusy || state.hasOrder) return;
    final previous = switch (state.step) {
      CheckoutStep.mode => null,
      CheckoutStep.destination => CheckoutStep.mode,
      CheckoutStep.slot => CheckoutStep.destination,
      CheckoutStep.review => CheckoutStep.slot,
      CheckoutStep.confirmation => CheckoutStep.review,
    };
    if (previous == null) return;
    await _replaceDraftState(
      state.copyWith(step: previous, failureKind: null, notice: null),
    );
  }

  Future<void> createQuote() {
    final context = _captureContext();
    if (context == null) return Future<void>.value();
    return _serialize(() async {
      if (!_isCurrentContext(context)) return;
      final cart = state.cart;
      if (cart == null || !_selectionComplete(state)) return;
      final existing = state.pendingOperation;
      final pending =
          existing?.kind == CheckoutPendingOperationKind.create &&
              existing?.cartVersion == cart.version
          ? existing!
          : CheckoutPendingOperation(
              kind: CheckoutPendingOperationKind.create,
              idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
              cartVersion: cart.version,
            );
      final pendingState = state.copyWith(
        pendingOperation: pending,
        failureKind: null,
        notice: null,
      );
      if (!await _persist(pendingState, context: context)) return;
      _publish(pendingState);
      await _executeCreate(pending, context);
    });
  }

  Future<void> confirmQuote() {
    final context = _captureContext();
    if (context == null) return Future<void>.value();
    return _serialize(() async {
      if (!_isCurrentContext(context)) return;
      final quote = state.quote;
      final cart = state.cart;
      if (quote == null || cart == null || quote.isExpired) return;
      final existing = state.pendingOperation;
      final pending =
          existing?.kind == CheckoutPendingOperationKind.confirm &&
              existing?.quoteId == quote.id &&
              existing?.expectedQuoteVersion == quote.quoteVersion
          ? existing!
          : CheckoutPendingOperation(
              kind: CheckoutPendingOperationKind.confirm,
              idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
              cartVersion: cart.version,
              quoteId: quote.id,
              expectedQuoteVersion: quote.quoteVersion,
            );
      final pendingState = state.copyWith(
        pendingOperation: pending,
        failureKind: null,
        notice: null,
      );
      if (!await _persist(pendingState, context: context)) return;
      _publish(pendingState);
      await _executeConfirm(pending, context);
    });
  }

  Future<void> createOrder() {
    final context = _captureContext();
    if (context == null) return Future<void>.value();
    return _serialize(() async {
      if (!_isCurrentContext(context)) return;
      final quote = state.quote;
      final cart = state.cart;
      if (quote == null ||
          cart == null ||
          !quote.isConfirmed ||
          !state.hasValidPaymentSelection ||
          state.hasOrder) {
        return;
      }
      final existing = state.pendingOperation;
      final pending =
          existing?.kind == CheckoutPendingOperationKind.order &&
              existing?.quoteId == quote.id &&
              existing?.expectedQuoteVersion == quote.quoteVersion &&
              existing?.paymentMethod == state.selection.paymentMethod
          ? existing!
          : CheckoutPendingOperation(
              kind: CheckoutPendingOperationKind.order,
              idempotencyKey: ref.read(customerIdempotencyKeyFactoryProvider)(),
              cartVersion: cart.version,
              quoteId: quote.id,
              expectedQuoteVersion: quote.quoteVersion,
              paymentMethod: state.selection.paymentMethod,
            );
      final pendingState = state.copyWith(
        pendingOperation: pending,
        failureKind: null,
        notice: null,
      );
      if (!await _persist(pendingState, context: context)) return;
      _publish(pendingState);
      await _executeOrder(pending, context);
    });
  }

  Future<void> restart() {
    final context = _captureContext();
    if (context == null) return Future<void>.value();
    return _serialize(() async {
      if (!_isCurrentContext(context)) return;
      try {
        await ref
            .read(checkoutDraftStoreProvider)
            .clear(
              ownerSubjectId: context.ownerSubjectId,
              shopSlug: context.shopSlug,
            );
        if (!_isCurrentContext(context)) return;
        _publish(
          state.copyWith(
            step: CheckoutStep.mode,
            selection: const CheckoutSelection(),
            quote: null,
            order: null,
            pendingOperation: null,
            failureKind: null,
            notice: null,
          ),
        );
      } on Object {
        if (!_isCurrentContext(context)) return;
        _publish(
          state.copyWith(
            failureKind: CheckoutFailureKind.unexpected,
            isBusy: false,
          ),
        );
      }
    });
  }

  void clearNotice() {
    _publish(state.copyWith(notice: null));
  }

  Future<void> _load(
    int generation, {
    required CustomerCartSnapshot cart,
    required List<CustomerAddress> addresses,
    required bool restoreNotice,
  }) async {
    final owner = _ownerSubjectId;
    final shop = _shopSlug;
    if (owner == null || shop == null) return;
    final context = _CheckoutContext(
      ownerSubjectId: owner,
      shopSlug: shop,
      generation: generation,
    );
    _publish(CheckoutState.loading(cart: cart).copyWith(addresses: addresses));
    try {
      final results = await Future.wait<Object?>([
        ref.read(checkoutRepositoryProvider).loadOptions(shopSlug: shop),
        ref.read(checkoutRepositoryProvider).loadPaymentOptions(shopSlug: shop),
        ref
            .read(checkoutDraftStoreProvider)
            .read(ownerSubjectId: owner, shopSlug: shop),
      ]);
      if (!_isCurrentContext(context)) return;
      final options = results[0]! as StorefrontFulfillmentOptions;
      final paymentOptions = results[1]! as StorefrontPaymentOptions;
      final draft = results[2] as CheckoutLocalDraft?;
      if (draft?.orderId != null) {
        final response = await ref
            .read(checkoutRepositoryProvider)
            .readOrder(shopSlug: shop, orderId: draft!.orderId!);
        if (!_isCurrentContext(context)) return;
        final order = response.order;
        if (response.status == CheckoutOrderRemoteStatus.ok && order != null) {
          final receipt = CheckoutState(
            status: CheckoutViewStatus.ready,
            step: CheckoutStep.confirmation,
            selection: draft.selection,
            addresses: addresses,
            cart: cart,
            options: options,
            paymentOptions: paymentOptions,
            order: order,
            notice: restoreNotice ? CheckoutNoticeKind.restored : null,
          );
          if (!await _persist(receipt, context: context)) return;
          _publish(receipt);
          return;
        }
      }
      if (options.status != FulfillmentOptionsStatus.ok ||
          !options.modes.any((mode) => mode.enabled) ||
          paymentOptions.status != PaymentOptionsStatus.ok ||
          !paymentOptions.methods.any((method) => method.enabled)) {
        _publish(
          CheckoutState.failure(
            failureKind: CheckoutFailureKind.unavailable,
            cart: cart,
          ),
        );
        return;
      }
      final selection = _sanitizeSelection(
        draft?.selection ?? const CheckoutSelection(),
        options,
        paymentOptions,
        addresses,
      );
      CheckoutQuote? quote;
      CheckoutFailureKind? restoreFailure;
      if (draft?.quoteId != null) {
        try {
          final response = await ref
              .read(checkoutRepositoryProvider)
              .readQuote(
                shopSlug: shop,
                cartVersion: cart.version,
                quoteId: draft!.quoteId!,
              );
          if (!_isCurrentContext(context)) return;
          quote = response.quote;
          if (quote == null) {
            restoreFailure = _failureFor(response.status);
          } else if (quote.cartVersion != cart.version) {
            quote = null;
            restoreFailure = CheckoutFailureKind.staleCart;
          } else if (quote.isExpired) {
            restoreFailure = CheckoutFailureKind.expired;
          }
        } on CheckoutRepositoryException catch (error) {
          restoreFailure = error.kind;
        }
      }
      final step = _sanitizeStep(
        draft?.step ?? CheckoutStep.mode,
        selection,
        quote,
      );
      final pendingOperation = _sanitizePendingOperation(
        draft?.pendingOperation,
        cartVersion: cart.version,
        selection: selection,
        quote: quote,
      );
      final ready = CheckoutState(
        status: CheckoutViewStatus.ready,
        step: step,
        selection: selection,
        addresses: addresses,
        cart: cart,
        options: options,
        paymentOptions: paymentOptions,
        quote: quote,
        pendingOperation: pendingOperation,
        failureKind: restoreFailure,
        notice: restoreNotice && draft != null
            ? CheckoutNoticeKind.restored
            : null,
      );
      if (!await _persist(ready, context: context)) return;
      _publish(ready);
    } on CheckoutRepositoryException catch (error) {
      if (_isCurrentContext(context)) {
        _publish(CheckoutState.failure(failureKind: error.kind, cart: cart));
      }
    } on Object {
      if (_isCurrentContext(context)) {
        _publish(
          CheckoutState.failure(
            failureKind: CheckoutFailureKind.unexpected,
            cart: cart,
          ),
        );
      }
    }
  }

  Future<void> _loadReceipt(
    int generation, {
    required CustomerCartSnapshot cart,
  }) async {
    final owner = _ownerSubjectId;
    final shop = _shopSlug;
    if (owner == null || shop == null) return;
    final context = _CheckoutContext(
      ownerSubjectId: owner,
      shopSlug: shop,
      generation: generation,
    );
    try {
      final draft = await ref
          .read(checkoutDraftStoreProvider)
          .read(ownerSubjectId: owner, shopSlug: shop);
      if (!_isCurrentContext(context)) return;
      if (draft?.orderId case final String orderId) {
        final response = await ref
            .read(checkoutRepositoryProvider)
            .readOrder(shopSlug: shop, orderId: orderId);
        if (!_isCurrentContext(context)) return;
        final order = response.order;
        if (response.status == CheckoutOrderRemoteStatus.ok && order != null) {
          final receipt = CheckoutState(
            status: CheckoutViewStatus.ready,
            step: CheckoutStep.confirmation,
            selection: draft!.selection,
            addresses: const [],
            cart: cart,
            order: order,
            notice: CheckoutNoticeKind.restored,
          );
          if (!await _persist(receipt, context: context)) return;
          _publish(receipt);
          return;
        }
      }
      final pending = draft?.pendingOperation;
      if (pending?.kind == CheckoutPendingOperationKind.order &&
          pending?.paymentMethod != null &&
          pending?.paymentMethod == draft?.selection.paymentMethod) {
        final recovery = CheckoutState(
          status: CheckoutViewStatus.ready,
          step: CheckoutStep.confirmation,
          selection: draft!.selection,
          addresses: const [],
          cart: cart,
          pendingOperation: pending,
          failureKind: CheckoutFailureKind.timeout,
          notice: CheckoutNoticeKind.restored,
        );
        _publish(recovery);
        await _executeOrder(pending!, context);
        return;
      }
      _publish(
        CheckoutState.failure(
          failureKind: CheckoutFailureKind.cartUnavailable,
          cart: cart,
        ),
      );
    } on CheckoutRepositoryException catch (error) {
      if (_isCurrentContext(context)) {
        _publish(CheckoutState.failure(failureKind: error.kind, cart: cart));
      }
    } on Object {
      if (_isCurrentContext(context)) {
        _publish(
          CheckoutState.failure(
            failureKind: CheckoutFailureKind.unexpected,
            cart: cart,
          ),
        );
      }
    }
  }

  Future<void> _executeCreate(
    CheckoutPendingOperation pending,
    _CheckoutContext context,
  ) async {
    if (!_isCurrentContext(context)) return;
    final shop = context.shopSlug;
    _publish(state.copyWith(isBusy: true, failureKind: null, notice: null));
    try {
      final response = await ref
          .read(checkoutRepositoryProvider)
          .createQuote(
            CheckoutQuoteCreateRequest(
              shopSlug: shop,
              cartVersion: pending.cartVersion,
              selection: state.selection,
              idempotencyKey: pending.idempotencyKey,
            ),
          );
      if (!_isCurrentContext(context)) return;
      final quote = response.quote;
      if (quote != null &&
          const {
            CheckoutRemoteStatus.quoted,
            CheckoutRemoteStatus.requiresReview,
            CheckoutRemoteStatus.confirmed,
          }.contains(response.status)) {
        final ready = state.copyWith(
          status: CheckoutViewStatus.ready,
          step: CheckoutStep.confirmation,
          quote: quote,
          pendingOperation: null,
          failureKind: null,
          notice: quote.requiresCustomerReview
              ? CheckoutNoticeKind.quoteChanged
              : null,
          isBusy: false,
        );
        await _persistAndPublish(ready, context);
        return;
      }
      await _publishDeterministicFailure(
        response,
        context: context,
        quote: quote,
      );
    } on CheckoutRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _publish(
        state.copyWith(
          failureKind: error.kind,
          isBusy: false,
          pendingOperation:
              error.kind == CheckoutFailureKind.timeout ||
                  error.kind == CheckoutFailureKind.offline
              ? pending
              : null,
        ),
      );
    }
  }

  Future<void> _executeConfirm(
    CheckoutPendingOperation pending,
    _CheckoutContext context,
  ) async {
    if (!_isCurrentContext(context)) return;
    final quoteId = pending.quoteId;
    final expectedVersion = pending.expectedQuoteVersion;
    if (quoteId == null || expectedVersion == null) return;
    _publish(state.copyWith(isBusy: true, failureKind: null, notice: null));
    try {
      final response = await ref
          .read(checkoutRepositoryProvider)
          .confirmQuote(
            shopSlug: context.shopSlug,
            cartVersion: pending.cartVersion,
            quoteId: quoteId,
            expectedQuoteVersion: expectedVersion,
            idempotencyKey: pending.idempotencyKey,
          );
      if (!_isCurrentContext(context)) return;
      final quote = response.quote;
      if (response.status == CheckoutRemoteStatus.confirmed && quote != null) {
        final confirmed = state.copyWith(
          quote: quote,
          pendingOperation: null,
          failureKind: null,
          notice: CheckoutNoticeKind.confirmed,
          isBusy: false,
        );
        await _persistAndPublish(confirmed, context);
        return;
      }
      if (response.status == CheckoutRemoteStatus.requiresReview &&
          quote != null) {
        final changed = state.copyWith(
          quote: quote,
          pendingOperation: null,
          failureKind: null,
          notice: CheckoutNoticeKind.quoteChanged,
          isBusy: false,
        );
        await _persistAndPublish(changed, context);
        return;
      }
      await _publishDeterministicFailure(
        response,
        context: context,
        quote: quote,
      );
    } on CheckoutRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _publish(
        state.copyWith(
          failureKind: error.kind,
          isBusy: false,
          pendingOperation:
              error.kind == CheckoutFailureKind.timeout ||
                  error.kind == CheckoutFailureKind.offline
              ? pending
              : null,
        ),
      );
    }
  }

  Future<void> _executeOrder(
    CheckoutPendingOperation pending,
    _CheckoutContext context,
  ) async {
    if (!_isCurrentContext(context)) return;
    final quoteId = pending.quoteId;
    final expectedVersion = pending.expectedQuoteVersion;
    final paymentMethod = pending.paymentMethod;
    if (quoteId == null || expectedVersion == null || paymentMethod == null) {
      _publish(
        state.copyWith(
          pendingOperation: null,
          failureKind: CheckoutFailureKind.paymentUnavailable,
          isBusy: false,
        ),
      );
      return;
    }
    _publish(state.copyWith(isBusy: true, failureKind: null, notice: null));
    try {
      final response = await ref
          .read(checkoutRepositoryProvider)
          .createOrder(
            shopSlug: context.shopSlug,
            cartVersion: pending.cartVersion,
            quoteId: quoteId,
            expectedQuoteVersion: expectedVersion,
            paymentMethod: paymentMethod,
            idempotencyKey: pending.idempotencyKey,
          );
      if (!_isCurrentContext(context)) return;
      final order = response.order;
      if (response.status == CheckoutOrderRemoteStatus.ok && order != null) {
        final receipt = state.copyWith(
          status: CheckoutViewStatus.ready,
          step: CheckoutStep.confirmation,
          order: order,
          pendingOperation: null,
          failureKind: null,
          notice: CheckoutNoticeKind.orderConfirmed,
          isBusy: false,
        );
        await _persistAndPublish(receipt, context);
        if (!_isCurrentContext(context)) return;
        await ref.read(checkoutCartRefreshProvider)();
        return;
      }
      if (response.status == CheckoutOrderRemoteStatus.requiresReview) {
        final quoteResponse = await ref
            .read(checkoutRepositoryProvider)
            .readQuote(
              shopSlug: context.shopSlug,
              cartVersion: pending.cartVersion,
              quoteId: quoteId,
            );
        if (!_isCurrentContext(context)) return;
        final quote = quoteResponse.quote;
        final changed = state.copyWith(
          quote: quote,
          order: null,
          pendingOperation: null,
          failureKind: quote == null ? CheckoutFailureKind.staleCart : null,
          notice: quote == null ? null : CheckoutNoticeKind.quoteChanged,
          isBusy: false,
        );
        await _persistAndPublish(changed, context);
        return;
      }
      await _publishOrderDeterministicFailure(response, context);
    } on CheckoutRepositoryException catch (error) {
      if (!_isCurrentContext(context)) return;
      _publish(
        state.copyWith(
          failureKind: error.kind,
          isBusy: false,
          pendingOperation:
              error.kind == CheckoutFailureKind.timeout ||
                  error.kind == CheckoutFailureKind.offline
              ? pending
              : null,
        ),
      );
    }
  }

  Future<void> _publishOrderDeterministicFailure(
    CheckoutOrderRemoteResponse response,
    _CheckoutContext context,
  ) async {
    if (!_isCurrentContext(context)) return;
    final failure = _failureForOrder(response.status);
    final next = state.copyWith(
      order: null,
      pendingOperation: null,
      failureKind: failure,
      isBusy: false,
    );
    await _persistAndPublish(next, context);
    if (!_isCurrentContext(context)) return;
    if (failure == CheckoutFailureKind.staleCart ||
        failure == CheckoutFailureKind.cartUnavailable) {
      await ref.read(checkoutCartRefreshProvider)();
    }
  }

  Future<void> _publishDeterministicFailure(
    CheckoutRemoteResponse response, {
    required _CheckoutContext context,
    CheckoutQuote? quote,
  }) async {
    if (!_isCurrentContext(context)) return;
    final failure = _failureFor(response.status);
    final next = state.copyWith(
      quote: quote,
      pendingOperation: null,
      failureKind: failure,
      isBusy: false,
    );
    await _persistAndPublish(next, context);
    if (!_isCurrentContext(context)) return;
    if (failure == CheckoutFailureKind.staleCart) {
      await ref.read(checkoutCartRefreshProvider)();
    }
  }

  Future<void> _replaceDraftState(CheckoutState next) async {
    final context = _captureContext();
    if (context != null && await _persist(next, context: context)) {
      _publish(next);
    }
  }

  Future<void> _persistAndPublish(
    CheckoutState next,
    _CheckoutContext context,
  ) async {
    if (await _persist(next, context: context)) _publish(next);
  }

  Future<bool> _persist(
    CheckoutState value, {
    required _CheckoutContext context,
  }) async {
    if (!_isCurrentContext(context)) return false;
    try {
      await ref
          .read(checkoutDraftStoreProvider)
          .save(
            CheckoutLocalDraft(
              ownerSubjectId: context.ownerSubjectId,
              shopSlug: context.shopSlug,
              step: value.step,
              selection: value.selection,
              quoteId: value.quote?.id,
              orderId: value.order?.id,
              pendingOperation: value.pendingOperation,
              updatedAt: ref.read(checkoutClockProvider)(),
            ),
          );
      return _isCurrentContext(context);
    } on Object {
      if (!_isCurrentContext(context)) return false;
      _publish(
        value.copyWith(
          pendingOperation: null,
          failureKind: CheckoutFailureKind.unexpected,
          isBusy: false,
        ),
      );
      return false;
    }
  }

  Future<void> _serialize(Future<void> Function() action) {
    final active = _operation;
    if (active != null) return active;
    late final Future<void> operation;
    operation = action().whenComplete(() {
      if (identical(_operation, operation)) _operation = null;
    });
    _operation = operation;
    return operation;
  }

  CheckoutState _remember(CheckoutState value) {
    _lastState = value;
    return value;
  }

  void _publish(CheckoutState value) {
    if (_disposed) return;
    final previous = _lastState;
    _lastState = value;
    state = value;
    final failure = value.failureKind;
    final previousSignature = (
      previous?.step,
      previous?.isBusy,
      previous?.failureKind,
      previous?.order != null,
    );
    final nextSignature = (
      value.step,
      value.isBusy,
      value.failureKind,
      value.order != null,
    );
    if (previousSignature != nextSignature) {
      final clock = ref.read(appClockProvider);
      recordObservabilityFromRefBestEffort(
        ref,
        () => ObservabilityEvent.checkoutStep(
          occurredAt: clock(),
          step: _checkoutTelemetryStep(value),
          outcome: failure != null
              ? ObservabilityOutcome.failure
              : value.isBusy
              ? ObservabilityOutcome.pending
              : ObservabilityOutcome.success,
          failure: failure == null ? null : _checkoutFailureCategory(failure),
        ),
      );
      if (previous?.order == null && value.order != null) {
        recordObservabilityFromRefBestEffort(
          ref,
          () => ObservabilityEvent.orderCreated(
            occurredAt: clock(),
            outcome: ObservabilityOutcome.success,
          ),
        );
      } else if (failure != null &&
          previous?.pendingOperation?.kind ==
              CheckoutPendingOperationKind.order) {
        recordObservabilityFromRefBestEffort(
          ref,
          () => ObservabilityEvent.orderCreated(
            occurredAt: clock(),
            outcome: ObservabilityOutcome.failure,
            failure: _checkoutFailureCategory(failure),
          ),
        );
      }
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  _CheckoutContext? _captureContext() {
    final owner = _ownerSubjectId;
    final shop = _shopSlug;
    if (owner == null || shop == null) return null;
    return _CheckoutContext(
      ownerSubjectId: owner,
      shopSlug: shop,
      generation: _generation,
    );
  }

  bool _isCurrentContext(_CheckoutContext context) {
    return _isCurrent(context.generation) &&
        _ownerSubjectId == context.ownerSubjectId &&
        _shopSlug == context.shopSlug;
  }
}

final class _CheckoutContext {
  const _CheckoutContext({
    required this.ownerSubjectId,
    required this.shopSlug,
    required this.generation,
  });

  final String ownerSubjectId;
  final String shopSlug;
  final int generation;
}

CheckoutTelemetryStep _checkoutTelemetryStep(CheckoutState state) =>
    switch (state.step) {
      CheckoutStep.mode => CheckoutTelemetryStep.mode,
      CheckoutStep.destination => CheckoutTelemetryStep.destination,
      CheckoutStep.slot => CheckoutTelemetryStep.slot,
      CheckoutStep.review => CheckoutTelemetryStep.review,
      CheckoutStep.confirmation =>
        state.order == null
            ? CheckoutTelemetryStep.payment
            : CheckoutTelemetryStep.order,
    };

BackendFailureCategory _checkoutFailureCategory(CheckoutFailureKind kind) =>
    switch (kind) {
      CheckoutFailureKind.offline => BackendFailureCategory.offline,
      CheckoutFailureKind.timeout => BackendFailureCategory.timeout,
      CheckoutFailureKind.unauthorized => BackendFailureCategory.unauthorized,
      CheckoutFailureKind.conflict ||
      CheckoutFailureKind.staleCart ||
      CheckoutFailureKind.slotUnavailable ||
      CheckoutFailureKind.expired => BackendFailureCategory.conflict,
      CheckoutFailureKind.invalidInput ||
      CheckoutFailureKind.invalidAddress ||
      CheckoutFailureKind.unsupportedZone ||
      CheckoutFailureKind.cartUnavailable =>
        BackendFailureCategory.invalidInput,
      CheckoutFailureKind.unavailable ||
      CheckoutFailureKind.paymentUnavailable ||
      CheckoutFailureKind.notFound => BackendFailureCategory.unavailable,
      CheckoutFailureKind.unexpected => BackendFailureCategory.unexpected,
    };

CheckoutSelection _sanitizeSelection(
  CheckoutSelection selection,
  StorefrontFulfillmentOptions options,
  StorefrontPaymentOptions paymentOptions,
  List<CustomerAddress> addresses,
) {
  final mode = selection.mode;
  if (mode == null || !options.isEnabled(mode)) {
    return const CheckoutSelection();
  }
  if (mode == CheckoutFulfillmentMode.delivery) {
    final address = addresses
        .where((candidate) => candidate.id == selection.addressId)
        .firstOrNull;
    if (address == null) return CheckoutSelection(mode: mode);
    final supportedZones = options.deliveryZones
        .where((zone) => zone.supports(address))
        .map((zone) => zone.id)
        .toSet();
    final slot = options.slot(selection.slotId);
    final paymentMethod = _sanitizedPaymentMethod(
      selection.paymentMethod,
      mode,
      paymentOptions,
    );
    return CheckoutSelection(
      mode: mode,
      addressId: address.id,
      slotId:
          slot?.mode == mode && supportedZones.contains(slot?.deliveryZoneId)
          ? slot?.id
          : null,
      paymentMethod: paymentMethod,
    );
  }
  final point = options.pickupPoint(selection.pickupPointId);
  if (point == null) return CheckoutSelection(mode: mode);
  final slot = options.slot(selection.slotId);
  final paymentMethod = _sanitizedPaymentMethod(
    selection.paymentMethod,
    mode,
    paymentOptions,
  );
  return CheckoutSelection(
    mode: mode,
    pickupPointId: point.id,
    slotId: slot?.mode == mode && slot?.pickupPointId == point.id
        ? slot?.id
        : null,
    paymentMethod: paymentMethod,
  );
}

CheckoutPaymentMethod? _sanitizedPaymentMethod(
  CheckoutPaymentMethod? method,
  CheckoutFulfillmentMode mode,
  StorefrontPaymentOptions options,
) => method != null && options.isEnabled(method, mode) ? method : null;

CheckoutStep _sanitizeStep(
  CheckoutStep requested,
  CheckoutSelection selection,
  CheckoutQuote? quote,
) {
  if (quote != null) return CheckoutStep.confirmation;
  if (selection.mode == null) return CheckoutStep.mode;
  final hasDestination = selection.mode == CheckoutFulfillmentMode.delivery
      ? selection.addressId != null
      : selection.pickupPointId != null;
  if (!hasDestination) {
    return requested.index > CheckoutStep.destination.index
        ? CheckoutStep.destination
        : requested;
  }
  if (selection.slotId == null) {
    return requested.index > CheckoutStep.slot.index
        ? CheckoutStep.slot
        : requested;
  }
  return requested.index > CheckoutStep.review.index
      ? CheckoutStep.review
      : requested;
}

CheckoutPendingOperation? _sanitizePendingOperation(
  CheckoutPendingOperation? pending, {
  required int cartVersion,
  required CheckoutSelection selection,
  required CheckoutQuote? quote,
}) {
  if (pending == null || pending.cartVersion != cartVersion) return null;
  return switch (pending.kind) {
    CheckoutPendingOperationKind.create
        when quote == null &&
            selection.mode != null &&
            selection.slotId != null &&
            (selection.mode == CheckoutFulfillmentMode.delivery
                ? selection.addressId != null
                : selection.pickupPointId != null) =>
      pending,
    CheckoutPendingOperationKind.confirm
        when quote != null &&
            !quote.isExpired &&
            !quote.isConfirmed &&
            pending.quoteId == quote.id &&
            pending.expectedQuoteVersion == quote.quoteVersion =>
      pending,
    CheckoutPendingOperationKind.order
        when quote != null &&
            quote.isConfirmed &&
            pending.paymentMethod != null &&
            pending.paymentMethod == selection.paymentMethod &&
            pending.quoteId == quote.id &&
            pending.expectedQuoteVersion == quote.quoteVersion =>
      pending,
    _ => null,
  };
}

bool _hasDestination(CheckoutState state) =>
    state.selection.mode == CheckoutFulfillmentMode.delivery
    ? state.selection.addressId != null &&
          state.supportedDeliveryZones.isNotEmpty
    : state.selection.pickupPointId != null;

bool _selectionComplete(CheckoutState state) =>
    _hasDestination(state) &&
    state.selection.slotId != null &&
    state.selectableSlots.any((slot) => slot.id == state.selection.slotId) &&
    state.hasValidPaymentSelection;

CheckoutFailureKind _failureFor(
  CheckoutRemoteStatus status,
) => switch (status) {
  CheckoutRemoteStatus.cartVersionConflict ||
  CheckoutRemoteStatus.quoteVersionConflict => CheckoutFailureKind.staleCart,
  CheckoutRemoteStatus.invalidAddress => CheckoutFailureKind.invalidAddress,
  CheckoutRemoteStatus.unsupportedZone => CheckoutFailureKind.unsupportedZone,
  CheckoutRemoteStatus.slotUnavailable ||
  CheckoutRemoteStatus.pickupUnavailable ||
  CheckoutRemoteStatus.deliveryUnavailable ||
  CheckoutRemoteStatus.modeUnavailable => CheckoutFailureKind.slotUnavailable,
  CheckoutRemoteStatus.cartEmpty ||
  CheckoutRemoteStatus.cartUnavailable => CheckoutFailureKind.cartUnavailable,
  CheckoutRemoteStatus.expired => CheckoutFailureKind.expired,
  CheckoutRemoteStatus.idempotencyConflict => CheckoutFailureKind.conflict,
  CheckoutRemoteStatus.notFound => CheckoutFailureKind.notFound,
  CheckoutRemoteStatus.invalid ||
  CheckoutRemoteStatus.invalidSelection => CheckoutFailureKind.invalidInput,
  CheckoutRemoteStatus.unavailable => CheckoutFailureKind.unavailable,
  _ => CheckoutFailureKind.unexpected,
};

CheckoutFailureKind _failureForOrder(CheckoutOrderRemoteStatus status) =>
    switch (status) {
      CheckoutOrderRemoteStatus.quoteVersionConflict ||
      CheckoutOrderRemoteStatus.cartVersionConflict ||
      CheckoutOrderRemoteStatus.requiresReview ||
      CheckoutOrderRemoteStatus.invalidated => CheckoutFailureKind.staleCart,
      CheckoutOrderRemoteStatus.invalidAddress =>
        CheckoutFailureKind.invalidAddress,
      CheckoutOrderRemoteStatus.unsupportedZone =>
        CheckoutFailureKind.unsupportedZone,
      CheckoutOrderRemoteStatus.slotUnavailable ||
      CheckoutOrderRemoteStatus.pickupUnavailable ||
      CheckoutOrderRemoteStatus.deliveryUnavailable ||
      CheckoutOrderRemoteStatus.modeUnavailable =>
        CheckoutFailureKind.slotUnavailable,
      CheckoutOrderRemoteStatus.cartEmpty ||
      CheckoutOrderRemoteStatus.cartUnavailable =>
        CheckoutFailureKind.cartUnavailable,
      CheckoutOrderRemoteStatus.expired => CheckoutFailureKind.expired,
      CheckoutOrderRemoteStatus.idempotencyConflict =>
        CheckoutFailureKind.conflict,
      CheckoutOrderRemoteStatus.paymentMethodUnavailable ||
      CheckoutOrderRemoteStatus.paymentMethodConflict ||
      CheckoutOrderRemoteStatus.onlinePaymentUnavailable =>
        CheckoutFailureKind.paymentUnavailable,
      CheckoutOrderRemoteStatus.notFound => CheckoutFailureKind.notFound,
      CheckoutOrderRemoteStatus.invalid ||
      CheckoutOrderRemoteStatus.invalidSelection ||
      CheckoutOrderRemoteStatus.quoteNotConfirmed =>
        CheckoutFailureKind.invalidInput,
      CheckoutOrderRemoteStatus.unavailable => CheckoutFailureKind.unavailable,
      CheckoutOrderRemoteStatus.invariantError ||
      CheckoutOrderRemoteStatus.ok => CheckoutFailureKind.unexpected,
    };
