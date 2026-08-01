import 'package:flutter/foundation.dart';

@immutable
final class AuthenticatedCustomer {
  factory AuthenticatedCustomer.fromUntrustedIdentity({
    required String subjectId,
    required String? email,
    required Map<String, Object?> metadata,
  }) {
    final normalizedSubject = subjectId.trim();
    if (normalizedSubject.isEmpty || normalizedSubject.length > 256) {
      throw const FormatException('Invalid internal Auth subject.');
    }

    return AuthenticatedCustomer._(
      subjectId: normalizedSubject,
      displayName: _firstSafeDisplayName(metadata),
      email: _safeEmail(email),
    );
  }

  const AuthenticatedCustomer._({
    required this.subjectId,
    required this.displayName,
    required this.email,
  });

  static const maxDisplayNameRunes = 80;
  static const maxEmailLength = 254;

  /// Identificatore interno: non è un attributo autorizzativo né un dato UI.
  final String subjectId;
  final String? displayName;
  final String? email;

  static String? _firstSafeDisplayName(Map<String, Object?> metadata) {
    for (final key in const ['full_name', 'name', 'given_name']) {
      final value = metadata[key];
      if (value is! String) {
        continue;
      }
      final normalized = _safeText(value, maxRunes: maxDisplayNameRunes);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }

  static String? _safeEmail(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty ||
        normalized.length > maxEmailLength ||
        !_isSafeScalarText(normalized) ||
        normalized.contains('<') ||
        normalized.contains('>')) {
      return null;
    }

    final at = normalized.indexOf('@');
    if (at < 1 ||
        at != normalized.lastIndexOf('@') ||
        at == normalized.length - 1 ||
        !normalized.substring(at + 1).contains('.')) {
      return null;
    }
    return normalized;
  }

  static String? _safeText(String value, {required int maxRunes}) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty ||
        normalized.runes.length > maxRunes ||
        !_isSafeScalarText(normalized) ||
        normalized.contains('<') ||
        normalized.contains('>')) {
      return null;
    }
    return normalized;
  }

  static bool _isSafeScalarText(String value) {
    for (final rune in value.runes) {
      final isControl = rune < 0x20 || (rune >= 0x7f && rune <= 0x9f);
      final isBidiOverride =
          rune == 0x061c ||
          (rune >= 0x200e && rune <= 0x200f) ||
          (rune >= 0x202a && rune <= 0x202e) ||
          (rune >= 0x2066 && rune <= 0x2069);
      if (isControl || isBidiOverride) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    return other is AuthenticatedCustomer &&
        other.subjectId == subjectId &&
        other.displayName == displayName &&
        other.email == email;
  }

  @override
  int get hashCode => Object.hash(subjectId, displayName, email);

  @override
  String toString() {
    return 'AuthenticatedCustomer('
        'hasDisplayName: ${displayName != null}, '
        'hasEmail: ${email != null}'
        ')';
  }
}
