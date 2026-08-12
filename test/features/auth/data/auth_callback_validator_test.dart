import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final canonical = Uri.parse(AppConfig.allowedAuthRedirectUri);
  final validator = AuthCallbackValidator(
    allowedScheme: canonical.scheme,
    allowedHost: canonical.host,
    allowedPath: canonical.path,
  );

  test('accetta soltanto un code PKCE bounded', () {
    final result = validator.validate(
      Uri.parse('${AppConfig.allowedAuthRedirectUri}?code=valid-code_123'),
    );

    expect(result, isA<AuthCallbackAccepted>());
    expect((result as AuthCallbackAccepted).code, 'valid-code_123');
  });

  test('classifica cancellazione provider senza esporre descrizione', () {
    final result = validator.validate(
      Uri.parse(
        '${AppConfig.allowedAuthRedirectUri}'
        '?error=access_denied'
        '&error_code=oauth_cancelled'
        '&error_description=User%20cancelled',
      ),
    );

    expect(
      result,
      isA<AuthCallbackProviderFailure>().having(
        (failure) => failure.wasCancelled,
        'wasCancelled',
        isTrue,
      ),
    );
  });

  test('classifica errore provider sconosciuto come non-cancellazione', () {
    final result = validator.validate(
      Uri.parse(
        '${AppConfig.allowedAuthRedirectUri}?error=temporarily_unavailable',
      ),
    );

    expect(
      result,
      isA<AuthCallbackProviderFailure>().having(
        (failure) => failure.wasCancelled,
        'wasCancelled',
        isFalse,
      ),
    );
  });

  test('rifiuta origini, componenti e payload non canonici', () {
    final tooLongCode = List.filled(
      AuthCallbackValidator.maxCodeLength + 1,
      'a',
    ).join();
    final invalidCallbacks = <String>[
      'other.scheme://auth-callback/?code=valid-code',
      'http://clientmerchandisecontrol.invalid/auth-callback/?code=valid-code',
      'https://other.invalid/auth-callback/?code=valid-code',
      'https://clientmerchandisecontrol.invalid/other/?code=valid-code',
      'https://clientmerchandisecontrol.invalid/auth-callback?code=valid-code',
      'https://user@clientmerchandisecontrol.invalid/auth-callback/?code=valid-code',
      'https://clientmerchandisecontrol.invalid:8443/auth-callback/?code=valid-code',
      '${AppConfig.allowedAuthRedirectUri}?code=valid-code#fragment',
      AppConfig.allowedAuthRedirectUri,
      '${AppConfig.allowedAuthRedirectUri}?code=',
      '${AppConfig.allowedAuthRedirectUri}?code=a&code=b',
      '${AppConfig.allowedAuthRedirectUri}?code=valid-code&state=unexpected',
      '${AppConfig.allowedAuthRedirectUri}?code=valid%20code',
      '${AppConfig.allowedAuthRedirectUri}?code=valid%0Acode',
      '${AppConfig.allowedAuthRedirectUri}?code=$tooLongCode',
      '${AppConfig.allowedAuthRedirectUri}?code=valid-code&error=access_denied',
      '${AppConfig.allowedAuthRedirectUri}?access_token=implicit-token',
      '${AppConfig.allowedAuthRedirectUri}#access_token=implicit-token',
      '${AppConfig.allowedAuthRedirectUri}?refresh_token=implicit-token',
      '${AppConfig.allowedAuthRedirectUri}?provider_token=implicit-token',
      '${AppConfig.allowedAuthRedirectUri}?error=access_denied&extra=value',
      '${AppConfig.allowedAuthRedirectUri}?error=',
      '${AppConfig.allowedAuthRedirectUri}?error=access_denied&error=cancelled',
      '${AppConfig.allowedAuthRedirectUri}?error=access_denied'
          '&error_description=%20%20',
    ];

    for (final callback in invalidCallbacks) {
      expect(
        validator.validate(Uri.parse(callback)),
        isA<AuthCallbackRejected>(),
        reason: callback.split('?').first,
      );
    }
  });
}
