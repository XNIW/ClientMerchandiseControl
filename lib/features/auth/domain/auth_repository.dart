import 'authenticated_customer.dart';

enum AuthSessionEventType {
  initialSession,
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
}

enum AuthSignOutReason { userInitiated, sessionExpired, unknown }

final class AuthSessionEvent {
  const AuthSessionEvent({
    required this.type,
    required this.customer,
    this.signOutReason,
  });

  final AuthSessionEventType type;
  final AuthenticatedCustomer? customer;
  final AuthSignOutReason? signOutReason;
}

abstract interface class AuthRepository {
  AuthenticatedCustomer? get currentCustomer;

  Stream<AuthSessionEvent> get sessionChanges;

  /// Restituisce soltanto se il browser esterno è stato aperto.
  Future<bool> launchGoogleSignIn();

  Future<AuthenticatedCustomer> exchangeCodeForSession(String code);

  Future<void> clearPendingOAuth();

  /// Persiste l'intento e rende la sessione non ripristinabile prima di altri
  /// cleanup asincroni.
  Future<void> beginSignOut();

  /// Tenta la revoca globale, conserva un retry cifrato se necessario e
  /// completa sempre il logout locale.
  Future<void> completeSignOut();

  Future<void> retryPendingRemoteRevocations();

  /// Pulisce subito la sessione locale. Un errore remoto può essere rilanciato
  /// dopo la pulizia e non autorizza il ripristino dello stato authenticated.
  Future<void> signOutLocal();
}
