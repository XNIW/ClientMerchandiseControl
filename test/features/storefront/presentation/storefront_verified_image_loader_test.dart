import 'dart:async';

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

  test('cache LRU resta bounded per entry e byte', () async {
    final payloads = <String, List<int>>{
      'one.webp': [1, 1],
      'two.webp': [2, 2],
      'three.webp': [3, 3],
    };
    var requests = 0;
    final loader = StorefrontVerifiedImageLoader(
      client: MockClient((request) async {
        requests++;
        return http.Response.bytes(
          payloads[request.url.pathSegments.last]!,
          200,
          headers: const {'content-type': 'image/webp'},
        );
      }),
      publicOrigin: Uri.parse('https://project.supabase.co'),
      maximumCacheEntries: 2,
      maximumCacheBytes: 4,
    );

    for (final entry in payloads.entries) {
      await loader.load(
        uri: allowedUri.resolve(entry.key),
        sha256Digest: sha256.convert(entry.value).toString(),
      );
    }
    expect(requests, 3);

    await loader.load(
      uri: allowedUri.resolve('one.webp'),
      sha256Digest: sha256.convert(payloads['one.webp']!).toString(),
    );
    expect(
      requests,
      4,
      reason: "l'elemento LRU deve essere scaricato di nuovo dopo eviction",
    );
  });

  test(
    'stress 256 immagini mantiene soltanto la finestra LRU configurata',
    () async {
      final payloads = List.generate(
        256,
        (index) => List<int>.filled(1024, index),
        growable: false,
      );
      var requests = 0;
      final loader = StorefrontVerifiedImageLoader(
        client: MockClient((request) async {
          requests++;
          final index = int.parse(
            request.url.pathSegments.last.replaceAll('.webp', ''),
          );
          return http.Response.bytes(
            payloads[index],
            200,
            headers: const {'content-type': 'image/webp'},
          );
        }),
        publicOrigin: Uri.parse('https://project.supabase.co'),
        maximumCacheEntries: 16,
        maximumCacheBytes: 16 * 1024,
      );

      for (var index = 0; index < payloads.length; index++) {
        await loader.load(
          uri: allowedUri.resolve('$index.webp'),
          sha256Digest: sha256.convert(payloads[index]).toString(),
        );
      }
      expect(requests, payloads.length);

      await loader.load(
        uri: allowedUri.resolve('255.webp'),
        sha256Digest: sha256.convert(payloads.last).toString(),
      );
      expect(requests, payloads.length, reason: 'la entry MRU resta cached');

      await loader.load(
        uri: allowedUri.resolve('0.webp'),
        sha256Digest: sha256.convert(payloads.first).toString(),
      );
      expect(
        requests,
        payloads.length + 1,
        reason: 'la entry più vecchia è stata realmente espulsa',
      );
    },
  );

  test(
    'download concorrenti dello stesso digest condividono una request',
    () async {
      final bytes = <int>[9, 8, 7, 6];
      final response = Completer<http.Response>();
      var requests = 0;
      final loader = StorefrontVerifiedImageLoader(
        client: MockClient((request) {
          requests++;
          return response.future;
        }),
        publicOrigin: Uri.parse('https://project.supabase.co'),
      );
      final digest = sha256.convert(bytes).toString();

      final first = loader.load(uri: allowedUri, sha256Digest: digest);
      final second = loader.load(uri: allowedUri, sha256Digest: digest);
      await Future<void>.delayed(Duration.zero);
      expect(requests, 1);
      response.complete(
        http.Response.bytes(
          bytes,
          200,
          headers: const {'content-type': 'image/webp'},
        ),
      );

      final results = await Future.wait([first, second]);
      expect(results, everyElement(bytes));
      results.first[0] = 0;
      expect(
        results.last,
        bytes,
        reason: 'ogni consumer riceve una copia isolata',
      );
    },
  );

  test('failure single-flight viene rimossa e consente retry', () async {
    final bytes = <int>[4, 3, 2, 1];
    var requests = 0;
    final loader = StorefrontVerifiedImageLoader(
      client: MockClient((request) async {
        requests++;
        if (requests == 1) return http.Response('', 503);
        return http.Response.bytes(
          bytes,
          200,
          headers: const {'content-type': 'image/webp'},
        );
      }),
      publicOrigin: Uri.parse('https://project.supabase.co'),
    );
    final digest = sha256.convert(bytes).toString();

    await expectLater(
      loader.load(uri: allowedUri, sha256Digest: digest),
      throwsA(isA<StorefrontImageVerificationException>()),
    );
    expect(await loader.load(uri: allowedUri, sha256Digest: digest), bytes);
    expect(requests, 2);
  });

  test('rifiuta configurazioni cache non bounded', () {
    expect(
      () => StorefrontVerifiedImageLoader(
        client: MockClient((request) async => http.Response('', 500)),
        publicOrigin: Uri.parse('https://project.supabase.co'),
        maximumCacheEntries: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => StorefrontVerifiedImageLoader(
        client: MockClient((request) async => http.Response('', 500)),
        publicOrigin: Uri.parse('https://project.supabase.co'),
        maximumCacheBytes: 0,
      ),
      throwsArgumentError,
    );
  });
}
