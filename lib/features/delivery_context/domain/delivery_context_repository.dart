import 'delivery_context_models.dart';

abstract interface class DeliveryContextRepository {
  Future<CustomerDeliveryContext?> read({required String shopSlug});

  Future<CustomerDeliveryContext> preview({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
    String? commune,
  });

  Future<CustomerDeliveryContext> select({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    required int expectedVersion,
    String? addressId,
    String? pickupPointId,
  });
}

enum DeliveryContextFailureKind {
  offline,
  timeout,
  unauthorized,
  conflict,
  invalid,
  unavailable,
  unexpected,
}

final class DeliveryContextRepositoryException implements Exception {
  const DeliveryContextRepositoryException(this.kind);

  final DeliveryContextFailureKind kind;
}
