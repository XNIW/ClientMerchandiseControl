import 'package:client_merchandise_control/features/storefront/presentation/storefront_verified_image_loader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final allowedUri = Uri.parse(
    'https://project.supabase.co/storage/v1/object/public/'
    'storefront-product-images/shop/product.webp',
  );

  test(
    'accetta solo origin e path pubblici esatti con digest valido',
    () async {
      final bytes = <int>[1, 2, 3, 4];
      var requests = 0;
      final loader = StorefrontVerifiedImageLoader(
        client: MockClient((request) async {
          requests++;
          return http.Response.bytes(
            bytes,
            200,
            headers: const {'content-type': 'image/webp'},
          );
        }),
        publicOrigin: Uri.parse('https://project.supabase.co'),
      );
      final digest = sha256.convert(bytes).toString();

      final first = await loader.load(uri: allowedUri, sha256Digest: digest);
      expect(first, bytes);
      first[0] = 99;
      expect(
        await loader.load(uri: allowedUri, sha256Digest: digest),
        bytes,
        reason: 'il consumer non deve poter corrompere la cache verificata',
      );
      expect(requests, 1, reason: 'il digest verificato deve usare la cache');

      for (final rejected in [
        Uri.parse(
          'https://evil.example/storage/v1/object/public/'
          'storefront-product-images/shop/product.webp',
        ),
        Uri.parse(
          'http://project.supabase.co/storage/v1/object/public/'
          'storefront-product-images/shop/product.webp',
        ),
        Uri.parse('https://project.supabase.co/arbitrary/product.webp'),
        Uri.parse('$allowedUri?redirect=https://evil.example'),
      ]) {
        await expectLater(
          loader.load(uri: rejected, sha256Digest: digest),
          throwsA(isA<StorefrontImageVerificationException>()),
        );
      }
      expect(requests, 1);
    },
  );

  test('rifiuta digest, MIME e redirect non verificabili', () async {
    final bytes = <int>[5, 6, 7];
    final digest = sha256.convert(bytes).toString();
    final responses = <http.Response>[
      http.Response('', 302, headers: {'location': allowedUri.toString()}),
      http.Response.bytes(bytes, 200, headers: {'content-type': 'text/html'}),
      http.Response.bytes(bytes, 200, headers: {'content-type': 'image/png'}),
    ];
    var index = 0;
    final loader = StorefrontVerifiedImageLoader(
      client: MockClient((request) async => responses[index++]),
      publicOrigin: Uri.parse('https://project.supabase.co'),
    );

    await expectLater(
      loader.load(uri: allowedUri, sha256Digest: digest),
      throwsA(isA<StorefrontImageVerificationException>()),
    );
    await expectLater(
      loader.load(uri: allowedUri, sha256Digest: digest),
      throwsA(isA<StorefrontImageVerificationException>()),
    );
    await expectLater(
      loader.load(
        uri: allowedUri,
        sha256Digest: List<String>.filled(64, '0').join(),
      ),
      throwsA(isA<StorefrontImageVerificationException>()),
    );
  });

  test('interrompe lo stream quando supera il limite prima del decode', () {
    final bytes = <int>[1, 2, 3, 4];
    final loader = StorefrontVerifiedImageLoader(
      client: MockClient(
        (request) async => http.Response.bytes(
          bytes,
          200,
          headers: {'content-type': 'image/png'},
        ),
      ),
      publicOrigin: Uri.parse('https://project.supabase.co'),
      maximumBytes: 3,
    );

    expect(
      loader.load(
        uri: allowedUri,
        sha256Digest: sha256.convert(bytes).toString(),
      ),
      throwsA(isA<StorefrontImageVerificationException>()),
    );
  });
}
