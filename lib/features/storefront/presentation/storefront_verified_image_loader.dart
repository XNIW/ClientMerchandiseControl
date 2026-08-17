import 'dart:async';
import 'dart:collection';
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
    this.maximumCacheBytes = 24 * 1024 * 1024,
    this.maximumCacheEntries = 64,
    this.downloadTimeout = const Duration(seconds: 8),
  }) {
    if (maximumBytes < 1 ||
        maximumCacheBytes < 1 ||
        maximumCacheEntries < 1 ||
        downloadTimeout <= Duration.zero) {
      throw ArgumentError('image_loader_limits');
    }
  }

  static const _publicImagePathPrefix =
      '/storage/v1/object/public/storefront-product-images/';

  final http.Client client;
  final Uri? publicOrigin;
  final int maximumBytes;
  final int maximumCacheBytes;
  final int maximumCacheEntries;
  final Duration downloadTimeout;
  final LinkedHashMap<String, Uint8List> _contentAddressedCache =
      LinkedHashMap<String, Uint8List>();
  final Map<String, Future<Uint8List>> _inFlight = {};
  int _cachedBytes = 0;

  Future<Uint8List> load({required Uri uri, required String sha256Digest}) {
    final normalizedDigest = sha256Digest.toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(normalizedDigest) ||
        !_isAllowedUri(uri)) {
      return Future<Uint8List>.error(
        const StorefrontImageVerificationException('image_identity_rejected'),
      );
    }
    final cached = _contentAddressedCache.remove(normalizedDigest);
    if (cached != null) {
      _contentAddressedCache[normalizedDigest] = cached;
      return Future<Uint8List>.value(Uint8List.fromList(cached));
    }
    final active = _inFlight[normalizedDigest];
    if (active != null) return active.then(Uint8List.fromList);

    final download = _download(uri, normalizedDigest);
    _inFlight[normalizedDigest] = download;
    return download.then(Uint8List.fromList).whenComplete(() {
      if (identical(_inFlight[normalizedDigest], download)) {
        _inFlight.remove(normalizedDigest);
      }
    });
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
    _store(expectedDigest, value);
    return value;
  }

  void _store(String digest, Uint8List value) {
    if (value.lengthInBytes > maximumCacheBytes) return;
    final previous = _contentAddressedCache.remove(digest);
    if (previous != null) _cachedBytes -= previous.lengthInBytes;
    final retained = Uint8List.fromList(value);
    _contentAddressedCache[digest] = retained;
    _cachedBytes += retained.lengthInBytes;
    while (_contentAddressedCache.length > maximumCacheEntries ||
        _cachedBytes > maximumCacheBytes) {
      final oldestDigest = _contentAddressedCache.keys.first;
      final removed = _contentAddressedCache.remove(oldestDigest);
      if (removed != null) _cachedBytes -= removed.lengthInBytes;
    }
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
