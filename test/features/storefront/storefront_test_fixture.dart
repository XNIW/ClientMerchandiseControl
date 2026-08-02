import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';

Map<String, Object?> validStorefrontHomePayload({bool withImages = true}) {
  final image = withImages
      ? <String, Object?>{
          'version': '90000000-0000-4000-8000-000000000001',
          'thumb':
              'https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/storefront-product-images/shops/test/thumb-a.webp',
          'card':
              'https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/storefront-product-images/shops/test/card-a.webp',
          'detail':
              'https://abcdefghijklmnopqrst.supabase.co/storage/v1/object/public/storefront-product-images/shops/test/detail-a.webp',
          'sha256':
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        }
      : null;
  Map<String, Object?> product({
    required String id,
    required String name,
    required bool featured,
    required bool discounted,
  }) => {
    'id': id,
    'category': {
      'id': '40000000-0000-4000-8000-000000000001',
      'slug': 'bebidas',
      'name': 'Bebidas',
    },
    'name': name,
    'description': 'Descripción pública',
    'brand': 'Marca pública',
    'priceClp': discounted ? 1200 : 1500,
    if (discounted) 'compareAtPriceClp': 1500,
    if (discounted) 'discountBps': 2000,
    if (discounted)
      'promotion': {
        'id': '70000000-0000-4000-8000-000000000001',
        'name': 'Oferta real',
        'startsAt': '2026-08-01T00:00:00Z',
        'endsAt': '2026-08-03T00:00:00Z',
      },
    'featured': featured,
    'sortRank': 1,
    'availability': 'available',
    'fulfillment': {'pickup': true, 'delivery': true, 'reservation': false},
    'images': ?image,
    'catalogVersion': 7,
    'publishedAt': '2026-08-01T00:00:00Z',
    'updatedAt': '2026-08-01T01:00:00Z',
  };

  return {
    'status': 'ok',
    'apiVersion': 'storefront.v1',
    'catalogVersion': 7,
    'settings': {
      'shopSlug': 'storefront-test',
      'currency': 'CLP',
      'locale': 'es-CL',
      'timeZone': 'America/Santiago',
      'defaultPageSize': 24,
      'maximumPageSize': 100,
      'fulfillment': {'pickup': true, 'delivery': true, 'reservation': false},
    },
    'categories': [
      {
        'id': '40000000-0000-4000-8000-000000000001',
        'slug': 'bebidas',
        'name': 'Bebidas',
        'sortRank': 1,
      },
    ],
    'featured': [
      product(
        id: '50000000-0000-4000-8000-000000000001',
        name: 'Café destacado',
        featured: true,
        discounted: false,
      ),
    ],
    'offers': [
      product(
        id: '50000000-0000-4000-8000-000000000002',
        name: 'Té en oferta',
        featured: false,
        discounted: true,
      ),
    ],
  };
}

StorefrontHomeData validStorefrontHomeData() {
  const category = StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000001',
    slug: 'bebidas',
    name: 'Bebidas',
    sortRank: 1,
  );
  StorefrontProductSummary product({
    required String id,
    required String name,
    required bool featured,
    required int price,
    int? compareAt,
    int? discount,
  }) => StorefrontProductSummary(
    id: id,
    category: category,
    name: name,
    priceClp: price,
    compareAtPriceClp: compareAt,
    discountBps: discount,
    featured: featured,
    sortRank: 1,
    availability: StorefrontAvailability.available,
    fulfillment: const StorefrontFulfillment(
      pickup: true,
      delivery: true,
      reservation: false,
    ),
    catalogVersion: 7,
    publishedAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1, 1),
  );
  return StorefrontHomeData(
    catalogVersion: 7,
    settings: const StorefrontSettings(
      shopSlug: 'storefront-test',
      currency: 'CLP',
      locale: 'es-CL',
      timeZone: 'America/Santiago',
      defaultPageSize: 24,
      maximumPageSize: 100,
      fulfillment: StorefrontFulfillment(
        pickup: true,
        delivery: true,
        reservation: false,
      ),
    ),
    categories: const [category],
    featured: [
      product(
        id: '50000000-0000-4000-8000-000000000001',
        name: 'Café destacado',
        featured: true,
        price: 1500,
      ),
    ],
    offers: [
      product(
        id: '50000000-0000-4000-8000-000000000002',
        name: 'Té en oferta',
        featured: false,
        price: 1200,
        compareAt: 1500,
        discount: 2000,
      ),
    ],
  );
}
