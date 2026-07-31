import '../domain/auth_failure.dart';

sealed class AuthCallbackValidation {
  const AuthCallbackValidation();
}

final class AuthCallbackAccepted extends AuthCallbackValidation {
  const AuthCallbackAccepted(this.code);

  final String code;
}

final class AuthCallbackProviderFailure extends AuthCallbackValidation {
  const AuthCallbackProviderFailure({required this.wasCancelled});

  final bool wasCancelled;
}

final class AuthCallbackRejected extends AuthCallbackValidation {
  const AuthCallbackRejected([
    this.failure = const AuthFailure(AuthFailureKind.invalidCallback),
  ]);

  final AuthFailure failure;
}

final class AuthCallbackValidator {
  const AuthCallbackValidator({
    required this.allowedScheme,
    required this.allowedHost,
    this.allowedPath = '/',
  });

  static const maxCodeLength = 2048;
  static const maxErrorLength = 512;

  static const _errorKeys = {'error', 'error_code', 'error_description'};

  final String allowedScheme;
  final String allowedHost;
  final String allowedPath;

  AuthCallbackValidation validate(Uri callback) {
    if (!callback.isAbsolute ||
        callback.scheme != allowedScheme ||
        callback.host != allowedHost ||
        callback.path != allowedPath ||
        callback.userInfo.isNotEmpty ||
        callback.hasPort ||
        callback.hasFragment) {
      return const AuthCallbackRejected();
    }

    final parameters = callback.queryParametersAll;
    if (parameters.isEmpty ||
        parameters.values.any((values) => values.length != 1)) {
      return const AuthCallbackRejected();
    }

    final keys = parameters.keys.toSet();
    if (keys.length == 1 && keys.single == 'code') {
      final code = parameters['code']!.single;
      return _isBoundedVisibleValue(
            code,
            maxLength: maxCodeLength,
            allowSpaces: false,
          )
          ? AuthCallbackAccepted(code)
          : const AuthCallbackRejected();
    }

    if (!keys.contains('error') ||
        keys.difference(_errorKeys).isNotEmpty ||
        keys.contains('code')) {
      return const AuthCallbackRejected();
    }

    for (final entry in parameters.entries) {
      final maxLength = entry.key == 'error' ? 128 : maxErrorLength;
      if (!_isBoundedVisibleValue(
        entry.value.single,
        maxLength: maxLength,
        allowSpaces: entry.key == 'error_description',
      )) {
        return const AuthCallbackRejected();
      }
    }

    final normalizedError = parameters['error']!.single.toLowerCase();
    return AuthCallbackProviderFailure(
      wasCancelled: const {
        'access_denied',
        'cancelled',
        'user_cancelled',
      }.contains(normalizedError),
    );
  }

  static bool _isBoundedVisibleValue(
    String value, {
    required int maxLength,
    required bool allowSpaces,
  }) {
    if (value.isEmpty ||
        value.length > maxLength ||
        value.trim().isEmpty ||
        value.trim() != value) {
      return false;
    }
    final minimumRune = allowSpaces ? 0x20 : 0x21;
    return value.runes.every((rune) => rune >= minimumRune && rune <= 0x7e);
  }
}
