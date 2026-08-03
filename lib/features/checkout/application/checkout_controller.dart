import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
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
    if (cart.isEmpty) {
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
    _ownerSubjectId = identity.subjectId;
    _shopSlug = shopSlug;
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
    return _serialize(() async {
      final pending = state.pendingOperation;
      if (pending != null) {
        if (pending.kind == CheckoutPendingOperationKind.create) {
          await _executeCreate(pending);
        } else {
          await _executeConfirm(pending);
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
    if (state.isBusy) return;
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
    return _serialize(() async {
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
      if (!await _persist(pendingState)) return;
      _publish(pendingState);
      await _executeCreate(pending);
    });
  }

  Future<void> confirmQuote() {
    return _serialize(() async {
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
      if (!await _persist(pendingState)) return;
      _publish(pendingState);
      await _executeConfirm(pending);
    });
  }

  Future<void> restart() {
    return _serialize(() async {
      final owner = _ownerSubjectId;
      final shop = _shopSlug;
      if (owner == null || shop == null) return;
      try {
        await ref
            .read(checkoutDraftStoreProvider)
            .clear(ownerSubjectId: owner, shopSlug: shop);
        _publish(
          state.copyWith(
            step: CheckoutStep.mode,
            selection: const CheckoutSelection(),
            quote: null,
            pendingOperation: null,
            failureKind: null,
            notice: null,
          ),
        );
      } on Object {
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
    _publish(CheckoutState.loading(cart: cart).copyWith(addresses: addresses));
    try {
      final results = await Future.wait<Object?>([
        ref.read(checkoutRepositoryProvider).loadOptions(shopSlug: shop),
        ref
            .read(checkoutDraftStoreProvider)
            .read(ownerSubjectId: owner, shopSlug: shop),
      ]);
      if (!_isCurrent(generation)) return;
      final options = results[0]! as StorefrontFulfillmentOptions;
      final draft = results[1] as CheckoutLocalDraft?;
      if (options.status != FulfillmentOptionsStatus.ok ||
          !options.modes.any((mode) => mode.enabled)) {
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
        addresses,
      );
      CheckoutQuote? quote;
      CheckoutFailureKind? restoreFailure;
      if (draft?.quoteId != null) {
        try {
          final response = await ref
              .read(checkoutRepositoryProvider)
              .readQuote(quoteId: draft!.quoteId!);
          if (!_isCurrent(generation)) return;
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
        quote: quote,
        pendingOperation: pendingOperation,
        failureKind: restoreFailure,
        notice: restoreNotice && draft != null
            ? CheckoutNoticeKind.restored
            : null,
      );
      _publish(ready);
      await _persist(ready);
    } on CheckoutRepositoryException catch (error) {
      if (_isCurrent(generation)) {
        _publish(CheckoutState.failure(failureKind: error.kind, cart: cart));
      }
    } on Object {
      if (_isCurrent(generation)) {
        _publish(
          CheckoutState.failure(
            failureKind: CheckoutFailureKind.unexpected,
            cart: cart,
          ),
        );
      }
    }
  }

  Future<void> _executeCreate(CheckoutPendingOperation pending) async {
    final shop = _shopSlug;
    if (shop == null) return;
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
        await _persistAndPublish(ready);
        return;
      }
      await _publishDeterministicFailure(response, quote: quote);
    } on CheckoutRepositoryException catch (error) {
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

  Future<void> _executeConfirm(CheckoutPendingOperation pending) async {
    final quoteId = pending.quoteId;
    final expectedVersion = pending.expectedQuoteVersion;
    if (quoteId == null || expectedVersion == null) return;
    _publish(state.copyWith(isBusy: true, failureKind: null, notice: null));
    try {
      final response = await ref
          .read(checkoutRepositoryProvider)
          .confirmQuote(
            quoteId: quoteId,
            expectedQuoteVersion: expectedVersion,
            idempotencyKey: pending.idempotencyKey,
          );
      final quote = response.quote;
      if (response.status == CheckoutRemoteStatus.confirmed && quote != null) {
        final confirmed = state.copyWith(
          quote: quote,
          pendingOperation: null,
          failureKind: null,
          notice: CheckoutNoticeKind.confirmed,
          isBusy: false,
        );
        await _persistAndPublish(confirmed);
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
        await _persistAndPublish(changed);
        return;
      }
      await _publishDeterministicFailure(response, quote: quote);
    } on CheckoutRepositoryException catch (error) {
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

  Future<void> _publishDeterministicFailure(
    CheckoutRemoteResponse response, {
    CheckoutQuote? quote,
  }) async {
    final failure = _failureFor(response.status);
    final next = state.copyWith(
      quote: quote,
      pendingOperation: null,
      failureKind: failure,
      isBusy: false,
    );
    await _persistAndPublish(next);
    if (failure == CheckoutFailureKind.staleCart) {
      await ref.read(checkoutCartRefreshProvider)();
    }
  }

  Future<void> _replaceDraftState(CheckoutState next) async {
    if (await _persist(next)) _publish(next);
  }

  Future<void> _persistAndPublish(CheckoutState next) async {
    if (await _persist(next)) _publish(next);
  }

  Future<bool> _persist(CheckoutState value) async {
    final owner = _ownerSubjectId;
    final shop = _shopSlug;
    if (owner == null || shop == null) return false;
    try {
      await ref
          .read(checkoutDraftStoreProvider)
          .save(
            CheckoutLocalDraft(
              ownerSubjectId: owner,
              shopSlug: shop,
              step: value.step,
              selection: value.selection,
              quoteId: value.quote?.id,
              pendingOperation: value.pendingOperation,
              updatedAt: ref.read(checkoutClockProvider)(),
            ),
          );
      return true;
    } on Object {
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
    _lastState = value;
    state = value;
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;
}

CheckoutSelection _sanitizeSelection(
  CheckoutSelection selection,
  StorefrontFulfillmentOptions options,
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
    return CheckoutSelection(
      mode: mode,
      addressId: address.id,
      slotId:
          slot?.mode == mode && supportedZones.contains(slot?.deliveryZoneId)
          ? slot?.id
          : null,
    );
  }
  final point = options.pickupPoint(selection.pickupPointId);
  if (point == null) return CheckoutSelection(mode: mode);
  final slot = options.slot(selection.slotId);
  return CheckoutSelection(
    mode: mode,
    pickupPointId: point.id,
    slotId: slot?.mode == mode && slot?.pickupPointId == point.id
        ? slot?.id
        : null,
  );
}

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
    state.selectableSlots.any((slot) => slot.id == state.selection.slotId);

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
