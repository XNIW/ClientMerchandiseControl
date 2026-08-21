import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

class ReleaseConfigValidationException implements Exception {
  const ReleaseConfigValidationException(this.code);

  final String code;
}

class ReleaseConfigAttestation {
  ReleaseConfigAttestation._(this.values, this.sha256);

  static const markerPrefix = 'CMC_RELEASE_CONFIG_ATTESTATION_V1:';

  static const requiredKeys = <String>[
    'APP_ENV',
    'SUPABASE_URL',
    'SUPABASE_PUBLISHABLE_KEY',
    'AUTH_REDIRECT_URI',
    'GOOGLE_AUTH_ENABLED',
    'STOREFRONT_SHOP_SLUG',
    'DELIVERY_MAPS_ENABLED',
    'DELIVERY_MAPS_NATIVE_CONFIGURED',
  ];

  final Map<String, String> values;
  final String sha256;

  String get marker => '$markerPrefix$sha256';

  static ReleaseConfigAttestation fromBytes(List<int> bytes) {
    if (bytes.isEmpty || bytes.length > 65536) {
      throw const ReleaseConfigValidationException('FILE_SIZE_INVALID');
    }
    final String source;
    try {
      source = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const ReleaseConfigValidationException('JSON_INVALID');
    }
    return fromValues(_FlatJsonStringObjectParser(source).parse());
  }

  static ReleaseConfigAttestation fromValues(Map<String, String> input) {
    final expected = requiredKeys.toSet();
    if (input.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(input.keys.toSet()).isNotEmpty) {
      throw const ReleaseConfigValidationException('KEY_SET_INVALID');
    }
    if (input.values.any((value) => value.isEmpty || value != value.trim())) {
      throw const ReleaseConfigValidationException('VALUE_NOT_CANONICAL');
    }
    if (input['APP_ENV'] != 'production') {
      throw const ReleaseConfigValidationException('ENVIRONMENT_INVALID');
    }
    if (input['GOOGLE_AUTH_ENABLED'] != 'false' ||
        input['DELIVERY_MAPS_ENABLED'] != 'false' ||
        input['DELIVERY_MAPS_NATIVE_CONFIGURED'] != 'false') {
      throw const ReleaseConfigValidationException('CAPABILITY_STATE_INVALID');
    }

    final canonical = <String, String>{
      'APP_ENV': 'production',
      'SUPABASE_URL': canonicalSupabaseOrigin(input['SUPABASE_URL']!),
      'SUPABASE_PUBLISHABLE_KEY': input['SUPABASE_PUBLISHABLE_KEY']!,
      'AUTH_REDIRECT_URI': canonicalAuthRedirectUri(
        input['AUTH_REDIRECT_URI']!,
      ),
      'GOOGLE_AUTH_ENABLED': 'false',
      'STOREFRONT_SHOP_SLUG': canonicalShopSlug(input['STOREFRONT_SHOP_SLUG']!),
      'DELIVERY_MAPS_ENABLED': 'false',
      'DELIVERY_MAPS_NATIVE_CONFIGURED': 'false',
    };
    if (!isPublishableKeyAllowed(canonical['SUPABASE_PUBLISHABLE_KEY']!)) {
      throw const ReleaseConfigValidationException('PUBLISHABLE_KEY_INVALID');
    }
    final digest = crypto.sha256
        .convert(utf8.encode(jsonEncode(canonical)))
        .toString();
    return ReleaseConfigAttestation._(Map.unmodifiable(canonical), digest);
  }

  static String canonicalSupabaseOrigin(String value) {
    try {
      final uri = Uri.parse(value);
      final hasForbiddenDelimiter = value.contains('?') || value.contains('#');
      final hasUserInfo = uri.authority.contains('@');
      final hasInvalidPort = uri.hasPort && (uri.port < 1 || uri.port > 65535);
      if (uri.scheme != 'https' ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          hasUserInfo ||
          hasInvalidPort ||
          hasForbiddenDelimiter ||
          (uri.path.isNotEmpty && uri.path != '/')) {
        throw const ReleaseConfigValidationException('BACKEND_ORIGIN_INVALID');
      }
      return Uri(
        scheme: 'https',
        host: uri.host,
        port: uri.hasPort && uri.port != 443 ? uri.port : null,
      ).toString();
    } on FormatException {
      throw const ReleaseConfigValidationException('BACKEND_ORIGIN_INVALID');
    }
  }

