enum CustomerAccountFailureKind {
  offline,
  unauthorized,
  invalidInput,
  conflict,
  timeout,
  unavailable,
  unexpected,
}

final class CustomerAccountFailure {
  const CustomerAccountFailure(this.kind);

  final CustomerAccountFailureKind kind;

  bool get canRetry => switch (kind) {
    CustomerAccountFailureKind.offline ||
    CustomerAccountFailureKind.timeout ||
    CustomerAccountFailureKind.unavailable ||
    CustomerAccountFailureKind.unexpected => true,
    CustomerAccountFailureKind.unauthorized ||
    CustomerAccountFailureKind.invalidInput ||
    CustomerAccountFailureKind.conflict => false,
  };
}

final class CustomerAccountRepositoryException implements Exception {
  const CustomerAccountRepositoryException(this.kind);

  final CustomerAccountFailureKind kind;

  @override
  String toString() => 'CustomerAccountRepositoryException(${kind.name})';
}
