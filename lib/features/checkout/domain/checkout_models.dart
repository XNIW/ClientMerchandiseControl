import '../../account/domain/customer_account_models.dart';

const checkoutMaximumAmountClp = 999999999999;
const checkoutMaximumItems = 100;

enum CheckoutStep { mode, destination, slot, review, confirmation }

enum CheckoutFulfillmentMode { pickup, reservation, delivery }

enum FulfillmentOptionsStatus { ok, unavailable, invalid }

enum CheckoutRemoteStatus {
  ok,
  quoted,
  requiresReview,
  confirmed,
  expired,
  invalid,
  unavailable,
  cartEmpty,
  cartVersionConflict,
  quoteVersionConflict,
  modeUnavailable,
  slotUnavailable,
  invalidSelection,
  pickupUnavailable,
  deliveryUnavailable,
  invalidAddress,
  unsupportedZone,
  cartUnavailable,
  idempotencyConflict,
  notFound,
}

enum CheckoutOrderRemoteStatus {
  ok,
  requiresReview,
  expired,
  invalidated,
  quoteNotConfirmed,
  quoteVersionConflict,
  cartVersionConflict,
  cartEmpty,
  modeUnavailable,
  slotUnavailable,
  invalidSelection,
  pickupUnavailable,
  deliveryUnavailable,
  invalidAddress,
  unsupportedZone,
  cartUnavailable,
  idempotencyConflict,
  notFound,
  invariantError,
  invalid,
  unavailable,
}

enum CheckoutQuoteStatus {
  quoted,
  requiresReview,
  confirmed,
  expired,
  invalidated,
  consumed,
}

enum CheckoutOrderStatus {
  confirmed,
  accepted,
  rejected,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled,
}

enum CheckoutChangeType {
  priceChanged,
  promotionChanged,
  unavailable,
  holdRequired,
}

enum CheckoutPendingOperationKind { create, confirm, order }

final class CheckoutModeOption {
  const CheckoutModeOption({required this.mode, required this.enabled});

  final CheckoutFulfillmentMode mode;
  final bool enabled;
}

final class CheckoutPickupPoint {
  const CheckoutPickupPoint({
    required this.id,
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.commune,
    required this.region,
    required this.instructions,
  });

  final String id;
  final String name;
  final String addressLine1;
  final String? addressLine2;
  final String commune;
  final String region;
  final String? instructions;
}

final class CheckoutDeliveryZone {
  CheckoutDeliveryZone({
    required this.id,
    required this.name,
    required this.region,
    required List<String> communes,
    required this.feeClp,
  }) : communes = List.unmodifiable(communes);

  final String id;
  final String name;
  final String region;
  final List<String> communes;
  final int feeClp;

  bool supports(CustomerAddress address) {
    final addressRegion = _normalizedPlace(address.region);
    final addressCommune = _normalizedPlace(address.commune);
    return _normalizedPlace(region) == addressRegion &&
        communes.any((commune) => _normalizedPlace(commune) == addressCommune);
  }
}

