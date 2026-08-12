enum CustomerOrderFailureKind {
  offline,
  timeout,
  unauthorized,
  invalid,
  unavailable,
  notFound,
  notCancellable,
  versionConflict,
  idempotencyConflict,
  unexpected,
}

final class CustomerOrderRepositoryException implements Exception {
  const CustomerOrderRepositoryException(this.kind);

  final CustomerOrderFailureKind kind;

  @override
  String toString() => 'CustomerOrderRepositoryException(${kind.name})';
}
