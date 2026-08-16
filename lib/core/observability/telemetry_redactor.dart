import 'dart:convert';

final class TelemetryRedactor {
  const TelemetryRedactor({this.maximumLength = 4096})
    : assert(maximumLength >= 2);

  final int maximumLength;

  static final _patterns = <(RegExp, String)>[
    (
      RegExp(
        r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
        caseSensitive: false,
      ),
      '[REDACTED_EMAIL]',
    ),
    (
      RegExp(r'\b(?:bearer|basic)\s+[A-Z0-9._~+\-/]+=*', caseSensitive: false),
      '[REDACTED_AUTH]',
    ),
    (
      RegExp(
        r'\b(?:access[_-]?token|refresh[_-]?token|id[_-]?token|auth[_-]?token|oauth[_-]?code|client[_-]?secret|payment[_-]?(?:secret|token)|push[_-]?token|api[_-]?key|service[_-]?role|password|passphrase|authorization|cookie|private[_-]?key|dsn|secret|credentials?)\b["\x27]?\s*[:=]\s*["\x27]?[^"\x27\s,;}]+',
        caseSensitive: false,
      ),
      '[REDACTED_SECRET]',
    ),
    (RegExp(r'\bhttps?://[^\s"<>]+', caseSensitive: false), '[REDACTED_URL]'),
    (
      RegExp(
        r'\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}\b',
      ),
      '[REDACTED_UUID]',
    ),
    (
      RegExp(
        r'(?<![A-Za-z0-9])[-+]?\d{1,2}\.\d{4,}\s*[,/]\s*[-+]?\d{1,3}\.\d{4,}(?![A-Za-z0-9])',
      ),
      '[REDACTED_COORDINATES]',
    ),
    (
      RegExp(r'(?<![A-Za-z0-9])(?:\+?\d[\d ()-]{7,}\d)(?![A-Za-z0-9])'),
      '[REDACTED_PHONE]',
    ),
  ];

  static const _sensitiveKeys = {
    'name',
    'email',
    'phone',
    'address',
    'latitude',
    'longitude',
    'lat',
    'lng',
    'coordinates',
    'trackingurl',
    'query',
    'querytext',
    'rawquery',
    'cart',
    'cartitems',
    'accesstoken',
    'refreshtoken',
    'idtoken',
    'authtoken',
    'oauthcode',
    'clientsecret',
    'paymentsecret',
    'paymenttoken',
    'pushtoken',
    'apikey',
    'servicerole',
    'password',
    'passphrase',
    'authorization',
    'cookie',
    'cookiejar',
    'privatekey',
    'dsn',
    'secret',
    'credential',
    'credentials',
  };

  static const _sensitiveKeySuffixes = {
    'password',
    'passphrase',
    'authorization',
    'cookie',
    'privatekey',
    'dsn',
    'secret',
    'credential',
    'credentials',
  };

  bool isSensitiveKey(Object? key) {
    if (key is! String) return true;
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return _sensitiveKeys.contains(normalized) ||
        _sensitiveKeySuffixes.any(normalized.endsWith);
  }

  String redact(String value) {
    var sanitized = value.replaceAll(
      RegExp(r'[\u0000-\u0008\u000B\u000C\u000E-\u001F]'),
      '',
    );
    for (final (pattern, replacement) in _patterns) {
      sanitized = sanitized.replaceAll(pattern, replacement);
    }
    if (sanitized.length <= maximumLength) return sanitized;
    return '${sanitized.substring(0, maximumLength)}[TRUNCATED]';
  }
}

final class CrashSafeTelemetrySerializer {
  const CrashSafeTelemetrySerializer({
    this.redactor = const TelemetryRedactor(),
  });

  final TelemetryRedactor redactor;

  String serialize(Map<String, Object?> payload) {
    try {
      final encoded = jsonEncode(_safeValue(payload, depth: 0));
      if (encoded.length <= redactor.maximumLength) return encoded;
      const truncated = '{"schema":1,"name":"[TRUNCATED]"}';
      return redactor.maximumLength >= truncated.length ? truncated : '{}';
    } on Object {
      return '{"schema":1,"name":"serializationFailure"}';
    }
  }

  Object? _safeValue(Object? value, {required int depth}) {
    if (depth > 5) return '[DEPTH_LIMIT]';
    return switch (value) {
      null || bool() || int() || double() => value,
      String() => redactor.redact(value),
      List<Object?>() => [
        for (final item in value.take(32)) _safeValue(item, depth: depth + 1),
      ],
      Map<Object?, Object?>() => _safeMap(value, depth: depth),
      _ => '[UNSUPPORTED_${value.runtimeType}]',
    };
  }

  Map<String, Object?> _safeMap(
    Map<Object?, Object?> value, {
    required int depth,
  }) {
    final result = <String, Object?>{};
    for (final entry in value.entries.take(32)) {
      final key = _safeKey(entry.key);
      result[key] =
          redactor.isSensitiveKey(entry.key) &&
              !_isSafeRootEventName(entry.key, entry.value, depth)
          ? '[REDACTED_SECRET]'
          : _safeValue(entry.value, depth: depth + 1);
    }
    return result;
  }

  bool _isSafeRootEventName(Object? key, Object? value, int depth) {
    if (depth != 0 || key != 'name' || value is! String) return false;
    return const {
      'appStart',
      'screenView',
      'catalogQueryResult',
      'addToCartOutcome',
      'checkoutStep',
      'orderCreated',
      'orderStatus',
      'notificationRouting',
      'trackingAvailability',
      'trackingSignal',
      'backendFailure',
      'performanceBudgetViolation',
      'crash',
      'serializationFailure',
    }.contains(value);
  }

  String _safeKey(Object? key) {
    final value = key is String ? key : 'unsupportedKey';
    final safe = redactor.redact(value);
    return safe.length <= 64 ? safe : safe.substring(0, 64);
  }
}
