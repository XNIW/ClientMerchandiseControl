import 'dart:async';
import 'dart:convert';

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
    this.serializedSession,
    this.shouldRemovePersistedSession = false,
  });

  final SupabaseAuthChangeKind kind;
  final SupabaseIdentitySnapshot? identity;
  final SupabaseSignOutKind? signOutKind;
  final String? serializedSession;
  final bool shouldRemovePersistedSession;
}

final class SupabaseAuthExchange {
  const SupabaseAuthExchange({
    required this.identity,
    required this.serializedSession,
  });

  final SupabaseIdentitySnapshot? identity;
  final String serializedSession;
}

abstract interface class SupabaseAuthPort {
  SupabaseIdentitySnapshot? get currentIdentity;

  String? get serializedCurrentSession;

  Stream<SupabaseAuthChange> get changes;

  Future<bool> launchGoogleOAuth(String redirectUri);

  Future<SupabaseAuthExchange> exchangeCode(String code);

  Future<void> signOutLocal();

  Future<void> signOutGlobal();

  Future<void> revokeSerializedSession(String serializedSession);
}

final class PlatformSupabaseAuthPort implements SupabaseAuthPort {
  PlatformSupabaseAuthPort(this._client);

  final SupabaseClient _client;

  @override
  SupabaseIdentitySnapshot? get currentIdentity {
    return identityFromSession(_client.auth.currentSession);
  }

  @override
  String? get serializedCurrentSession {
    final session = _client.auth.currentSession;
    return session == null ? null : jsonEncode(session.toJson());
  }

