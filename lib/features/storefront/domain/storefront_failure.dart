enum StorefrontFailureKind {
  cancelled,
  catalogChanged,
  invalidConfiguration,
  invalidPayload,
  offline,
  timeout,
  unauthorized,
  unavailable,
  unknown,
}

class StorefrontFailure implements Exception {
  const StorefrontFailure(this.kind, {required this.code});

  final StorefrontFailureKind kind;
  final String code;

  @override
  String toString() => 'StorefrontFailure(kind: ${kind.name}, code: $code)';
}
