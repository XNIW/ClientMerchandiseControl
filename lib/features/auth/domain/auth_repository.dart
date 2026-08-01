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

  /// Pulisce subito la sessione locale. Un errore remoto può essere rilanciato
  /// dopo la pulizia e non autorizza il ripristino dello stato authenticated.
  Future<void> signOutLocal();
}
