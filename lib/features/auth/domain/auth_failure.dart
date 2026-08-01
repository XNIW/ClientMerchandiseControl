import 'package:flutter/foundation.dart';

enum AuthFailureKind {
  offline,
  cancelled,
  providerUnavailable,
  browserLaunchFailed,
  invalidCallback,
  callbackAlreadyConsumed,
  sessionExpired,
  secureStorageUnavailable,
  configuration,
  unexpected,
}

@immutable
final class AuthFailure {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  bool get canRetry => switch (kind) {
    AuthFailureKind.offline ||
    AuthFailureKind.providerUnavailable ||
    AuthFailureKind.browserLaunchFailed ||
    AuthFailureKind.invalidCallback ||
    AuthFailureKind.sessionExpired ||
    AuthFailureKind.unexpected => true,
    AuthFailureKind.cancelled ||
    AuthFailureKind.callbackAlreadyConsumed ||
    AuthFailureKind.secureStorageUnavailable ||
    AuthFailureKind.configuration => false,
  };

  String get diagnosticCode => switch (kind) {
    AuthFailureKind.offline => 'AUTH_OFFLINE',
    AuthFailureKind.cancelled => 'AUTH_CANCELLED',
    AuthFailureKind.providerUnavailable => 'AUTH_PROVIDER_UNAVAILABLE',
    AuthFailureKind.browserLaunchFailed => 'AUTH_BROWSER_NOT_LAUNCHED',
    AuthFailureKind.invalidCallback => 'AUTH_CALLBACK_REJECTED',
    AuthFailureKind.callbackAlreadyConsumed => 'AUTH_CALLBACK_REPLAY',
    AuthFailureKind.sessionExpired => 'AUTH_SESSION_EXPIRED',
    AuthFailureKind.secureStorageUnavailable => 'AUTH_SECURE_STORAGE',
    AuthFailureKind.configuration => 'AUTH_CONFIGURATION',
    AuthFailureKind.unexpected => 'AUTH_UNEXPECTED',
  };

  @override
  bool operator ==(Object other) {
    return other is AuthFailure && other.kind == kind;
  }

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'AuthFailure($diagnosticCode)';
}
