import 'customer_notification_models.dart';

abstract interface class CustomerNotificationRepository {
  Future<CustomerNotificationPage> list({
    required String shopSlug,
    CustomerNotificationCategory? category,
    CustomerNotificationCursor? before,
    int pageSize = 25,
  });

  Future<DateTime> markRead(String notificationId);

  Future<int> markAllRead(String shopSlug);

  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  });
}
