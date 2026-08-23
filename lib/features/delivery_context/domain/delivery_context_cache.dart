import 'delivery_context_models.dart';

abstract interface class DeliveryContextCacheStore {
  Future<CustomerDeliveryContext?> read({
    required String ownerSubjectId,
    required String shopSlug,
  });

  Future<void> write({
    required String ownerSubjectId,
    required CustomerDeliveryContext context,
  });

  Future<void> remove({
    required String ownerSubjectId,
    required String shopSlug,
  });
}
