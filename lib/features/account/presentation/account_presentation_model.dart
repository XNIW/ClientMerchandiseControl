import 'package:flutter/foundation.dart';

@immutable
final class AuthenticatedAccountPresentationModel {
  AuthenticatedAccountPresentationModel({
    this.displayName,
    this.email,
    Uint8List? avatarBytes,
  }) : _avatarBytes = _validatedAvatarBytes(avatarBytes);

  static const maxAvatarBytes = 512 * 1024;

  final String? displayName;
  final String? email;
  final Uint8List? _avatarBytes;

  Uint8List? get avatarBytes {
    final bytes = _avatarBytes;
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  static Uint8List? _validatedAvatarBytes(Uint8List? bytes) {
    if (bytes == null) {
      return null;
    }
    if (bytes.isEmpty || bytes.length > maxAvatarBytes) {
      throw ArgumentError.value(
        bytes.length,
        'avatarBytes.length',
        'Avatar bytes must contain between 1 and $maxAvatarBytes bytes.',
      );
    }
    return Uint8List.fromList(bytes);
  }
}
