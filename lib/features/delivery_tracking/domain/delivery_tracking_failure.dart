enum DeliveryTrackingFailureKind {
  invalid,
  unauthorized,
  notFound,
  offline,
  timeout,
  unavailable,
  unexpected,
}

final class DeliveryTrackingRepositoryException implements Exception {
  const DeliveryTrackingRepositoryException(this.kind);

  final DeliveryTrackingFailureKind kind;
}
