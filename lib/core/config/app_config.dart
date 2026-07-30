import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';

class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromValues({
    String appEnvironment = 'development',
    String supabaseUrl = '',
    String supabasePublishableKey = '',
  }) {
    final environment = AppEnvironment.parse(appEnvironment);
    final normalizedUrl = _normalize(supabaseUrl);
    final normalizedKey = _normalize(supabasePublishableKey);

    if ((normalizedUrl == null) != (normalizedKey == null)) {
      throw const AppConfigurationException(
        'SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY devono essere configurati insieme.',
      );
    }

    if (environment != AppEnvironment.development &&
        (normalizedUrl == null || normalizedKey == null)) {
      throw AppConfigurationException(
        'La configurazione ${environment.name} richiede il backend completo.',
      );
    }

    final canonicalUrl = normalizedUrl == null
        ? null
        : _canonicalSupabaseOrigin(normalizedUrl);

    if (normalizedKey != null && !_isPublishableKeyAllowed(normalizedKey)) {
      throw const AppConfigurationException(
        'SUPABASE_PUBLISHABLE_KEY deve essere una chiave pubblicabile valida.',
      );
    }

    return AppConfig._(
      environment: environment,
      supabaseUrl: canonicalUrl,
      supabasePublishableKey: normalizedKey,
    );
  }

  factory AppConfig.fromEnvironment() {
    return AppConfig.fromValues(
      appEnvironment: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    );
  }

  final AppEnvironment environment;
  final String? supabaseUrl;
  final String? supabasePublishableKey;

  bool get isBackendConfigured =>
      supabaseUrl != null && supabasePublishableKey != null;

  static String? _normalize(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String _canonicalSupabaseOrigin(String value) {
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
        throw const AppConfigurationException(
          'SUPABASE_URL deve essere una origin HTTPS senza credenziali, path, query o fragment.',
        );
      }

      return Uri(
        scheme: 'https',
        host: uri.host,
        port: uri.hasPort && uri.port != 443 ? uri.port : null,
      ).toString();
    } on FormatException {
      throw const AppConfigurationException(
        'SUPABASE_URL deve essere una origin HTTPS valida.',
      );
    }
  }

  static bool _isPublishableKeyAllowed(String value) {
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

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig deve essere fornito durante il bootstrap.');
});
