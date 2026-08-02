import '../domain/storefront_failure.dart';
import '../domain/storefront_models.dart';

abstract final class StorefrontHomeDto {
  static const apiVersion = 'storefront.v1';
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static final _slug = RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$');
  static final _sha256 = RegExp(r'^[a-f0-9]{64}$');

  static StorefrontHomeData decode(Object? raw) {
    final payload = _map(
      raw,
      'home',
      const {
        'status',
        'apiVersion',
        'catalogVersion',
        'settings',
        'categories',
        'featured',
        'offers',
      },
      optionalKeys: const {
        'catalogVersion',
        'settings',
        'categories',
        'featured',
        'offers',
      },
    );
    if (_string(payload, 'apiVersion') != apiVersion) {
      _invalid('home_status');
    }
    final status = _string(payload, 'status');
    if (status == 'unavailable') {
      throw const StorefrontFailure(
        StorefrontFailureKind.unavailable,
        code: 'storefront_unavailable',
      );
    }
    if (status != 'ok' ||
        const {
          'catalogVersion',
          'settings',
          'categories',
          'featured',
          'offers',
        }.any((key) => !payload.containsKey(key))) {
      _invalid('home_status');
    }
    final catalogVersion = _nonNegativeInt(payload, 'catalogVersion');
    final settingsMap = _map(payload['settings'], 'settings', const {
      'shopSlug',
      'currency',
      'locale',
      'timeZone',
      'defaultPageSize',
      'maximumPageSize',
      'fulfillment',
    });
    final settings = StorefrontSettings(
      shopSlug: _validSlug(settingsMap, 'shopSlug'),
      currency: _exactString(settingsMap, 'currency', 'CLP'),
      locale: _boundedString(settingsMap, 'locale', 2, 24),
      timeZone: _boundedString(settingsMap, 'timeZone', 1, 64),
      defaultPageSize: _boundedInt(settingsMap, 'defaultPageSize', 1, 100),
      maximumPageSize: _boundedInt(settingsMap, 'maximumPageSize', 1, 100),
      fulfillment: _fulfillment(settingsMap['fulfillment']),
    );
    if (settings.defaultPageSize > settings.maximumPageSize) {
      _invalid('settings_page_size');
    }
    return StorefrontHomeData(
      catalogVersion: catalogVersion,
      settings: settings,
      categories: _list(
        payload,
        'categories',
      ).map(_category).toList(growable: false),
      featured: _list(
        payload,
        'featured',
      ).map((item) => _product(item, catalogVersion)).toList(growable: false),
      offers: _list(
        payload,
        'offers',
      ).map((item) => _product(item, catalogVersion)).toList(growable: false),
    );
  }

  static StorefrontCategory _category(Object? raw) {
    final value = _map(
      raw,
      'category',
      const {'id', 'slug', 'name', 'sortRank'},
      optionalKeys: const {'sortRank'},
    );
    final id = _string(value, 'id');
    if (!_uuid.hasMatch(id)) _invalid('category_id');
    return StorefrontCategory(
      id: id,
      slug: _validSlug(value, 'slug'),
      name: _boundedString(value, 'name', 1, 160),
      sortRank: value['sortRank'] == null
          ? 0
          : _nonNegativeInt(value, 'sortRank'),
    );
  }

  static StorefrontProductSummary _product(
    Object? raw,
    int responseCatalogVersion,
  ) {
    final value = _map(
      raw,
      'product',
      const {
        'id',
        'category',
        'name',
        'description',
        'brand',
        'barcode',
        'priceClp',
        'compareAtPriceClp',
        'discountBps',
        'promotion',
        'featured',
        'sortRank',
        'availability',
        'fulfillment',
        'images',
        'catalogVersion',
        'publishedAt',
        'updatedAt',
      },
      optionalKeys: const {
        'description',
        'brand',
        'barcode',
        'compareAtPriceClp',
        'discountBps',
        'promotion',
        'images',
      },
    );
    final id = _string(value, 'id');
    if (!_uuid.hasMatch(id)) _invalid('product_id');
    final price = _nonNegativeInt(value, 'priceClp');
    final compareAt = _nullableNonNegativeInt(value, 'compareAtPriceClp');
    if (compareAt != null && compareAt < price) {
      _invalid('compare_at_price');
    }
    final discount = _nullableBoundedInt(value, 'discountBps', 1, 10000);
    if ((compareAt != null && compareAt > price) != (discount != null)) {
      _invalid('discount_consistency');
    }
    final catalogVersion = _nonNegativeInt(value, 'catalogVersion');
    if (catalogVersion != responseCatalogVersion) {
      _invalid('catalog_version');
    }
    return StorefrontProductSummary(
      id: id,
      category: _category(value['category']),
      name: _boundedString(value, 'name', 1, 200),
      description: _nullableBoundedString(value, 'description', 1, 4000),
      brand: _nullableBoundedString(value, 'brand', 1, 120),
      priceClp: price,
      compareAtPriceClp: compareAt,
      discountBps: discount,
      promotion: value['promotion'] == null
          ? null
          : _promotion(value['promotion']),
      featured: _bool(value, 'featured'),
      sortRank: _nonNegativeInt(value, 'sortRank'),
      availability: _availability(_string(value, 'availability')),
      fulfillment: _fulfillment(value['fulfillment']),
      images: value['images'] == null ? null : _images(value['images']),
      catalogVersion: catalogVersion,
      publishedAt: _dateTime(value, 'publishedAt'),
      updatedAt: _dateTime(value, 'updatedAt'),
    );
  }

