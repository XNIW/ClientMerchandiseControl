import '../../account/domain/customer_account_models.dart';
import '../../cart/domain/cart_models.dart';
import '../domain/checkout_failure.dart';
import '../domain/checkout_models.dart';

const _checkoutUnset = Object();

enum CheckoutViewStatus { authRequired, loading, ready, failure }

enum CheckoutNoticeKind { restored, quoteChanged, confirmed, orderConfirmed }

final class CheckoutState {
  CheckoutState({
    required this.status,
    required this.step,
    required this.selection,
    required List<CustomerAddress> addresses,
    this.cart,
    this.options,
    this.paymentOptions,
    this.quote,
    this.order,
    this.pendingOperation,
    this.failureKind,
    this.notice,
    this.isBusy = false,
  }) : addresses = List.unmodifiable(addresses);

  factory CheckoutState.loading({CustomerCartSnapshot? cart}) {
    return CheckoutState(
      status: CheckoutViewStatus.loading,
      step: CheckoutStep.mode,
      selection: const CheckoutSelection(),
      addresses: const [],
      cart: cart,
    );
  }

  factory CheckoutState.authRequired(CustomerCartSnapshot cart) {
    return CheckoutState(
      status: CheckoutViewStatus.authRequired,
      step: CheckoutStep.mode,
      selection: const CheckoutSelection(),
      addresses: const [],
      cart: cart,
    );
  }

  factory CheckoutState.failure({
    required CheckoutFailureKind failureKind,
    CustomerCartSnapshot? cart,
  }) {
    return CheckoutState(
      status: CheckoutViewStatus.failure,
      step: CheckoutStep.mode,
      selection: const CheckoutSelection(),
      addresses: const [],
      cart: cart,
      failureKind: failureKind,
    );
  }

  final CheckoutViewStatus status;
  final CheckoutStep step;
  final CheckoutSelection selection;
  final List<CustomerAddress> addresses;
  final CustomerCartSnapshot? cart;
  final StorefrontFulfillmentOptions? options;
  final StorefrontPaymentOptions? paymentOptions;
  final CheckoutQuote? quote;
  final CheckoutOrder? order;
  final CheckoutPendingOperation? pendingOperation;
  final CheckoutFailureKind? failureKind;
  final CheckoutNoticeKind? notice;
  final bool isBusy;

  bool get hasPendingRetry => pendingOperation != null;
  bool get isConfirmed => quote?.isConfirmed ?? false;
  bool get hasOrder => order != null;

  CustomerAddress? get selectedAddress => selection.addressId == null
      ? null
      : addresses
            .where((address) => address.id == selection.addressId)
            .firstOrNull;

  CheckoutPickupPoint? get selectedPickupPoint =>
      options?.pickupPoint(selection.pickupPointId);

  CheckoutFulfillmentSlot? get selectedSlot => options?.slot(selection.slotId);

  CheckoutPaymentOption? get selectedPaymentOption {
    final method = selection.paymentMethod;
    return method == null ? null : paymentOptions?.option(method);
  }

  List<CheckoutPaymentOption> get compatiblePaymentOptions {
    final mode = selection.mode;
    final current = paymentOptions;
    if (mode == null || current == null) return const [];
    return current.methods
        .where((option) => option.supports(mode))
        .toList(growable: false);
  }

  bool get hasValidPaymentSelection {
    final mode = selection.mode;
    final method = selection.paymentMethod;
    return mode != null &&
        method != null &&
        (paymentOptions?.isEnabled(method, mode) ?? false);
  }

  List<CheckoutDeliveryZone> get supportedDeliveryZones {
    final address = selectedAddress;
    final current = options;
    if (address == null || current == null) return const [];
    return current.deliveryZones
        .where((zone) => zone.supports(address))
        .toList(growable: false);
  }

  List<CheckoutFulfillmentSlot> get selectableSlots {
    final mode = selection.mode;
    final current = options;
    if (mode == null || current == null) return const [];
    return current.slots
        .where((slot) {
          if (slot.mode != mode) return false;
          if (mode == CheckoutFulfillmentMode.delivery) {
            final zoneIds = supportedDeliveryZones
                .map((zone) => zone.id)
                .toSet();
            return zoneIds.contains(slot.deliveryZoneId);
          }
          return slot.pickupPointId == selection.pickupPointId;
        })
        .toList(growable: false);
  }

  CheckoutState copyWith({
    CheckoutViewStatus? status,
    CheckoutStep? step,
    CheckoutSelection? selection,
    List<CustomerAddress>? addresses,
    Object? cart = _checkoutUnset,
    Object? options = _checkoutUnset,
    Object? paymentOptions = _checkoutUnset,
    Object? quote = _checkoutUnset,
    Object? order = _checkoutUnset,
    Object? pendingOperation = _checkoutUnset,
    Object? failureKind = _checkoutUnset,
    Object? notice = _checkoutUnset,
    bool? isBusy,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      step: step ?? this.step,
      selection: selection ?? this.selection,
      addresses: addresses ?? this.addresses,
      cart: identical(cart, _checkoutUnset)
          ? this.cart
          : cart as CustomerCartSnapshot?,
      options: identical(options, _checkoutUnset)
          ? this.options
          : options as StorefrontFulfillmentOptions?,
      paymentOptions: identical(paymentOptions, _checkoutUnset)
          ? this.paymentOptions
          : paymentOptions as StorefrontPaymentOptions?,
      quote: identical(quote, _checkoutUnset)
          ? this.quote
          : quote as CheckoutQuote?,
      order: identical(order, _checkoutUnset)
          ? this.order
          : order as CheckoutOrder?,
      pendingOperation: identical(pendingOperation, _checkoutUnset)
          ? this.pendingOperation
          : pendingOperation as CheckoutPendingOperation?,
      failureKind: identical(failureKind, _checkoutUnset)
          ? this.failureKind
          : failureKind as CheckoutFailureKind?,
      notice: identical(notice, _checkoutUnset)
          ? this.notice
          : notice as CheckoutNoticeKind?,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}