final class CheckoutFulfillmentSlot {
  const CheckoutFulfillmentSlot({
    required this.id,
    required this.mode,
    required this.pickupPointId,
    required this.deliveryZoneId,
    required this.label,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final CheckoutFulfillmentMode mode;
  final String? pickupPointId;
  final String? deliveryZoneId;
  final String label;
  final DateTime startsAt;
  final DateTime endsAt;
}

final class StorefrontFulfillmentOptions {
  StorefrontFulfillmentOptions({
    required this.status,
    required this.shopSlug,
    required this.currencyCode,
    required List<CheckoutModeOption> modes,
    required List<CheckoutPickupPoint> pickupPoints,
    required List<CheckoutDeliveryZone> deliveryZones,
    required List<CheckoutFulfillmentSlot> slots,
    required this.serverTime,
  }) : modes = List.unmodifiable(modes),
       pickupPoints = List.unmodifiable(pickupPoints),
       deliveryZones = List.unmodifiable(deliveryZones),
       slots = List.unmodifiable(slots);

  factory StorefrontFulfillmentOptions.unavailable({
    required FulfillmentOptionsStatus status,
    required DateTime serverTime,
  }) {
    return StorefrontFulfillmentOptions(
      status: status,
      shopSlug: null,
      currencyCode: null,
      modes: const [],
      pickupPoints: const [],
      deliveryZones: const [],
      slots: const [],
      serverTime: serverTime,
    );
  }

  final FulfillmentOptionsStatus status;
  final String? shopSlug;
  final String? currencyCode;
  final List<CheckoutModeOption> modes;
  final List<CheckoutPickupPoint> pickupPoints;
  final List<CheckoutDeliveryZone> deliveryZones;
  final List<CheckoutFulfillmentSlot> slots;
  final DateTime serverTime;

  bool isEnabled(CheckoutFulfillmentMode mode) =>
      modes.any((option) => option.mode == mode && option.enabled);

  CheckoutPickupPoint? pickupPoint(String? id) => id == null
      ? null
      : pickupPoints.where((point) => point.id == id).firstOrNull;

  CheckoutDeliveryZone? deliveryZone(String? id) => id == null
      ? null
      : deliveryZones.where((zone) => zone.id == id).firstOrNull;

  CheckoutFulfillmentSlot? slot(String? id) =>
      id == null ? null : slots.where((slot) => slot.id == id).firstOrNull;
}

final class CheckoutSelection {
  const CheckoutSelection({
    this.mode,
    this.addressId,
    this.pickupPointId,
    this.slotId,
  });

  final CheckoutFulfillmentMode? mode;
  final String? addressId;
  final String? pickupPointId;
  final String? slotId;

  CheckoutSelection copyWith({
    CheckoutFulfillmentMode? mode,
    String? addressId,
    String? pickupPointId,
    String? slotId,
    bool clearMode = false,
    bool clearAddress = false,
    bool clearPickupPoint = false,
    bool clearSlot = false,
  }) {
    return CheckoutSelection(
      mode: clearMode ? null : mode ?? this.mode,
      addressId: clearAddress ? null : addressId ?? this.addressId,
      pickupPointId: clearPickupPoint
          ? null
          : pickupPointId ?? this.pickupPointId,
      slotId: clearSlot ? null : slotId ?? this.slotId,
    );
  }
}

final class CheckoutQuoteItem {
  const CheckoutQuoteItem({
    required this.publicationId,
    required this.publicName,
    required this.quantity,
    required this.unitPriceClp,
    required this.compareAtPriceClp,
    required this.lineTotalClp,
    required this.promotionName,
    required this.promotionEndsAt,
  });

  final String publicationId;
  final String publicName;
  final int quantity;
  final int unitPriceClp;
  final int? compareAtPriceClp;
  final int lineTotalClp;
  final String? promotionName;
  final DateTime? promotionEndsAt;
}

final class CheckoutQuoteChange {
  const CheckoutQuoteChange({
    required this.publicationId,
    required this.type,
    required this.previousPriceClp,
    required this.currentPriceClp,
  });

  final String publicationId;
  final CheckoutChangeType type;
  final int? previousPriceClp;
  final int? currentPriceClp;
}

final class CheckoutQuote {
  CheckoutQuote({
    required this.id,
    required this.shopSlug,
    required this.cartVersion,
    required this.quoteVersion,
    required this.status,
    required this.fulfillmentMode,
    required this.addressId,
    required this.pickupPointId,
    required this.deliveryZoneId,
    required this.slotId,
    required this.subtotalClp,
    required this.deliveryFeeClp,
    required this.totalClp,
    required List<CheckoutQuoteItem> items,
    required List<CheckoutQuoteChange> changes,
    required this.requiresCustomerReview,
    required this.quotedAt,
    required this.expiresAt,
    required this.confirmedAt,
    required this.serverTime,
    required this.remainingSeconds,
    required this.idempotent,
  }) : items = List.unmodifiable(items),
       changes = List.unmodifiable(changes);

  final String id;
  final String shopSlug;
  final int cartVersion;
  final int quoteVersion;
  final CheckoutQuoteStatus status;
  final CheckoutFulfillmentMode fulfillmentMode;
  final String? addressId;
  final String? pickupPointId;
  final String? deliveryZoneId;
  final String slotId;
  final int subtotalClp;
  final int deliveryFeeClp;
  final int totalClp;
  final List<CheckoutQuoteItem> items;
  final List<CheckoutQuoteChange> changes;
  final bool requiresCustomerReview;
  final DateTime quotedAt;
  final DateTime expiresAt;
  final DateTime? confirmedAt;
  final DateTime serverTime;
  final int remainingSeconds;
  final bool idempotent;

  bool get isConfirmed => status == CheckoutQuoteStatus.confirmed;
  bool get isExpired => status == CheckoutQuoteStatus.expired;
}

final class CheckoutRemoteResponse {
  CheckoutRemoteResponse({
    required this.status,
    required this.idempotent,
    required this.serverTime,
    this.quote,
    List<CheckoutQuoteChange> changes = const [],
  }) : changes = List.unmodifiable(changes);

  final CheckoutRemoteStatus status;
  final bool idempotent;
  final DateTime serverTime;
  final CheckoutQuote? quote;
  final List<CheckoutQuoteChange> changes;
}

final class CheckoutOrder {
  CheckoutOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.version,
    required this.shopSlug,
    required this.fulfillmentMode,
    required this.subtotalClp,
    required this.deliveryFeeClp,
    required this.totalClp,
    required List<CheckoutQuoteItem> items,
    required this.placedAt,
    required this.serverTime,
    required this.idempotent,
  }) : items = List.unmodifiable(items);

