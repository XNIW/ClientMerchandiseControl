import 'dart:async';
import 'dart:io';

import 'package:client_merchandise_control/core/backend/secure_supabase_auth_storage.dart';
import 'package:client_merchandise_control/core/config/app_environment.dart';
import 'package:client_merchandise_control/features/auth/data/auth_error_mapper.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_failure.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const mapper = AuthErrorMapper();
  const sentinel = 'SECRET_TOKEN_EMAIL_CALLBACK_SENTINEL';

  test('mappa rete e retry Supabase senza messaggi originali', () {
    final failures = [
      mapper.map(const SocketException(sentinel)),
      mapper.map(TimeoutException(sentinel)),
      mapper.map(AuthRetryableFetchException(message: sentinel)),
    ];

    for (final failure in failures) {
      expect(failure.kind, AuthFailureKind.offline);
      expect(failure.toString(), isNot(contains(sentinel)));
    }
  });

  test('mappa storage e configurazione come errori chiusi', () {
    final storage = mapper.map(const AuthStorageException(sentinel));
    final configuration = mapper.map(const AppConfigurationException(sentinel));

    expect(storage.kind, AuthFailureKind.secureStorageUnavailable);
    expect(configuration.kind, AuthFailureKind.configuration);
    expect(storage.toString(), isNot(contains(sentinel)));
    expect(configuration.toString(), isNot(contains(sentinel)));
  });

  test('mappa provider 5xx e altri errori in categorie stabili', () {
    final provider = mapper.map(
      const AuthApiException(sentinel, statusCode: '503'),
    );
    final auth = mapper.map(const AuthException(sentinel));
    final platform = mapper.map(
      PlatformException(code: 'auth', message: sentinel),
    );
    final unexpected = mapper.map(StateError(sentinel));

    expect(provider.kind, AuthFailureKind.providerUnavailable);
    expect(auth.kind, AuthFailureKind.unexpected);
    expect(platform.kind, AuthFailureKind.unexpected);
    expect(unexpected.kind, AuthFailureKind.unexpected);
    for (final failure in [provider, auth, platform, unexpected]) {
      expect(failure.toString(), isNot(contains(sentinel)));
    }
  });
}
