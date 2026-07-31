import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/secure_supabase_auth_storage.dart';
import '../../../core/config/app_environment.dart';
import '../domain/auth_failure.dart';

final class AuthErrorMapper {
  const AuthErrorMapper();

  AuthFailure map(Object error) {
    if (error is AuthStorageException) {
      return const AuthFailure(AuthFailureKind.secureStorageUnavailable);
    }
    if (error is AppConfigurationException) {
      return const AuthFailure(AuthFailureKind.configuration);
    }
    if (error is SocketException || error is TimeoutException) {
      return const AuthFailure(AuthFailureKind.offline);
    }
    if (error is AuthRetryableFetchException) {
      return const AuthFailure(AuthFailureKind.offline);
    }
    if (error is AuthApiException) {
      final status = int.tryParse(error.statusCode ?? '');
      if (status != null && status >= 500) {
        return const AuthFailure(AuthFailureKind.providerUnavailable);
      }
      return const AuthFailure(AuthFailureKind.unexpected);
    }
    if (error is AuthException) {
      return const AuthFailure(AuthFailureKind.unexpected);
    }
    if (error is PlatformException) {
      return const AuthFailure(AuthFailureKind.unexpected);
    }
    return const AuthFailure(AuthFailureKind.unexpected);
  }
}