  static StorefrontPromotion _promotion(Object? raw) {
    final value = _map(raw, 'promotion', const {
      'id',
      'name',
      'startsAt',
      'endsAt',
    });
    final id = _string(value, 'id');
    if (!_uuid.hasMatch(id)) _invalid('promotion_id');
    final startsAt = _dateTime(value, 'startsAt');
    final endsAt = _dateTime(value, 'endsAt');
    if (!startsAt.isBefore(endsAt)) _invalid('promotion_interval');
    return StorefrontPromotion(
      id: id,
      name: _boundedString(value, 'name', 1, 160),
      startsAt: startsAt,
      endsAt: endsAt,
    );
  }

  static StorefrontImageSet _images(Object? raw) {
    final value = _map(raw, 'images', const {
      'version',
      'thumb',
      'card',
      'detail',
      'sha256',
    });
    final version = _string(value, 'version');
    if (!_uuid.hasMatch(version)) _invalid('image_version');
    final sha256 = _string(value, 'sha256');
    if (!_sha256.hasMatch(sha256)) _invalid('image_sha256');
    return StorefrontImageSet(
      version: version,
      thumb: _publicImageUri(value, 'thumb'),
      card: _publicImageUri(value, 'card'),
      detail: _publicImageUri(value, 'detail'),
      sha256: sha256,
    );
  }

  static Uri _publicImageUri(Map<String, Object?> value, String key) {
    final uri = Uri.tryParse(_string(value, key));
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.pathSegments.contains('storefront-product-images') ||
        uri.pathSegments.contains('product-images')) {
      _invalid('image_url');
    }
    return uri;
  }

  static StorefrontFulfillment _fulfillment(Object? raw) {
    final value = _map(raw, 'fulfillment', const {
      'pickup',
      'delivery',
      'reservation',
    });
    return StorefrontFulfillment(
      pickup: _bool(value, 'pickup'),
      delivery: _bool(value, 'delivery'),
      reservation: _bool(value, 'reservation'),
    );
  }

  static StorefrontAvailability _availability(String value) => switch (value) {
    'available' => StorefrontAvailability.available,
    'low_stock' => StorefrontAvailability.lowStock,
    'unavailable' => StorefrontAvailability.unavailable,
    'reservation_only' => StorefrontAvailability.reservationOnly,
    'pickup_only' => StorefrontAvailability.pickupOnly,
    'delivery_only' => StorefrontAvailability.deliveryOnly,
    _ => _invalid('availability'),
  };

  static Map<String, Object?> _map(
    Object? value,
    String code,
    Set<String> allowedKeys, {
    Set<String> optionalKeys = const {},
  }) {
    if (value is! Map) _invalid('${code}_map');
    final result = value.map((key, item) {
      if (key is! String) _invalid('${code}_key');
      return MapEntry(key, item);
    });
    if (result.keys.any((key) => !allowedKeys.contains(key)) ||
        allowedKeys
            .difference(optionalKeys)
            .any((key) => !result.containsKey(key))) {
      _invalid('${code}_shape');
    }
    return result;
  }

  static List<Object?> _list(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! List) _invalid('${key}_list');
    if (result.length > 20) _invalid('${key}_limit');
    return result;
  }

  static String _string(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! String) _invalid('${key}_string');
    return result;
  }

  static String _boundedString(
    Map<String, Object?> value,
    String key,
    int min,
    int max,
  ) {
    final result = _string(value, key).trim();
    if (result.length < min || result.length > max) _invalid('${key}_length');
    return result;
  }

  static String? _nullableBoundedString(
    Map<String, Object?> value,
    String key,
    int min,
    int max,
  ) {
    if (value[key] == null) return null;
    return _boundedString(value, key, min, max);
  }

  static String _exactString(
    Map<String, Object?> value,
    String key,
    String expected,
  ) {
    final result = _string(value, key);
    if (result != expected) _invalid('${key}_value');
    return result;
  }

  static String _validSlug(Map<String, Object?> value, String key) {
    final result = _string(value, key);
    if (!_slug.hasMatch(result)) _invalid('${key}_slug');
    return result;
  }

  static bool _bool(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! bool) _invalid('${key}_bool');
    return result;
  }

  static int _nonNegativeInt(Map<String, Object?> value, String key) =>
      _boundedInt(value, key, 0, 9223372036854775807);

  static int? _nullableNonNegativeInt(Map<String, Object?> value, String key) =>
      value[key] == null ? null : _nonNegativeInt(value, key);

  static int? _nullableBoundedInt(
    Map<String, Object?> value,
    String key,
    int min,
    int max,
  ) => value[key] == null ? null : _boundedInt(value, key, min, max);

  static int _boundedInt(
    Map<String, Object?> value,
    String key,
    int min,
    int max,
  ) {
    final result = value[key];
    if (result is! int || result < min || result > max) {
      _invalid('${key}_integer');
    }
    return result;
  }

  static DateTime _dateTime(Map<String, Object?> value, String key) {
    final result = DateTime.tryParse(_string(value, key));
    if (result == null || !result.isUtc) _invalid('${key}_datetime');
    return result;
  }

  static Never _invalid(String code) => throw StorefrontFailure(
    StorefrontFailureKind.invalidPayload,
    code: 'invalid_payload_$code',
  );
}
