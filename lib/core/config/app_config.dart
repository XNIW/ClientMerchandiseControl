import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_environment.dart';
import 'release_config_attestation.dart';

class AppConfig {
  static const allowedAuthRedirectUri =
      'https://clientmerchandisecontrol.invalid/auth-callback/';
  static const _compiledAppEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const _compiledSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _compiledSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _compiledAuthRedirectUri = String.fromEnvironment(
    'AUTH_REDIRECT_URI',
  );
  static const _compiledGoogleAuthEnabled = String.fromEnvironment(
    'GOOGLE_AUTH_ENABLED',
  );
  static const _compiledStorefrontShopSlug = String.fromEnvironment(
    'STOREFRONT_SHOP_SLUG',
  );
  static const _compiledDeliveryMapsEnabled = String.fromEnvironment(
    'DELIVERY_MAPS_ENABLED',
  );
  static const _compiledDeliveryMapsNativeConfigured = String.fromEnvironment(
    'DELIVERY_MAPS_NATIVE_CONFIGURED',
  );
  static const _compiledReleaseConfigSha256 = String.fromEnvironment(
    'RELEASE_CONFIG_SHA256',
  );
  static const _compiledReleaseAttestationMarker =
      '${ReleaseConfigAttestation.markerPrefix}$_compiledReleaseConfigSha256';

  const AppConfig._({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.authRedirectUri,
    required this.googleAuthEnabled,
    required this.storefrontShopSlug,
    required this.releaseConfigSha256,
  });

  /// Configurazione esclusiva degli harness che verificano il lifecycle OAuth
  /// senza registrare callback native o contattare provider reali.
  @visibleForTesting
  factory AppConfig.authFlowTest({
    String supabaseUrl = 'https://project.example.invalid',
    String supabasePublishableKey = 'sb_publishable_test_key',
    String storefrontShopSlug = 'storefront-test',
  }) {
    final safeBase = AppConfig.fromValues(
      appEnvironment: 'staging',
      supabaseUrl: supabaseUrl,
      supabasePublishableKey: supabasePublishableKey,
      authRedirectUri: allowedAuthRedirectUri,
      googleAuthEnabled: 'false',
      storefrontShopSlug: storefrontShopSlug,
    );
    return AppConfig._(
      environment: safeBase.environment,
      supabaseUrl: safeBase.supabaseUrl,
      supabasePublishableKey: safeBase.supabasePublishableKey,
      authRedirectUri: safeBase.authRedirectUri,
      googleAuthEnabled: true,
      storefrontShopSlug: safeBase.storefrontShopSlug,
      releaseConfigSha256: safeBase.releaseConfigSha256,
    );
  }

  factory AppConfig.fromValues({
    String appEnvironment = 'development',
    String supabaseUrl = '',
    String supabasePublishableKey = '',
    String authRedirectUri = '',
    String googleAuthEnabled = '',
    String storefrontShopSlug = '',
    String releaseConfigSha256 = '',
  }) {
    final environment = AppEnvironment.parse(appEnvironment);
    final normalizedUrl = _normalize(supabaseUrl);
    final normalizedKey = _normalize(supabasePublishableKey);
    final rawRedirectUri = authRedirectUri.isEmpty ? null : authRedirectUri;
    final normalizedGoogleAuthEnabled = _normalize(googleAuthEnabled);
    final normalizedStorefrontShopSlug = _normalize(storefrontShopSlug);
    final normalizedReleaseConfigSha256 = _normalize(releaseConfigSha256);

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
            canonicalStorefrontShopSlug != null ||
            normalizedReleaseConfigSha256 != null) {
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
        if (googleAuth) {
          throw const AppConfigurationException(
            'Google OAuth resta disabilitato finché non è configurato un dominio HTTPS posseduto e verificato.',
          );
        }
        if (normalizedReleaseConfigSha256 != null) {
          throw const AppConfigurationException(
            'RELEASE_CONFIG_SHA256 è ammesso soltanto in production.',
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
        if (normalizedReleaseConfigSha256 == null ||
            !RegExp(
              r'^[0-9a-f]{64}$',
            ).hasMatch(normalizedReleaseConfigSha256)) {
          throw const AppConfigurationException(
            'RELEASE_CONFIG_SHA256 deve attestare la configurazione production compilata.',
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
      releaseConfigSha256: normalizedReleaseConfigSha256,
    );
  }

  factory AppConfig.fromEnvironment() {
    final config = AppConfig.fromValues(
      appEnvironment: _compiledAppEnvironment,
      supabaseUrl: _compiledSupabaseUrl,
      supabasePublishableKey: _compiledSupabasePublishableKey,
      authRedirectUri: _compiledAuthRedirectUri,
      googleAuthEnabled: _compiledGoogleAuthEnabled,
      storefrontShopSlug: _compiledStorefrontShopSlug,
      releaseConfigSha256: _compiledReleaseConfigSha256,
    );
    if (config.environment != AppEnvironment.production) {
      return config;
    }
    try {
      final attestation = ReleaseConfigAttestation.fromValues({
        'APP_ENV': _compiledAppEnvironment,
        'SUPABASE_URL': _compiledSupabaseUrl,
        'SUPABASE_PUBLISHABLE_KEY': _compiledSupabasePublishableKey,
        'AUTH_REDIRECT_URI': _compiledAuthRedirectUri,
        'GOOGLE_AUTH_ENABLED': _compiledGoogleAuthEnabled,
        'STOREFRONT_SHOP_SLUG': _compiledStorefrontShopSlug,
        'DELIVERY_MAPS_ENABLED': _compiledDeliveryMapsEnabled,
        'DELIVERY_MAPS_NATIVE_CONFIGURED':
            _compiledDeliveryMapsNativeConfigured,
      });
      if (config.releaseConfigSha256 != attestation.sha256 ||
          _compiledReleaseAttestationMarker != attestation.marker) {
        throw const AppConfigurationException(
          'RELEASE_CONFIG_SHA256 non corrisponde alla configurazione production compilata.',
        );
      }
    } on ReleaseConfigValidationException {
      throw const AppConfigurationException(
        'La configurazione production compilata non supera l’attestazione semantica.',
      );
    }
    return config;
  }

  final AppEnvironment environment;
  final String? supabaseUrl;
  final String? supabasePublishableKey;
  final String? authRedirectUri;
  final bool googleAuthEnabled;
  final String? storefrontShopSlug;
  final String? releaseConfigSha256;

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
    'releaseConfigurationAttested': releaseConfigSha256 != null,
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
      return ReleaseConfigAttestation.canonicalSupabaseOrigin(value);
    } on ReleaseConfigValidationException {
      throw const AppConfigurationException(
        'SUPABASE_URL deve essere una origin HTTPS valida.',
      );
    }
  }

  static String _canonicalAuthRedirectUri(String value) {
    try {
      return ReleaseConfigAttestation.canonicalAuthRedirectUri(value);
    } on ReleaseConfigValidationException {
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
    try {
      return ReleaseConfigAttestation.canonicalShopSlug(value);
    } on ReleaseConfigValidationException {
      throw const AppConfigurationException(
        'STOREFRONT_SHOP_SLUG deve essere uno slug pubblico lowercase valido.',
      );
    }
  }

  static bool _isPublishableKeyAllowed(String value) {
    return ReleaseConfigAttestation.isPublishableKeyAllowed(value);
  }
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig deve essere fornito durante il bootstrap.');
});
