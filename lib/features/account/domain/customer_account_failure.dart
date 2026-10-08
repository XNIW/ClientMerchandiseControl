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
  const CustomerAccountFailure(this.kind, {this.isUncertain = false});

  final CustomerAccountFailureKind kind;
  final bool isUncertain;

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
  const CustomerAccountRepositoryException(
    this.kind, {
    this.creationDeleted = false,
    this.creationRejected = false,
  });

  final CustomerAccountFailureKind kind;

  final bool creationDeleted;

  /// Solo un rifiuto server autorevole, mai un errore di parsing dell’ACK.
  final bool creationRejected;

  @override
  String toString() => 'CustomerAccountRepositoryException(${kind.name})';
}
