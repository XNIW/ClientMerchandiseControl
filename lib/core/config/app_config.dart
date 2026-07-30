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

    if (normalizedUrl != null) {
      final uri = Uri.tryParse(normalizedUrl);
      final isHttp = uri?.scheme == 'http' || uri?.scheme == 'https';
      if (uri == null || !uri.hasAuthority || !isHttp || uri.host.isEmpty) {
        throw const AppConfigurationException(
          'SUPABASE_URL deve essere un URL HTTP(S) assoluto valido.',
        );
      }
      if (environment != AppEnvironment.development && uri.scheme != 'https') {
        throw const AppConfigurationException(
          'Staging e production richiedono un URL HTTPS.',
        );
      }
    }

    return AppConfig._(
      environment: environment,
      supabaseUrl: normalizedUrl,
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
}

final appConfigProvider = Provider<AppConfig>((ref) {
  throw StateError('AppConfig deve essere fornito durante il bootstrap.');
});
