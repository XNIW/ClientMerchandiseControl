import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/secure_supabase_auth_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/authenticated_customer.dart';

enum SupabaseAuthChangeKind {
  initialSession,
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
}

enum SupabaseSignOutKind { userInitiated, sessionExpired, unknown }

final class SupabaseIdentitySnapshot {
  const SupabaseIdentitySnapshot({
    required this.subjectId,
    required this.email,
    required this.metadata,
  });

  final String subjectId;
  final String? email;
  final Map<String, Object?> metadata;
}

final class SupabaseAuthChange {
  const SupabaseAuthChange({
    required this.kind,
    required this.identity,
    this.signOutKind,
  });

  final SupabaseAuthChangeKind kind;
  final SupabaseIdentitySnapshot? identity;
  final SupabaseSignOutKind? signOutKind;
}

abstract interface class SupabaseAuthPort {
  SupabaseIdentitySnapshot? get currentIdentity;

  Stream<SupabaseAuthChange> get changes;

  Future<bool> launchGoogleOAuth(String redirectUri);

  Future<SupabaseIdentitySnapshot?> exchangeCode(String code);

  Future<void> signOutLocal();
}

final class PlatformSupabaseAuthPort implements SupabaseAuthPort {
  PlatformSupabaseAuthPort(this._client);

  final SupabaseClient _client;

  @override
  SupabaseIdentitySnapshot? get currentIdentity {
    return _identityFromUser(_client.auth.currentSession?.user);
  }

  @override
  Stream<SupabaseAuthChange> get changes {
    return _client.auth.onAuthStateChange.map(_mapAuthChange);
  }

  @override
  Future<bool> launchGoogleOAuth(String redirectUri) {
    return _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUri,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  @override
  Future<SupabaseIdentitySnapshot?> exchangeCode(String code) async {
    final response = await _client.auth.exchangeCodeForSession(code);
    return _identityFromUser(response.session.user);
  }

  @override
  Future<void> signOutLocal() {
    return _client.auth.signOut(scope: SignOutScope.local);
  }

  static SupabaseAuthChange _mapAuthChange(AuthState sdkState) {
    final event = sdkState.event;
    final kind = switch (event) {
      AuthChangeEvent.initialSession => SupabaseAuthChangeKind.initialSession,
      AuthChangeEvent.signedOut => SupabaseAuthChangeKind.signedOut,
      AuthChangeEvent.tokenRefreshed => SupabaseAuthChangeKind.tokenRefreshed,
      AuthChangeEvent.userUpdated => SupabaseAuthChangeKind.userUpdated,
      _ => SupabaseAuthChangeKind.signedIn,
    };

    return SupabaseAuthChange(
      kind: kind,
      identity: _identityFromUser(sdkState.session?.user),
      signOutKind: switch (sdkState.signOutReason) {
        SignOutReason.userInitiated => SupabaseSignOutKind.userInitiated,
        SignOutReason.sessionExpired ||
        SignOutReason.sessionMissing => SupabaseSignOutKind.sessionExpired,
        null => null,
      },
    );
  }

  static SupabaseIdentitySnapshot? _identityFromUser(User? user) {
    if (user == null) {
      return null;
    }
    return SupabaseIdentitySnapshot(
      subjectId: user.id,
      email: user.email,
      metadata: Map<String, Object?>.unmodifiable(
        user.userMetadata ?? const <String, Object?>{},
      ),
    );
  }
}

final class SupabaseAuthRepository implements AuthRepository {
  factory SupabaseAuthRepository({
    required SupabaseAuthPort authPort,
    required SecureSupabaseAuthStorage secureStorage,
    required String redirectUri,
  }) {
    return SupabaseAuthRepository._(authPort, secureStorage, redirectUri);
  }

  SupabaseAuthRepository._(
    this._authPort,
    this._secureStorage,
    this._redirectUri,
  );

  final SupabaseAuthPort _authPort;
  final SecureSupabaseAuthStorage _secureStorage;
  final String _redirectUri;

  @override
  AuthenticatedCustomer? get currentCustomer {
    return _customerFromIdentity(_authPort.currentIdentity);
  }

  @override
  Stream<AuthSessionEvent> get sessionChanges {
    return _authPort.changes.map((change) {
      return AuthSessionEvent(
        type: switch (change.kind) {
          SupabaseAuthChangeKind.initialSession =>
            AuthSessionEventType.initialSession,
          SupabaseAuthChangeKind.signedIn => AuthSessionEventType.signedIn,
          SupabaseAuthChangeKind.signedOut => AuthSessionEventType.signedOut,
          SupabaseAuthChangeKind.tokenRefreshed =>
            AuthSessionEventType.tokenRefreshed,
          SupabaseAuthChangeKind.userUpdated =>
            AuthSessionEventType.userUpdated,
        },
        customer: _customerFromIdentity(change.identity),
        signOutReason: switch (change.signOutKind) {
          SupabaseSignOutKind.userInitiated => AuthSignOutReason.userInitiated,
          SupabaseSignOutKind.sessionExpired =>
            AuthSignOutReason.sessionExpired,
          SupabaseSignOutKind.unknown => AuthSignOutReason.unknown,
          null => null,
        },
      );
    });
  }

  @override
  Future<bool> launchGoogleSignIn() {
    return _authPort.launchGoogleOAuth(_redirectUri);
  }

  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async {
    final identity = await _authPort.exchangeCode(code);
    final customer = _customerFromIdentity(identity);
    if (customer == null) {
      throw const AuthRepositoryException('missing_customer_session');
    }
    return customer;
  }

  @override
  Future<void> clearPendingOAuth() {
    return _secureStorage.clearPendingOAuth();
  }

  @override
  Future<void> signOutLocal() async {
    Object? signOutError;
    StackTrace? signOutStackTrace;
    try {
      await _authPort.signOutLocal();
    } on Object catch (error, stackTrace) {
      signOutError = error;
      signOutStackTrace = stackTrace;
    }

    await _secureStorage.removePersistedSession();
    await _secureStorage.clearPendingOAuth();

    if (signOutError != null) {
      Error.throwWithStackTrace(signOutError, signOutStackTrace!);
    }
  }

  static AuthenticatedCustomer? _customerFromIdentity(
    SupabaseIdentitySnapshot? identity,
  ) {
    if (identity == null) {
      return null;
    }
    try {
      return AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: identity.subjectId,
        email: identity.email,
        metadata: identity.metadata,
      );
    } on FormatException {
      return null;
    }
  }
}

final class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.code);

  final String code;

  @override
  String toString() => 'AuthRepositoryException($code)';
}
