import 'customer_order_models.dart';

abstract interface class CustomerOrderRepository {
  Future<CustomerOrderPage> listOrders({
    required String shopSlug,
    CustomerOrderCursor? cursor,
    int limit = 20,
  });

  Future<CustomerOrderDetail> loadOrder({
    required String shopSlug,
    required String orderId,
  });

  Future<CustomerOrderDetail> cancelOrder({
    required String shopSlug,
    required String orderId,
    required int expectedStatusVersion,
    required String idempotencyKey,
  });
}

abstract interface class CustomerOrderCacheStore {
  Future<CustomerOrderCacheSnapshot?> read({
    required String ownerSubjectId,
    required String shopSlug,
  });

  Future<void> save(CustomerOrderCacheSnapshot snapshot);

  Future<void> clear({
    required String ownerSubjectId,
    required String shopSlug,
  });
}
