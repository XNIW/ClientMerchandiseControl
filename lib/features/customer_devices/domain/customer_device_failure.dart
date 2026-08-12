enum CustomerDeviceFailureKind {
  invalidInput,
  offline,
  timeout,
  unauthorized,
  conflict,
  unavailable,
  unexpected,
}

final class CustomerDeviceFailure {
  const CustomerDeviceFailure(this.kind);

  final CustomerDeviceFailureKind kind;
}

final class CustomerDeviceRepositoryException implements Exception {
  const CustomerDeviceRepositoryException(this.kind);

  final CustomerDeviceFailureKind kind;

  @override
  String toString() => 'CustomerDeviceRepositoryException($kind)';
}