  @override
  Stream<SupabaseAuthChange> get changes {
    return _client.auth.onAuthStateChange.map(mapSdkAuthChange);
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
  Future<SupabaseAuthExchange> exchangeCode(String code) async {
    final response = await _client.auth.exchangeCodeForSession(code);
    return SupabaseAuthExchange(
      identity: identityFromSession(response.session),
      serializedSession: jsonEncode(response.session.toJson()),
    );
  }

  @override
  Future<void> signOutLocal() {
    return _client.auth.signOut(scope: SignOutScope.local);
  }

  @override
  Future<void> signOutGlobal() {
    return _client.auth.signOut(scope: SignOutScope.global);
  }

  @override
  Future<void> revokeSerializedSession(String serializedSession) async {
    try {
      await _client.auth.recoverSession(serializedSession);
      await _client.auth.signOut(scope: SignOutScope.global);
    } finally {
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }

  static SupabaseAuthChange mapSdkAuthChange(AuthState sdkState) {
    final event = sdkState.event;
    final session = sdkState.session;
    if (session != null && !_isUsableSession(session)) {
      return SupabaseAuthChange(
        kind: SupabaseAuthChangeKind.signedOut,
        identity: null,
        signOutKind: SupabaseSignOutKind.sessionExpired,
        shouldRemovePersistedSession:
            event == AuthChangeEvent.signedOut ||
            !shouldPreserveForSdkRecovery(session),
      );
    }
    final kind = switch (event) {
      AuthChangeEvent.initialSession => SupabaseAuthChangeKind.initialSession,
      AuthChangeEvent.signedOut => SupabaseAuthChangeKind.signedOut,
      AuthChangeEvent.tokenRefreshed => SupabaseAuthChangeKind.tokenRefreshed,
      AuthChangeEvent.userUpdated => SupabaseAuthChangeKind.userUpdated,
      _ => SupabaseAuthChangeKind.signedIn,
    };

    return SupabaseAuthChange(
      kind: kind,
      identity: identityFromSession(session),
      signOutKind: switch (sdkState.signOutReason) {
        SignOutReason.userInitiated => SupabaseSignOutKind.userInitiated,
        SignOutReason.sessionExpired ||
        SignOutReason.sessionMissing => SupabaseSignOutKind.sessionExpired,
        null => null,
      },
      serializedSession: session == null ? null : jsonEncode(session.toJson()),
      shouldRemovePersistedSession: event == AuthChangeEvent.signedOut,
    );
  }

  static SupabaseIdentitySnapshot? identityFromSession(Session? session) {
    if (!_isUsableSession(session)) {
      return null;
    }
    return _identityFromUser(session!.user);
  }

  static bool _isUsableSession(Session? session) {
    return session != null && session.expiresAt != null && !session.isExpired;
  }

  static bool shouldPreserveForSdkRecovery(Session session) {
    return session.expiresAt != null &&
        session.isExpired &&
        (session.refreshToken?.isNotEmpty ?? false);
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
    if (_secureStorage.logoutRequested) return null;
    return _customerFromIdentity(_authPort.currentIdentity);
  }

  @override
  Stream<AuthSessionEvent> get sessionChanges {
    final authEvents = _authPort.changes.asyncMap(_mapSessionChange);
    return Stream<AuthSessionEvent>.multi((controller) {
      final authSubscription = authEvents.listen(
        controller.addSync,
        onError: controller.addErrorSync,
        onDone: controller.closeSync,
      );
      final storageSubscription = _secureStorage.failures.listen((failure) {
        controller.addErrorSync(failure, StackTrace.current);
      });
      controller.onCancel = () async {
        await authSubscription.cancel();
        await storageSubscription.cancel();
      };
    });
  }

  @override
  Future<bool> launchGoogleSignIn() async {
    await retryPendingRemoteRevocations();
    if ((await _secureStorage.pendingRemoteRevocations()).isNotEmpty ||
        await _secureStorage.pendingLogoutSession() != null) {
      throw const AuthRepositoryException('pending_remote_revocation');
    }
    return _authPort.launchGoogleOAuth(_redirectUri);
  }

  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async {
    final exchange = await _authPort.exchangeCode(code);
    try {
      await _secureStorage.persistExplicitLoginSession(
        exchange.serializedSession,
      );
    } on Object catch (error, stackTrace) {
      try {
        await signOutLocal();
      } on Object {
        // L'errore originale di persistenza è il segnale fail-closed prioritario.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
    final customer = _customerFromIdentity(exchange.identity);
    if (customer == null) {
      try {
        await signOutLocal();
      } on Object {
        // Il caller riceve comunque un errore chiuso senza dettagli SDK.
      }
      throw const AuthRepositoryException('missing_customer_session');
    }
    return customer;
  }

  @override
  Future<void> clearPendingOAuth() {
    return _secureStorage.clearPendingOAuth();
  }

  @override
  Future<void> beginSignOut() {
    return _secureStorage.beginLogoutIntent(_authPort.serializedCurrentSession);
  }

  @override
  Future<void> completeSignOut() async {
    var remoteRevoked = _authPort.serializedCurrentSession == null;
    try {
      await _authPort.signOutGlobal().timeout(const Duration(seconds: 12));
      remoteRevoked = true;
    } on Object {
      // finishLogout trasferisce la sessione nel retry cifrato e bounded.
    }
    try {
      await _authPort.signOutLocal();
    } on Object {
      // La rimozione autorevole dal client è eseguita comunque dallo storage.
    }
    await _secureStorage.finishLogout(remoteRevoked: remoteRevoked);
  }

  @override
  Future<void> retryPendingRemoteRevocations() async {
    var authContextTouched = false;
    final interruptedLogout = await _secureStorage.pendingLogoutSession();
    if (_secureStorage.logoutRequested) {
      var remoteRevoked = interruptedLogout == null;
      if (interruptedLogout != null) {
        authContextTouched = true;
        try {
          await _authPort
              .revokeSerializedSession(interruptedLogout)
              .timeout(const Duration(seconds: 12));
          remoteRevoked = true;
        } on Object {
          // finishLogout accoda la sessione cifrata per il retry successivo.
        }
      }
      try {
        await _authPort.signOutLocal();
      } on Object {
        // Il marker di logout continua a impedire il restore locale.
      }
      await _secureStorage.finishLogout(remoteRevoked: remoteRevoked);
    }

    final pending = await _secureStorage.pendingRemoteRevocations();
    for (final revocation in pending) {
      authContextTouched = true;
      try {
        await _authPort
            .revokeSerializedSession(revocation.session)
            .timeout(const Duration(seconds: 12));
        await _secureStorage.clearPendingRemoteRevocation(revocation.slot);
      } on Object {
        // Il record cifrato resta intatto per un successivo tentativo bounded.
      }
    }
    if (authContextTouched || _secureStorage.logoutRequested) {
      try {
        await _authPort.signOutLocal();
      } on Object {
        // Lo storage locale resta il confine fail-closed del restore.
      }
      await _secureStorage.removePersistedSession();
    }
  }

  @override
  Future<void> signOutLocal() async {
    Object? firstError;
    StackTrace? firstStackTrace;

    Future<void> capture(Future<void> Function() operation) async {
      try {
        await operation();
      } on Object catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }

    await capture(_authPort.signOutLocal);
    await capture(_secureStorage.removePersistedSession);
    await capture(_secureStorage.clearPendingOAuth);

    if (firstError case final error?) {
      Error.throwWithStackTrace(error, firstStackTrace!);
    }
  }

  Future<AuthSessionEvent> _mapSessionChange(SupabaseAuthChange change) async {
    if (_secureStorage.logoutRequested) {
      if (change.kind == SupabaseAuthChangeKind.signedOut &&
          change.shouldRemovePersistedSession) {
        await _secureStorage.removePersistedSession();
      }
      return AuthSessionEvent(
        type: change.kind == SupabaseAuthChangeKind.signedOut
            ? AuthSessionEventType.signedOut
            : AuthSessionEventType.initialSession,
        customer: null,
        signOutReason: change.signOutKind == SupabaseSignOutKind.sessionExpired
            ? AuthSignOutReason.sessionExpired
            : AuthSignOutReason.userInitiated,
      );
    }
    final serializedSession = change.serializedSession;
    if (serializedSession != null && change.identity != null) {
      await _secureStorage.persistSession(serializedSession);
    } else if (change.kind == SupabaseAuthChangeKind.signedOut &&
        change.shouldRemovePersistedSession) {
      await _secureStorage.removePersistedSession();
    }

    return AuthSessionEvent(
      type: switch (change.kind) {
        SupabaseAuthChangeKind.initialSession =>
          AuthSessionEventType.initialSession,
        SupabaseAuthChangeKind.signedIn => AuthSessionEventType.signedIn,
        SupabaseAuthChangeKind.signedOut => AuthSessionEventType.signedOut,
        SupabaseAuthChangeKind.tokenRefreshed =>
          AuthSessionEventType.tokenRefreshed,
        SupabaseAuthChangeKind.userUpdated => AuthSessionEventType.userUpdated,
      },
      customer: _customerFromIdentity(change.identity),
      signOutReason: switch (change.signOutKind) {
        SupabaseSignOutKind.userInitiated => AuthSignOutReason.userInitiated,
        SupabaseSignOutKind.sessionExpired => AuthSignOutReason.sessionExpired,
        SupabaseSignOutKind.unknown => AuthSignOutReason.unknown,
        null => null,
      },
    );
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
