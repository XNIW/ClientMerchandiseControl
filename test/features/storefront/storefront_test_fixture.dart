import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';

const validStorefrontCursor = 'eyJ2IjoxLCJzb3J0IjoiY2F0YWxvZyJ9';

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

Map<String, Object?> validStorefrontCategoriesPayload({
  String? nextCursor = validStorefrontCursor,
}) {
  final home = validStorefrontHomePayload();
  return {
    'status': 'ok',
    'apiVersion': 'storefront.v1',
    'catalogVersion': 7,
    'categories': home['categories'],
    'nextCursor': nextCursor,
  };
}

Map<String, Object?> validStorefrontCatalogPayload({
  String? nextCursor = validStorefrontCursor,
  String sort = 'catalog',
}) {
  final home = validStorefrontHomePayload();
  return {
    'status': 'ok',
    'apiVersion': 'storefront.v1',
    'catalogVersion': 7,
    'items': [...home['featured'] as List, ...home['offers'] as List],
    'nextCursor': nextCursor,
    'sort': sort,
  };
}

Map<String, Object?> validStorefrontSearchPayload({
  String query = 'cafe',
  String? nextCursor = validStorefrontCursor,
}) {
  final catalog = validStorefrontCatalogPayload(nextCursor: null);
  final items = (catalog['items'] as List)
      .map(
        (item) =>
            Map<String, Object?>.from(item as Map)..['relevanceScore'] = 1000,
      )
      .toList(growable: false);
  return {
    'status': 'ok',
    'apiVersion': 'storefront.v1',
    'catalogVersion': 7,
    'query': query,
    'items': items,
    'nextCursor': nextCursor,
  };
}

Map<String, Object?> validStorefrontProductDetailPayload() {
  final catalog = validStorefrontCatalogPayload(nextCursor: null);
  return {
    'status': 'ok',
    'apiVersion': 'storefront.v1',
    'catalogVersion': 7,
    'item': (catalog['items'] as List).first,
  };
}

abstract class HomeOnlyStorefrontRepository implements StorefrontRepository {
  const HomeOnlyStorefrontRepository();

  @override
  Future<StorefrontCategoriesPage> fetchCategories({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchCategories is outside this test');

  @override
  Future<StorefrontCatalogPage> fetchCatalog({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontCatalogSort sort,
    StorefrontAvailability? availability,
    bool? discounted,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchCatalog is outside this test');

  @override
  Future<StorefrontSearchPage> fetchSearch({
    required String shopSlug,
    required String query,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchSearch is outside this test');

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) => throw UnsupportedError('fetchProductDetail is outside this test');
}
