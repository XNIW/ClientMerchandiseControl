import 'dart:convert';

final class TelemetryRedactor {
  const TelemetryRedactor({this.maximumLength = 4096});

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
        r'\b(?:access[_-]?token|refresh[_-]?token|auth[_-]?token|oauth[_-]?code|payment[_-]?(?:secret|token)|push[_-]?token|api[_-]?key|service[_-]?role)\b\s*[:=]\s*[^\s,;}]+',
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
      return redactor.redact(jsonEncode(_safeValue(payload, depth: 0)));
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
      Map<Object?, Object?>() => {
        for (final entry in value.entries.take(32))
          _safeKey(entry.key): _safeValue(entry.value, depth: depth + 1),
      },
      _ => '[UNSUPPORTED_${value.runtimeType}]',
    };
  }

  String _safeKey(Object? key) {
    final value = key is String ? key : 'unsupportedKey';
    final safe = redactor.redact(value);
    return safe.length <= 64 ? safe : safe.substring(0, 64);
  }
}
