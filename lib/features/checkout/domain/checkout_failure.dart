enum CheckoutFailureKind {
  offline,
  timeout,
  unauthorized,
  invalidInput,
  unavailable,
  conflict,
  staleCart,
  invalidAddress,
  unsupportedZone,
  slotUnavailable,
  paymentUnavailable,
  cartUnavailable,
  expired,
  notFound,
  unexpected,
}

final class CheckoutRepositoryException implements Exception {
  const CheckoutRepositoryException(this.kind);

  final CheckoutFailureKind kind;
}
