import '../domain/storefront_failure.dart';
import '../domain/storefront_models.dart';
import 'storefront_home_dto.dart';

abstract final class StorefrontCatalogDto {
  static final _cursor = RegExp(r'^[A-Za-z0-9_-]{24,768}$');

  static StorefrontCategoriesPage decodeCategories(Object? raw) {
    final payload = _response(raw, const {
      'status',
      'apiVersion',
      'catalogVersion',
      'categories',
      'nextCursor',
    });
    _requireOk(payload, const {'catalogVersion', 'categories', 'nextCursor'});
    final catalogVersion = _nonNegativeInt(payload, 'catalogVersion');
    final categories = _list(
      payload,
      'categories',
      maximum: 100,
    ).map(StorefrontHomeDto.decodeCategory).toList(growable: false);
    _requireUnique(categories.map((category) => category.id), 'category_id');
    _requireUnique(
      categories.map((category) => category.slug),
      'category_slug',
    );
    return StorefrontCategoriesPage(
      catalogVersion: catalogVersion,
      categories: categories,
      nextCursor: _nextCursor(payload),
    );
  }

  static StorefrontCatalogPage decodeCatalog(Object? raw) {
    final payload = _response(raw, const {
      'status',
      'apiVersion',
      'catalogVersion',
      'items',
      'nextCursor',
      'sort',
    });
    _requireOk(payload, const {
      'catalogVersion',
      'items',
      'nextCursor',
      'sort',
    });
    final catalogVersion = _nonNegativeInt(payload, 'catalogVersion');
    final items = _list(payload, 'items', maximum: 100)
        .map(
          (item) =>
              StorefrontHomeDto.decodeProductSummary(item, catalogVersion),
        )
        .toList(growable: false);
    _requireUnique(items.map((item) => item.id), 'product_id');
    return StorefrontCatalogPage(
      catalogVersion: catalogVersion,
      items: items,
      nextCursor: _nextCursor(payload),
      sort: _sort(_string(payload, 'sort')),
    );
  }

  static StorefrontSearchPage decodeSearch(Object? raw) {
    final payload = _response(raw, const {
      'status',
      'apiVersion',
      'catalogVersion',
      'query',
      'items',
      'nextCursor',
    });
    _requireOk(payload, const {
      'catalogVersion',
      'query',
      'items',
      'nextCursor',
    });
    final catalogVersion = _nonNegativeInt(payload, 'catalogVersion');
    final query = _normalizedSearchQuery(_string(payload, 'query'));
    final items = _list(payload, 'items', maximum: 100)
        .map((rawItem) {
          if (rawItem is! Map) _invalid('search_item_map');
          final item = rawItem.map((key, value) {
            if (key is! String) _invalid('search_item_key');
            return MapEntry(key, value);
          });
          if (!item.containsKey('relevanceScore') ||
              item['relevanceScore'] is! int ||
              (item['relevanceScore'] as int) < 0 ||
              (item['relevanceScore'] as int) > 1000000) {
            _invalid('search_relevance');
          }
          final product = <String, Object?>{
            for (final entry in item.entries) entry.key: entry.value,
          }..remove('relevanceScore');
          return StorefrontHomeDto.decodeProductSummary(
            product,
            catalogVersion,
          );
        })
        .toList(growable: false);
    _requireUnique(items.map((item) => item.id), 'search_product_id');
    return StorefrontSearchPage(
      catalogVersion: catalogVersion,
      query: query,
      items: items,
      nextCursor: _nextCursor(payload),
    );
  }

  static Map<String, Object?> _response(Object? raw, Set<String> allowedKeys) {
    if (raw is! Map) _invalid('response_map');
    final payload = raw.map((key, value) {
      if (key is! String) _invalid('response_key');
      return MapEntry(key, value);
    });
    if (payload.keys.any((key) => !allowedKeys.contains(key)) ||
        !payload.containsKey('status') ||
        !payload.containsKey('apiVersion')) {
      _invalid('response_shape');
    }
    if (_string(payload, 'apiVersion') != StorefrontHomeDto.apiVersion) {
      _invalid('api_version');
    }
    return payload;
  }

  static void _requireOk(
    Map<String, Object?> payload,
    Set<String> requiredKeys,
  ) {
    final status = _string(payload, 'status');
    if (status == 'unavailable') {
      throw const StorefrontFailure(
        StorefrontFailureKind.unavailable,
        code: 'storefront_unavailable',
      );
    }
    if (status == 'catalog_changed') {
      throw const StorefrontFailure(
        StorefrontFailureKind.catalogChanged,
        code: 'catalog_changed',
      );
    }
    if (status != 'ok' ||
        requiredKeys.any((key) => !payload.containsKey(key))) {
      _invalid('response_status');
    }
  }

  static List<Object?> _list(
    Map<String, Object?> payload,
    String key, {
    required int maximum,
  }) {
    final value = payload[key];
    if (value is! List || value.length > maximum) _invalid('${key}_list');
    return value;
  }

  static String _string(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! String) _invalid('${key}_string');
    return value;
  }

  static int _nonNegativeInt(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! int || value < 0) _invalid('${key}_integer');
    return value;
  }

  static String? _nextCursor(Map<String, Object?> payload) {
    final value = payload['nextCursor'];
    if (value == null) return null;
    if (value is! String || !_cursor.hasMatch(value)) {
      _invalid('next_cursor');
    }
    return value;
  }

  static StorefrontCatalogSort _sort(String value) => switch (value) {
    'catalog' => StorefrontCatalogSort.catalog,
    'name' => StorefrontCatalogSort.name,
    'price_asc' => StorefrontCatalogSort.priceAscending,
    'price_desc' => StorefrontCatalogSort.priceDescending,
    _ => _invalid('sort'),
  };

  static String _normalizedSearchQuery(String value) {
    if (value.length < 2 ||
        value.length > 120 ||
        value.trim() != value ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
        RegExp(r'\s{2,}').hasMatch(value)) {
      _invalid('search_query');
    }
    return value;
  }

  static void _requireUnique(Iterable<String> values, String code) {
    final seen = <String>{};
    if (values.any((value) => !seen.add(value))) _invalid('duplicate_$code');
  }

  static Never _invalid(String code) => throw StorefrontFailure(
    StorefrontFailureKind.invalidPayload,
    code: 'invalid_payload_$code',
  );
}
