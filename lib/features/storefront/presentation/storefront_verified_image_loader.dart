import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/backend/public_backend_http_client.dart';
import '../../../core/config/app_config.dart';

final storefrontVerifiedImageLoaderProvider =
    Provider<StorefrontVerifiedImageLoader>((ref) {
      final origin = ref.watch(appConfigProvider).supabaseUrl;
      return StorefrontVerifiedImageLoader(
        client: ref.watch(publicBackendHttpClientProvider),
        publicOrigin: origin == null ? null : Uri.parse(origin),
      );
    });

/// Carica soltanto immagini pubbliche appartenenti alla origin Supabase
/// configurata, applicando limiti prima della decodifica e verificando il digest
/// pubblicato dal contratto Storefront.
final class StorefrontVerifiedImageLoader {
  StorefrontVerifiedImageLoader({
    required this.client,
    required this.publicOrigin,
    this.maximumBytes = 5 * 1024 * 1024,
    this.downloadTimeout = const Duration(seconds: 8),
  });

  static const _publicImagePathPrefix =
      '/storage/v1/object/public/storefront-product-images/';

  final http.Client client;
  final Uri? publicOrigin;
  final int maximumBytes;
  final Duration downloadTimeout;
  final Map<String, Uint8List> _contentAddressedCache = {};

  Future<Uint8List> load({required Uri uri, required String sha256Digest}) {
    final normalizedDigest = sha256Digest.toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(normalizedDigest) ||
        !_isAllowedUri(uri)) {
      return Future<Uint8List>.error(
        const StorefrontImageVerificationException('image_identity_rejected'),
      );
    }
    final cached = _contentAddressedCache[normalizedDigest];
    if (cached != null) {
      return Future<Uint8List>.value(Uint8List.fromList(cached));
    }
    return _download(uri, normalizedDigest).timeout(downloadTimeout);
  }

  Future<Uint8List> _download(Uri uri, String expectedDigest) async {
    final request = http.Request('GET', uri)
      ..followRedirects = false
      ..maxRedirects = 0;
    final response = await client.send(request).timeout(downloadTimeout);
    final contentLength = response.contentLength;
    final contentType = response.headers['content-type']?.toLowerCase();
    if (response.statusCode != 200 ||
        (contentLength != null &&
            (contentLength < 1 || contentLength > maximumBytes)) ||
        contentType == null ||
        !contentType.startsWith('image/')) {
      throw const StorefrontImageVerificationException(
        'image_response_rejected',
      );
    }

    final stopwatch = Stopwatch()..start();
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream.timeout(downloadTimeout)) {
      if (stopwatch.elapsed > downloadTimeout ||
          bytes.length + chunk.length > maximumBytes) {
        throw const StorefrontImageVerificationException(
          'image_download_limit_exceeded',
        );
      }
      bytes.add(chunk);
    }
    final value = bytes.takeBytes();
    if (value.isEmpty || sha256.convert(value).toString() != expectedDigest) {
      throw const StorefrontImageVerificationException('image_digest_mismatch');
    }
    _contentAddressedCache[expectedDigest] = Uint8List.fromList(value);
    return Uint8List.fromList(value);
  }

  bool _isAllowedUri(Uri uri) {
    final origin = publicOrigin;
    if (origin == null) return false;
    return uri.scheme == 'https' &&
        uri.scheme == origin.scheme &&
        uri.host == origin.host &&
        uri.port == origin.port &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        uri.path.startsWith(_publicImagePathPrefix) &&
        uri.path.length > _publicImagePathPrefix.length;
  }
}

final class StorefrontImageVerificationException implements Exception {
  const StorefrontImageVerificationException(this.code);

  final String code;
}
