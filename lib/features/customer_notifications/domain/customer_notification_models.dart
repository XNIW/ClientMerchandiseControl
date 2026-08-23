enum CustomerNotificationEvent {
  confirmed,
  rejected,
  preparing,
  ready,
  outForDelivery,
  completed,
  cancelled,
  reservationExpiring,
}

enum CustomerNotificationCategory { order, payment, afterSales, system }

enum CustomerNotificationDestinationType {
  order,
  afterSales,
  product,
  notifications,
}

final class CustomerNotification {
  CustomerNotification({
    required this.id,
    required this.shopSlug,
    required this.category,
    required this.event,
    required this.eventVersion,
    required this.titleKey,
    required this.bodyKey,
    required Map<String, String> safeArguments,
    required this.destinationType,
    required this.destinationId,
    required this.createdAt,
    required this.readAt,
    required this.expiresAt,
  }) : safeArguments = Map.unmodifiable(safeArguments);

  final String id;
  final String shopSlug;
  final CustomerNotificationCategory category;
  final String event;
  final int eventVersion;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> safeArguments;
  final CustomerNotificationDestinationType destinationType;
  final String? destinationId;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  bool get isUnread => readAt == null;

  CustomerNotification markRead(DateTime at) => CustomerNotification(
    id: id,
    shopSlug: shopSlug,
    category: category,
    event: event,
    eventVersion: eventVersion,
    titleKey: titleKey,
    bodyKey: bodyKey,
    safeArguments: safeArguments,
    destinationType: destinationType,
    destinationId: destinationId,
    createdAt: createdAt,
    readAt: readAt ?? at,
    expiresAt: expiresAt,
  );
}

final class CustomerNotificationCursor {
  const CustomerNotificationCursor({required this.createdAt, required this.id});

  final DateTime createdAt;
  final String id;
}

final class CustomerNotificationPage {
  CustomerNotificationPage({
    required List<CustomerNotification> items,
    required this.unreadCount,
    required this.serverTime,
    required this.nextCursor,
  }) : items = List.unmodifiable(items);

  final List<CustomerNotification> items;
  final int unreadCount;
  final DateTime serverTime;
  final CustomerNotificationCursor? nextCursor;
}

sealed class CustomerNotificationDestination {
  const CustomerNotificationDestination({
    required this.event,
    required this.eventVersion,
  });

  final CustomerNotificationEvent event;
  final int eventVersion;
}

final class CustomerNotificationOrderDestination
    extends CustomerNotificationDestination {
  const CustomerNotificationOrderDestination({
    required this.orderId,
    required super.event,
    required super.eventVersion,
  });

  final String orderId;
}

final class CustomerNotificationCartDestination
    extends CustomerNotificationDestination {
  const CustomerNotificationCartDestination({
    required super.event,
    required super.eventVersion,
  });
}
