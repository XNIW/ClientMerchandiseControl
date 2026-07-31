import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

enum AccountPresentationStatus { guest, authenticated }

@immutable
final class AccountPresentationModel {
  const AccountPresentationModel.guest()
    : status = AccountPresentationStatus.guest,
      displayName = null,
      email = null,
      avatarImage = null;

  const AccountPresentationModel.authenticated({
    this.displayName,
    this.email,
    this.avatarImage,
  }) : status = AccountPresentationStatus.authenticated;

  final AccountPresentationStatus status;
  final String? displayName;
  final String? email;
  final ImageProvider<Object>? avatarImage;

  bool get isAuthenticated => status == AccountPresentationStatus.authenticated;
}