  final String id;
  final String code;
  final CheckoutOrderStatus status;
  final int version;
  final String shopSlug;
  final CheckoutFulfillmentMode fulfillmentMode;
  final int subtotalClp;
  final int deliveryFeeClp;
  final int totalClp;
  final List<CheckoutQuoteItem> items;
  final DateTime placedAt;
  final DateTime serverTime;
  final bool idempotent;
}

final class CheckoutOrderRemoteResponse {
  const CheckoutOrderRemoteResponse({
    required this.status,
    required this.idempotent,
    required this.serverTime,
    this.order,
    this.orderId,
  });

  final CheckoutOrderRemoteStatus status;
  final bool idempotent;
  final DateTime serverTime;
  final CheckoutOrder? order;
  final String? orderId;
}

final class CheckoutQuoteCreateRequest {
  const CheckoutQuoteCreateRequest({
    required this.shopSlug,
    required this.cartVersion,
    required this.selection,
    required this.idempotencyKey,
  });

  final String shopSlug;
  final int cartVersion;
  final CheckoutSelection selection;
  final String idempotencyKey;
}

final class CheckoutPendingOperation {
  const CheckoutPendingOperation({
    required this.kind,
    required this.idempotencyKey,
    required this.cartVersion,
    this.quoteId,
    this.expectedQuoteVersion,
  });

  final CheckoutPendingOperationKind kind;
  final String idempotencyKey;
  final int cartVersion;
  final String? quoteId;
  final int? expectedQuoteVersion;
}

final class CheckoutLocalDraft {
  const CheckoutLocalDraft({
    required this.ownerSubjectId,
    required this.shopSlug,
    required this.step,
    required this.selection,
    required this.updatedAt,
    this.quoteId,
    this.orderId,
    this.pendingOperation,
  });

  final String ownerSubjectId;
  final String shopSlug;
  final CheckoutStep step;
  final CheckoutSelection selection;
  final String? quoteId;
  final String? orderId;
  final CheckoutPendingOperation? pendingOperation;
  final DateTime updatedAt;

  CheckoutLocalDraft copyWith({
    CheckoutStep? step,
    CheckoutSelection? selection,
    String? quoteId,
    String? orderId,
    CheckoutPendingOperation? pendingOperation,
    DateTime? updatedAt,
    bool clearQuote = false,
    bool clearOrder = false,
    bool clearPendingOperation = false,
  }) {
    return CheckoutLocalDraft(
      ownerSubjectId: ownerSubjectId,
      shopSlug: shopSlug,
      step: step ?? this.step,
      selection: selection ?? this.selection,
      quoteId: clearQuote ? null : quoteId ?? this.quoteId,
      orderId: clearOrder ? null : orderId ?? this.orderId,
      pendingOperation: clearPendingOperation
          ? null
          : pendingOperation ?? this.pendingOperation,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

String _normalizedPlace(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
