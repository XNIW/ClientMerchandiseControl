import 'package:flutter/foundation.dart';

import 'auth_failure.dart';
import 'authenticated_customer.dart';

enum AuthSessionOrigin { restored, callback, stateChange }

sealed class AuthState {
  const AuthState();

  bool get isBusy =>
      this is AuthAuthenticating ||
      this is AuthCancelling ||
      this is AuthSigningOut;
}

@immutable
final class AuthGuest extends AuthState {
  const AuthGuest({required this.canAuthenticate, this.notice});

  final bool canAuthenticate;
  final AuthFailure? notice;
}

@immutable
final class AuthAuthenticating extends AuthState {
  const AuthAuthenticating();
}

@immutable
final class AuthCancelling extends AuthState {
  const AuthCancelling();
}

@immutable
final class AuthCancelled extends AuthState {
  const AuthCancelled();
}

@immutable
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.customer, required this.origin});

  final AuthenticatedCustomer customer;
  final AuthSessionOrigin origin;
}

@immutable
final class AuthSigningOut extends AuthState {
  const AuthSigningOut(this.customer);

  final AuthenticatedCustomer customer;
}

@immutable
final class AuthRecoverableError extends AuthState {
  const AuthRecoverableError(this.failure);

  final AuthFailure failure;
}

@immutable
final class AuthConfigurationError extends AuthState {
  const AuthConfigurationError(this.failure);

  final AuthFailure failure;
}
