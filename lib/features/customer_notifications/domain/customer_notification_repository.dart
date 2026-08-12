import 'customer_notification_models.dart';

abstract interface class CustomerNotificationRepository {
  Future<CustomerNotificationDestination> resolveRoute({
    required String shopSlug,
    required String routeToken,
  });
}
