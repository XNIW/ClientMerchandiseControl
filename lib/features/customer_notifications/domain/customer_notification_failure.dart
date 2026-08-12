enum CustomerNotificationFailureKind {
  offline,
  timeout,
  unauthorized,
  invalid,
  notFound,
  unavailable,
  unexpected,
}

final class CustomerNotificationRepositoryException implements Exception {
  const CustomerNotificationRepositoryException(this.kind);

  final CustomerNotificationFailureKind kind;

  @override
  String toString() => 'CustomerNotificationRepositoryException(${kind.name})';
}
