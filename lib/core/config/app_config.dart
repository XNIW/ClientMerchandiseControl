import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';

class AppConfig {
  static const allowedAuthRedirectUri =
      'com.xniw.clientmerchandisecontrol://auth-callback/';

  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.authRedirectUri,
    required this.googleAuthEnabled,
    required this.storefrontShopSlug,
  });

  factory AppConfig.fromValues({
    String appEnvironment = 'development',
    String supabaseUrl = '',
    String supabasePublishableKey = '',
    String authRedirectUri = '',
    String googleAuthEnabled = '',
    String storefrontShopSlug = '',
  }) {
    final environment = AppEnvironment.parse(appEnvironment);
    final normalizedUrl = _normalize(supabaseUrl);
    final normalizedKey = _normalize(supabasePublishableKey);
    final rawRedirectUri = authRedirectUri.isEmpty ? null : authRedirectUri;
    final normalizedGoogleAuthEnabled = _normalize(googleAuthEnabled);
    final normalizedStorefrontShopSlug = _normalize(storefrontShopSlug);

    if ((normalizedUrl == null) != (normalizedKey == null)) {
      throw const AppConfigurationException(
        'SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY devono essere configurati insieme.',
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

    final canonicalRedirectUri = rawRedirectUri == null
        ? null
        : _canonicalAuthRedirectUri(rawRedirectUri);
    final googleAuth = _parseGoogleAuthEnabled(
      normalizedGoogleAuthEnabled,
      environment: environment,
    );
    final canonicalStorefrontShopSlug = normalizedStorefrontShopSlug == null
        ? null
        : _canonicalStorefrontShopSlug(normalizedStorefrontShopSlug);

    switch (environment) {
      case AppEnvironment.development:
        if (canonicalUrl != null ||
            normalizedKey != null ||
            canonicalRedirectUri != null ||
            googleAuth ||
            canonicalStorefrontShopSlug != null) {
          throw const AppConfigurationException(
            'La configurazione development non accetta backend, callback, OAuth o Storefront reale.',
          );
        }
        break;
      case AppEnvironment.staging:
        if (canonicalUrl == null ||
            normalizedKey == null ||
            canonicalRedirectUri == null ||
            canonicalStorefrontShopSlug == null) {
          throw const AppConfigurationException(
            'La configurazione staging richiede backend, callback, flag Google e Storefront completi.',
          );
        }
        break;
      case AppEnvironment.production:
        if (canonicalUrl == null ||
            normalizedKey == null ||
            canonicalRedirectUri == null ||
            canonicalStorefrontShopSlug == null) {
          throw const AppConfigurationException(
            'La configurazione production richiede backend, callback, flag Google e Storefront completi.',
          );
        }
        if (googleAuth) {
          throw const AppConfigurationException(
            'Google OAuth production non è abilitabile in questo milestone.',
          );
        }
        break;
    }

    return AppConfig._(
      environment: environment,
      supabaseUrl: canonicalUrl,
      supabasePublishableKey: normalizedKey,
      authRedirectUri: canonicalRedirectUri,
      googleAuthEnabled: googleAuth,
      storefrontShopSlug: canonicalStorefrontShopSlug,
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
      authRedirectUri: const String.fromEnvironment('AUTH_REDIRECT_URI'),
      googleAuthEnabled: const String.fromEnvironment('GOOGLE_AUTH_ENABLED'),
      storefrontShopSlug: const String.fromEnvironment('STOREFRONT_SHOP_SLUG'),
    );
  }

  final AppEnvironment environment;
  final String? supabaseUrl;
  final String? supabasePublishableKey;
  final String? authRedirectUri;
  final bool googleAuthEnabled;
  final String? storefrontShopSlug;

  bool get isBackendConfigured =>
      supabaseUrl != null && supabasePublishableKey != null;

  bool get isAuthRedirectConfigured => authRedirectUri != null;

  bool get isStorefrontConfigured => storefrontShopSlug != null;

  Map<String, Object> get sanitizedDiagnostics => Map.unmodifiable({
    'environment': environment.name,
    'backendConfigured': isBackendConfigured,
    'authRedirectConfigured': isAuthRedirectConfigured,
    'googleAuthEnabled': googleAuthEnabled,
    'storefrontConfigured': isStorefrontConfigured,
  });

  @override
  String toString() {
    return 'AppConfig('
        'environment: ${environment.name}, '
        'backendConfigured: $isBackendConfigured, '
        'authRedirectConfigured: $isAuthRedirectConfigured, '
        'googleAuthEnabled: $googleAuthEnabled'
        ', storefrontConfigured: $isStorefrontConfigured'
        ')';
  }

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

  static String _canonicalAuthRedirectUri(String value) {
    try {
      final uri = Uri.parse(value);
      final isStructurallyAllowed =
          uri.isAbsolute &&
          uri.scheme == 'com.xniw.clientmerchandisecontrol' &&
          uri.host == 'auth-callback' &&
          uri.userInfo.isEmpty &&
          !uri.hasPort &&
          uri.path == '/' &&
          !uri.hasQuery &&
          !uri.hasFragment &&
          !value.contains('*');

      if (!isStructurallyAllowed || value != allowedAuthRedirectUri) {
        throw const AppConfigurationException(
          'AUTH_REDIRECT_URI non appartiene alla callback mobile consentita.',
        );
      }

      return uri.toString();
    } on FormatException {
      throw const AppConfigurationException(
        'AUTH_REDIRECT_URI deve essere un URI assoluto valido e consentito.',
      );
    }
  }

  static bool _parseGoogleAuthEnabled(
    String? value, {
    required AppEnvironment environment,
  }) {
    if (value == null) {
      if (environment == AppEnvironment.development) {
        return false;
      }
      throw AppConfigurationException(
        'GOOGLE_AUTH_ENABLED deve essere esplicito in ${environment.name}.',
      );
    }

    return switch (value) {
      'true' => true,
      'false' => false,
      _ => throw const AppConfigurationException(
        'GOOGLE_AUTH_ENABLED deve essere true o false.',
      ),
    };
  }

  static String _canonicalStorefrontShopSlug(String value) {
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
      throw const AppConfigurationException(
        'STOREFRONT_SHOP_SLUG deve essere uno slug pubblico lowercase valido.',
      );
    }
    return value;
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
