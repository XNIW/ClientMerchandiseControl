import 'customer_notification_models.dart';

abstract interface class CustomerNotificationCache {
  Future<List<CustomerNotification>> read({
    required String ownerSubjectId,
    required String shopSlug,
  });

  Future<void> write({
    required String ownerSubjectId,
    required String shopSlug,
    required List<CustomerNotification> items,
  });

  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  });
}
