import 'package:client_merchandise_control/features/storefront/data/storefront_home_dto.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storefront_test_fixture.dart';

void main() {
  test('decodifica soltanto il contratto pubblico Home v1', () {
    final payload = validStorefrontHomePayload();
    (payload['categories'] as List).single['slug'] = 'te';
    ((payload['offers'] as List).single as Map)['category']['slug'] = 'te';
    final result = StorefrontHomeDto.decode(payload);

    expect(result.catalogVersion, 7);
    expect(result.settings.shopSlug, 'storefront-test');
    expect(result.categories.single.name, 'Bebidas');
    expect(result.featured.single.name, 'Café destacado');
    expect(result.offers.single.priceClp, 1200);
    expect(result.offers.single.compareAtPriceClp, 1500);
    expect(result.offers.single.images?.card.scheme, 'https');
    expect(result.offers.single.category.slug, 'te');
    expect(result.featured.single.category.sortRank, 0);
  });

  test('rifiuta slug categoria di un solo carattere', () {
    final payload = validStorefrontHomePayload();
    (payload['categories'] as List).single['slug'] = 't';

    expect(
      () => StorefrontHomeDto.decode(payload),
      throwsA(isA<StorefrontFailure>()),
    );
  });

  test('mappa unavailable e rifiuta versione API/catalog incoerente', () {
    expect(
      () => StorefrontHomeDto.decode({
        'status': 'unavailable',
        'apiVersion': 'storefront.v1',
      }),
      throwsA(
        isA<StorefrontFailure>().having(
          (failure) => failure.kind,
          'kind',
          StorefrontFailureKind.unavailable,
        ),
      ),
    );

    for (final mutate in <void Function(Map<String, Object?>)>[
      (payload) => payload['apiVersion'] = 'storefront.v2',
      (payload) =>
          ((payload['featured'] as List).single as Map)['catalogVersion'] = 8,
    ]) {
      final payload = validStorefrontHomePayload();
      mutate(payload);
      expect(
        () => StorefrontHomeDto.decode(payload),
        throwsA(
          isA<StorefrontFailure>().having(
            (failure) => failure.kind,
            'kind',
            StorefrontFailureKind.invalidPayload,
          ),
        ),
      );
    }
  });

  test('rifiuta campi fuori allow-list senza propagare metadata interni', () {
    final payload = validStorefrontHomePayload()
      ..['inventory_products'] = {'supplier': 'private'};

    expect(
      () => StorefrontHomeDto.decode(payload),
      throwsA(
        isA<StorefrontFailure>().having(
          (failure) => failure.kind,
          'kind',
          StorefrontFailureKind.invalidPayload,
        ),
      ),
    );
  });

  test('rifiuta CLP decimali/negativi e sconti incoerenti', () {
    for (final invalid in <Object?>[-1, 12.5, '1200']) {
      final payload = validStorefrontHomePayload();
      ((payload['featured'] as List).single as Map)['priceClp'] = invalid;
      expect(
        () => StorefrontHomeDto.decode(payload),
        throwsA(isA<StorefrontFailure>()),
      );
    }
    final inconsistent = validStorefrontHomePayload();
    ((inconsistent['offers'] as List).single as Map).remove('discountBps');
    expect(
      () => StorefrontHomeDto.decode(inconsistent),
      throwsA(isA<StorefrontFailure>()),
    );
  });

  test('rifiuta URL non HTTPS o appartenenti al bucket operativo', () {
    for (final invalid in [
      'http://example.invalid/storefront-product-images/card.webp',
      'https://example.invalid/storage/v1/object/public/product-images/card.webp',
      'https://user@example.invalid/storefront-product-images/card.webp',
      'https://example.invalid/storefront-product-images/card.webp?token=value',
    ]) {
      final payload = validStorefrontHomePayload();
      final product = (payload['featured'] as List).single as Map;
      (product['images'] as Map)['card'] = invalid;
      expect(
        () => StorefrontHomeDto.decode(payload),
        throwsA(isA<StorefrontFailure>()),
        reason: invalid,
      );
    }
  });
}
