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
