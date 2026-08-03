import 'package:client_merchandise_control/features/deep_links/application/storefront_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

const _shop = 'storefront-test';
const _publicationId = '50000000-0000-4000-8000-000000000001';
const _orderId = '88000000-0000-4000-8000-000000028101';

void main() {
  const codec = StorefrontDeepLinkCodec();

  test('costruisce e decodifica i link canonici prodotto e categoria', () {
    final product = codec.productUri(
      shopSlug: _shop,
      publicationId: _publicationId,
    );
    final category = codec.categoryUri(
      shopSlug: _shop,
      categorySlug: 'cafe-molido',
    );

    expect(
      product.toString(),
      'com.xniw.clientmerchandisecontrol://storefront/'
      'storefront-test/product/$_publicationId',
    );
    expect(
      category.toString(),
      'com.xniw.clientmerchandisecontrol://storefront/'
      'storefront-test/category/cafe-molido',
    );
    expect(
      codec.decode(product, shopSlug: _shop),
      isA<StorefrontProductDeepLink>().having(
        (intent) => intent.publicationId,
        'publicationId',
        _publicationId,
      ),
    );
    expect(
      codec.decode(category, shopSlug: _shop),
      isA<StorefrontCategoryDeepLink>().having(
        (intent) => intent.categorySlug,
        'categorySlug',
        'cafe-molido',
      ),
    );
  });

  test('costruisce e decodifica il link ordine canonico owner-protected', () {
    final order = codec.orderUri(shopSlug: _shop, orderId: _orderId);

    expect(
      order.toString(),
      'com.xniw.clientmerchandisecontrol://storefront/'
      'storefront-test/order/$_orderId',
    );
    expect(
      codec.decode(order, shopSlug: _shop),
      isA<StorefrontOrderDeepLink>().having(
        (intent) => intent.orderId,
        'orderId',
        _orderId,
      ),
    );
  });

  test('rifiuta input non canonici nei builder', () {
    for (final shop in const ['', 'a', 'UPPER', '../shop', ' shop']) {
      expect(
        () => codec.productUri(shopSlug: shop, publicationId: _publicationId),
        throwsArgumentError,
        reason: shop,
      );
    }
    for (final publicationId in const [
      '',
      '50000000-0000-4000-8000-00000000000Z',
      '50000000-0000-0000-0000-000000000001',
      '50000000-0000-4000-8000-000000000001/extra',
    ]) {
      expect(
        () => codec.productUri(shopSlug: _shop, publicationId: publicationId),
        throwsArgumentError,
        reason: publicationId,
      );
    }
    for (final category in const ['', 'a', 'Café', '../inventory', ' café']) {
      expect(
        () => codec.categoryUri(shopSlug: _shop, categorySlug: category),
        throwsArgumentError,
        reason: category,
      );
    }
  });

  test('matrice malevola e cross-shop fallisce chiusa', () {
    final valid = codec.productUri(
      shopSlug: _shop,
      publicationId: _publicationId,
    );
    final invalid = <Uri>[
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://auth-callback/?code=secret',
      ),
      Uri.parse('https://storefront/$_shop/product/$_publicationId'),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://other/'
        '$_shop/product/$_publicationId',
      ),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront/'
        'other-shop/product/$_publicationId',
      ),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://user@storefront/'
        '$_shop/product/$_publicationId',
      ),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront:443/'
        '$_shop/product/$_publicationId',
      ),
      Uri.parse('$valid?next=/inventory'),
      Uri.parse('$valid#fragment'),
      Uri.parse('$valid/extra'),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront/'
        '$_shop/product/5A000000-0000-4000-8000-000000000001',
      ),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront/'
        '$_shop/category/caf%C3%A9',
      ),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront/'
        '$_shop/category/cafe%2Finventory',
      ),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront/'
        '$_shop/promotion/70000000-0000-4000-8000-000000000001',
      ),
    ];

    for (final uri in invalid) {
      expect(codec.decode(uri, shopSlug: _shop), isNull, reason: '$uri');
    }
    expect(codec.decode(valid, shopSlug: 'other-shop'), isNull);
    expect(codec.decode(valid, shopSlug: 'a'), isNull);

    final order = codec.orderUri(shopSlug: _shop, orderId: _orderId);
    for (final uri in [
      Uri.parse('$order?token=private'),
      Uri.parse('$order#fragment'),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront/'
        'other-shop/order/$_orderId',
      ),
      Uri.parse(
        'com.xniw.clientmerchandisecontrol://storefront/'
        '$_shop/order/88000000-0000-0000-0000-000000028101',
      ),
    ]) {
      expect(codec.decode(uri, shopSlug: _shop), isNull, reason: '$uri');
    }
  });
}
