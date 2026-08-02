import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/storefront_failure.dart';
import '../domain/storefront_models.dart';
import '../domain/storefront_repository.dart';
import 'storefront_catalog_dto.dart';
import 'storefront_home_dto.dart';
import 'http_storefront_rpc_invoker.dart';

typedef StorefrontRpcInvoker =
    Future<Object?> Function(String function, Map<String, Object?> parameters);

class SupabaseStorefrontRepository implements StorefrontRepository {
  const SupabaseStorefrontRepository({
    required this.invoke,
    this.requestTimeout = const Duration(seconds: 5),
  });

  final StorefrontRpcInvoker invoke;
  final Duration requestTimeout;
  static final _publicationId = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) => _invokeDecoded(
    function: 'storefront_home_v1',
    parameters: {
      'p_shop_slug': shopSlug,
      'p_category_limit': 12,
      'p_featured_limit': 8,
      'p_offer_limit': 8,
    },
    cancellation: cancellation,
    decode: StorefrontHomeDto.decode,
  );

  @override
  Future<StorefrontCategoriesPage> fetchCategories({
    required String shopSlug,
    required String? cursor,
    required int limit,
    required StorefrontRequestCancellation cancellation,
  }) {
    _validateLimit(limit);
    return _invokeDecoded(
      function: 'storefront_categories_v1',
      parameters: {
        'p_shop_slug': shopSlug,
        'p_cursor': cursor,
        'p_limit': limit,
      },
      cancellation: cancellation,
      decode: StorefrontCatalogDto.decodeCategories,
    );
  }

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
  }) {
    _validateLimit(limit);
    _validateCategorySlug(categorySlug);
    return _invokeDecoded(
      function: 'storefront_catalog_v1',
      parameters: {
        'p_shop_slug': shopSlug,
        'p_cursor': cursor,
        'p_limit': limit,
        'p_category_slug': categorySlug,
        'p_availability': availability == null
            ? null
            : _availabilityValue(availability),
        'p_discounted': discounted,
        'p_featured': null,
        'p_sort': _sortValue(sort),
      },
      cancellation: cancellation,
      decode: StorefrontCatalogDto.decodeCatalog,
    );
  }

  @override
  Future<StorefrontSearchPage> fetchSearch({
    required String shopSlug,
    required String query,
    required String? cursor,
    required int limit,
    required String? categorySlug,
    required StorefrontRequestCancellation cancellation,
  }) {
    _validateLimit(limit);
    if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(query)) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_search_query',
      );
    }
    final normalizedQuery = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedQuery.length < 2 || normalizedQuery.length > 120) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_search_query',
      );
    }
    _validateCategorySlug(categorySlug);
    return _invokeDecoded(
      function: 'storefront_search_v1',
      parameters: {
        'p_shop_slug': shopSlug,
        'p_query': normalizedQuery,
        'p_cursor': cursor,
        'p_limit': limit,
        'p_category_slug': categorySlug,
      },
      cancellation: cancellation,
      decode: StorefrontCatalogDto.decodeSearch,
    );
  }

  @override
  Future<StorefrontProductSummary> fetchProductDetail({
    required String shopSlug,
    required String publicationId,
    required StorefrontRequestCancellation cancellation,
  }) async {
    if (!_publicationId.hasMatch(publicationId)) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_publication_id',
      );
    }
    final product = await _invokeDecoded(
      function: 'storefront_product_detail_v1',
      parameters: {'p_shop_slug': shopSlug, 'p_publication_id': publicationId},
      cancellation: cancellation,
      decode: StorefrontCatalogDto.decodeProductDetail,
    );
    if (product.id.toLowerCase() != publicationId.toLowerCase()) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidPayload,
        code: 'product_detail_id_mismatch',
      );
    }
    return product;
  }

  Future<T> _invokeDecoded<T>({
    required String function,
    required Map<String, Object?> parameters,
    required StorefrontRequestCancellation cancellation,
    required T Function(Object?) decode,
  }) async {
    cancellation.throwIfCancelled();
    try {
      final payload = await invoke(
        function,
        parameters,
      ).timeout(requestTimeout);
      cancellation.throwIfCancelled();
      return decode(payload);
    } on StorefrontFailure {
      rethrow;
    } on TimeoutException {
      throw const StorefrontFailure(
        StorefrontFailureKind.timeout,
        code: 'request_timeout',
      );
    } on SocketException {
      throw const StorefrontFailure(
        StorefrontFailureKind.offline,
        code: 'network_offline',
      );
    } on http.ClientException {
      throw const StorefrontFailure(
        StorefrontFailureKind.offline,
        code: 'network_unreachable',
      );
    } on FormatException {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidPayload,
        code: 'public_contract_invalid_json',
      );
    } on StorefrontRpcResponseException catch (error) {
      final unauthorized =
          error.statusCode == 401 ||
          error.statusCode == 403 ||
          error.code == '42501';
      throw StorefrontFailure(
        unauthorized
            ? StorefrontFailureKind.unauthorized
            : StorefrontFailureKind.unavailable,
        code: unauthorized
            ? 'public_contract_unauthorized'
            : 'public_contract_unavailable',
      );
    } on Object {
      throw const StorefrontFailure(
        StorefrontFailureKind.unknown,
        code: 'storefront_unknown',
      );
    }
  }

  void _validateLimit(int limit) {
    if (limit < 1 || limit > 100) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_page_limit',
      );
    }
  }

  void _validateCategorySlug(String? categorySlug) {
    if (categorySlug != null &&
        !RegExp(r'^[a-z0-9][a-z0-9-]{1,62}$').hasMatch(categorySlug)) {
      throw const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'invalid_category_slug',
      );
    }
  }

  String _sortValue(StorefrontCatalogSort sort) => switch (sort) {
    StorefrontCatalogSort.catalog => 'catalog',
    StorefrontCatalogSort.name => 'name',
    StorefrontCatalogSort.priceAscending => 'price_asc',
    StorefrontCatalogSort.priceDescending => 'price_desc',
  };

  String _availabilityValue(StorefrontAvailability availability) =>
      switch (availability) {
        StorefrontAvailability.available => 'available',
        StorefrontAvailability.lowStock => 'low_stock',
        StorefrontAvailability.unavailable => 'unavailable',
        StorefrontAvailability.reservationOnly => 'reservation_only',
        StorefrontAvailability.pickupOnly => 'pickup_only',
        StorefrontAvailability.deliveryOnly => 'delivery_only',
      };
}