  static String canonicalAuthRedirectUri(String value) {
    const allowed = 'https://clientmerchandisecontrol.invalid/auth-callback/';
    try {
      final uri = Uri.parse(value);
      if (!uri.isAbsolute ||
          uri.scheme != 'https' ||
          uri.host != 'clientmerchandisecontrol.invalid' ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort ||
          uri.path != '/auth-callback/' ||
          uri.hasQuery ||
          uri.hasFragment ||
          value.contains('*') ||
          value != allowed) {
        throw const ReleaseConfigValidationException('AUTH_REDIRECT_INVALID');
      }
      return uri.toString();
    } on FormatException {
      throw const ReleaseConfigValidationException('AUTH_REDIRECT_INVALID');
    }
  }

  static String canonicalShopSlug(String value) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
      throw const ReleaseConfigValidationException('SHOP_SLUG_INVALID');
    }
    return value;
  }

  static bool isPublishableKeyAllowed(String value) {
    if (RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(value)) {
      return true;
    }
    final segments = value.split('.');
    if (segments.length != 3 || segments.any((segment) => segment.isEmpty)) {
      return false;
    }
    try {
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[0]))),
      );
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      final signature = base64Url.decode(base64Url.normalize(segments[2]));
      return header is Map<String, dynamic> &&
          payload is Map<String, dynamic> &&
          payload['role'] == 'anon' &&
          signature.isNotEmpty;
    } on FormatException {
      return false;
    }
  }
}

class _FlatJsonStringObjectParser {
  _FlatJsonStringObjectParser(this.source);

  final String source;
  int index = 0;

  Map<String, String> parse() {
    final result = <String, String>{};
    _skipWhitespace();
    _expect('{');
    _skipWhitespace();
    if (_consume('}')) {
      _finish();
      return result;
    }
    while (true) {
      final key = _readString();
      if (result.containsKey(key)) {
        throw const ReleaseConfigValidationException('DUPLICATE_KEY');
      }
      _skipWhitespace();
      _expect(':');
      _skipWhitespace();
      result[key] = _readString();
      _skipWhitespace();
      if (_consume('}')) {
        _finish();
        return result;
      }
      _expect(',');
      _skipWhitespace();
    }
  }

  String _readString() {
    if (index >= source.length || source.codeUnitAt(index) != 0x22) {
      throw const ReleaseConfigValidationException('STRING_VALUES_REQUIRED');
    }
    final start = index++;
    var escaped = false;
    while (index < source.length) {
      final code = source.codeUnitAt(index++);
      if (escaped) {
        escaped = false;
      } else if (code == 0x5c) {
        escaped = true;
      } else if (code == 0x22) {
        try {
          final decoded = jsonDecode(source.substring(start, index));
          if (decoded is String) {
            return decoded;
          }
        } on FormatException {
          // Convertito nell'errore bounded del contratto qui sotto.
        }
        break;
      } else if (code < 0x20) {
        break;
      }
    }
    throw const ReleaseConfigValidationException('JSON_INVALID');
  }

  void _skipWhitespace() {
    while (index < source.length &&
        const <int>{
          0x20,
          0x09,
          0x0a,
          0x0d,
        }.contains(source.codeUnitAt(index))) {
      index++;
    }
  }

  bool _consume(String character) {
    if (index < source.length && source[index] == character) {
      index++;
      return true;
    }
    return false;
  }

  void _expect(String character) {
    if (!_consume(character)) {
      throw const ReleaseConfigValidationException('JSON_INVALID');
    }
  }

  void _finish() {
    _skipWhitespace();
    if (index != source.length) {
      throw const ReleaseConfigValidationException('JSON_INVALID');
    }
  }
}
