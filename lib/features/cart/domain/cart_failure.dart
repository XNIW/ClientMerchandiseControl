enum CartFailureKind {
  offline,
  timeout,
  unauthorized,
  invalidInput,
  conflict,
  limitReached,
  unavailable,
  unexpected,
}

final class CartRepositoryException implements Exception {
  const CartRepositoryException(this.kind);

  final CartFailureKind kind;

  @override
  String toString() => 'CartRepositoryException(${kind.name})';
}
