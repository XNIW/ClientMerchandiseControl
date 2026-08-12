const customerOrderMaximumAmountClp = 999999999999;
const customerOrderMaximumLines = 100;
const customerOrderMaximumPageSize = 50;
const customerOrderMaximumCachedCards = 50;
const customerOrderMaximumCachedDetails = 10;

enum CustomerOrderStatus {
  confirmed,
  accepted,
  rejected,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled,
}

enum CustomerOrderFulfillmentMode { pickup, reservation, delivery }

enum CustomerOrderActorKind { system, customer, admin, pos }

final class CustomerOrderCursor {
  const CustomerOrderCursor({
    required this.beforePlacedAt,
    required this.beforeOrderId,
  });

  final DateTime beforePlacedAt;
  final String beforeOrderId;
}

final class CustomerOrderCard {
  const CustomerOrderCard({
    required this.id,
    required this.code,
    required this.status,
    required this.version,
    required this.fulfillmentMode,
    required this.totalClp,
    required this.itemCount,
    required this.primaryItemName,
    required this.cancellationAllowed,
    required this.placedAt,
    required this.updatedAt,
  });

  factory CustomerOrderCard.fromDetail(CustomerOrderDetail detail) {
    return CustomerOrderCard(
      id: detail.id,
      code: detail.code,
      status: detail.status,
      version: detail.version,
      fulfillmentMode: detail.fulfillment.mode,
      totalClp: detail.totalClp,
      itemCount: detail.items.length,
      primaryItemName: detail.items.first.publicName,
      cancellationAllowed: detail.cancellation.allowed,
      placedAt: detail.placedAt,
      updatedAt: detail.updatedAt,
    );
  }

  final String id;
  final String code;
  final CustomerOrderStatus status;
  final int version;
  final CustomerOrderFulfillmentMode fulfillmentMode;
  final int totalClp;
  final int itemCount;
  final String primaryItemName;
  final bool cancellationAllowed;
  final DateTime placedAt;
  final DateTime updatedAt;
}

final class CustomerOrderPage {
  CustomerOrderPage({
    required this.shopSlug,
    required List<CustomerOrderCard> orders,
    required this.nextCursor,
    required this.serverTime,
  }) : orders = List.unmodifiable(orders);

  final String shopSlug;
  final List<CustomerOrderCard> orders;
  final CustomerOrderCursor? nextCursor;
  final DateTime serverTime;

  bool get hasMore => nextCursor != null;
}

final class CustomerOrderLine {
  const CustomerOrderLine({
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

final class CustomerOrderTimelineEvent {
  const CustomerOrderTimelineEvent({
    required this.version,
    required this.status,
    required this.actorKind,
    required this.createdAt,
  });

  final int version;
  final CustomerOrderStatus status;
  final CustomerOrderActorKind actorKind;
  final DateTime createdAt;
}

final class CustomerOrderFulfillment {
  CustomerOrderFulfillment({
    required this.mode,
    required this.destinationTitle,
    required List<String> destinationLines,
    required this.slotLabel,
    required this.slotStartsAt,
    required this.slotEndsAt,
  }) : destinationLines = List.unmodifiable(destinationLines);

  final CustomerOrderFulfillmentMode mode;
  final String destinationTitle;
  final List<String> destinationLines;
  final String slotLabel;
  final DateTime slotStartsAt;
  final DateTime slotEndsAt;
}

final class CustomerOrderCancellation {
  const CustomerOrderCancellation({
    required this.enabled,
    required this.allowed,
    required this.deadline,
  });

  final bool enabled;
  final bool allowed;
  final DateTime deadline;
}

final class CustomerOrderDetail {
  CustomerOrderDetail({
    required this.id,
    required this.code,
    required this.status,
    required this.version,
    required this.shopSlug,
    required this.fulfillment,
    required this.subtotalClp,
    required this.deliveryFeeClp,
    required this.totalClp,
    required List<CustomerOrderLine> items,
    required List<CustomerOrderTimelineEvent> timeline,
    required this.cancellation,
    required this.placedAt,
    required this.updatedAt,
    required this.serverTime,
    required this.idempotent,
  }) : items = List.unmodifiable(items),
       timeline = List.unmodifiable(timeline);

  final String id;
  final String code;
  final CustomerOrderStatus status;
  final int version;
  final String shopSlug;
  final CustomerOrderFulfillment fulfillment;
  final int subtotalClp;
  final int deliveryFeeClp;
  final int totalClp;
  final List<CustomerOrderLine> items;
  final List<CustomerOrderTimelineEvent> timeline;
  final CustomerOrderCancellation cancellation;
  final DateTime placedAt;
  final DateTime updatedAt;
  final DateTime serverTime;
  final bool idempotent;
}

final class CustomerOrderPendingCancellation {
  const CustomerOrderPendingCancellation({
    required this.orderId,
    required this.expectedStatusVersion,
    required this.idempotencyKey,
    required this.createdAt,
  });

  final String orderId;
  final int expectedStatusVersion;
  final String idempotencyKey;
  final DateTime createdAt;
}

final class CustomerOrderCacheSnapshot {
  CustomerOrderCacheSnapshot({
    required this.ownerSubjectId,
    required this.shopSlug,
    required List<CustomerOrderCard> orders,
    required Map<String, CustomerOrderDetail> details,
    required this.nextCursor,
    required this.pendingCancellation,
    required this.cachedAt,
  }) : orders = List.unmodifiable(orders),
       details = Map.unmodifiable(details);

  final String ownerSubjectId;
  final String shopSlug;
  final List<CustomerOrderCard> orders;
  final Map<String, CustomerOrderDetail> details;
  final CustomerOrderCursor? nextCursor;
  final CustomerOrderPendingCancellation? pendingCancellation;
  final DateTime cachedAt;

  CustomerOrderCacheSnapshot copyWith({
    List<CustomerOrderCard>? orders,
    Map<String, CustomerOrderDetail>? details,
    CustomerOrderCursor? nextCursor,
    CustomerOrderPendingCancellation? pendingCancellation,
    DateTime? cachedAt,
    bool clearPendingCancellation = false,
    bool clearNextCursor = false,
  }) {
    return CustomerOrderCacheSnapshot(
      ownerSubjectId: ownerSubjectId,
      shopSlug: shopSlug,
      orders: orders ?? this.orders,
      details: details ?? this.details,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      pendingCancellation: clearPendingCancellation
          ? null
          : pendingCancellation ?? this.pendingCancellation,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}
