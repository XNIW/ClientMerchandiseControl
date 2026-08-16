import 'delivery_tracking_models.dart';

abstract interface class DeliveryTrackingRepository {
  Future<DeliveryTrackingSnapshot> load({
    required String shopSlug,
    required String orderId,
  });

  Stream<DeliveryTrackingSnapshot> watch({required String orderId});
}

abstract interface class DeliveryTrackingCacheStore {
  Future<DeliveryTrackingSnapshot?> read({
    required String ownerSubjectId,
    required String shopSlug,
    required String orderId,
  });

  Future<void> save({
    required String ownerSubjectId,
    required String shopSlug,
    required DeliveryTrackingSnapshot snapshot,
  });

  Future<void> clear({required String ownerSubjectId});
}
