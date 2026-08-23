import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/customer_review_models.dart';
import '../domain/customer_review_repository.dart';

abstract interface class CustomerReviewPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformCustomerReviewPort implements CustomerReviewPort {
  PlatformCustomerReviewPort(this.client);

  final SupabaseClient client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return client.rpc(function, params: parameters);
  }
}

final class SupabaseCustomerReviewRepository
    implements CustomerReviewRepository {
  SupabaseCustomerReviewRepository({
    required this.port,
    this.timeout = const Duration(seconds: 12),
  });

  final CustomerReviewPort port;
  final Duration timeout;

  @override
  Future<CustomerReviewsAccount> listMine({required String shopSlug}) =>
      _guard(() async {
        _inputShop(shopSlug);
        final payload = _payload(
          await port.invoke('customer_reviews_list_v1', {
            'p_shop_slug': shopSlug,
            'p_pending_only': false,
          }),
          const {'apiVersion', 'status', 'items', 'eligible', 'serverTime'},
          'customer_reviews_list',
        );
        _customerRoot(payload);
        return CustomerReviewsAccount(
          items: _list(payload, 'items', 500).map(_mine).toList(),
          eligible: _list(payload, 'eligible', 500).map(_eligible).toList(),
        );
      });

  @override
  Future<CustomerReviewMutation> submit({
    required String orderItemId,
    required int rating,
    required String? comment,
  }) => _guard(() async {
    _inputUuid(orderItemId);
    _inputReview(rating, comment);
    return _mutation(
      await port.invoke('customer_review_submit_v1', {
        'p_order_item_id': orderItemId,
        'p_rating': rating,
        'p_comment': comment,
      }),
    );
  });

  @override
  Future<CustomerReviewMutation> update({
    required String reviewId,
    required int expectedVersion,
    required int rating,
    required String? comment,
    required bool withdraw,
  }) => _guard(() async {
    _inputUuid(reviewId);
    if (expectedVersion < 1) throw const CustomerReviewException('invalid');
    if (!withdraw) _inputReview(rating, comment);
    return _mutation(
      await port.invoke('customer_review_update_v1', {
        'p_review_id': reviewId,
        'p_expected_version': expectedVersion,
        'p_rating': rating,
        'p_comment': comment,
        'p_withdraw': withdraw,
      }),
    );
  });

  @override
  Future<StorefrontProductReviews> listProduct({
    required String shopSlug,
    required String publicationId,
    StorefrontReviewCursor? cursor,
    int pageSize = 20,
  }) => _guard(() async {
    _inputShop(shopSlug);
    _inputUuid(publicationId);
    if (cursor != null) {
      _inputUuid(cursor.beforeId);
      final before = cursor.beforeCreatedAt.toUtc();
      if (before.year < 2020 || before.year > 2200) {
        throw const CustomerReviewException('invalid');
      }
    }
    if (pageSize < 1 || pageSize > 50) {
      throw const CustomerReviewException('invalid');
    }
    final payload = _payload(
      await port.invoke('storefront_product_reviews_v1', {
        'p_shop_slug': shopSlug,
        'p_publication_id': publicationId,
        'p_before_created_at': cursor?.beforeCreatedAt
            .toUtc()
            .toIso8601String(),
        'p_before_id': cursor?.beforeId,
        'p_page_size': pageSize,
      }),
      const {
        'apiVersion',
        'status',
        'averageRating',
        'publishedCount',
        'distribution',
        'items',
        'serverTime',
      },
      'product_reviews',
    );
    if (payload['apiVersion'] != 'storefront-reviews.v1') {
      throw const FormatException('product_reviews_version');
    }
    final status = _string(payload, 'status');
    if (status != 'ok') throw CustomerReviewException(status);
    final average = payload['averageRating'];
    final count = _integer(payload, 'publishedCount');
    final distributionRaw = _strict(payload['distribution'], const {
      '1',
      '2',
      '3',
      '4',
      '5',
    }, 'product_reviews_distribution');
    if (average is! num || average < 0 || average > 5 || count < 0) {
      throw const FormatException('product_reviews_aggregate');
    }
    final distribution = {
      for (var rating = 1; rating <= 5; rating++)
        rating: _integer(distributionRaw, '$rating'),
    };
    if (distribution.values.fold<int>(0, (sum, value) => sum + value) !=
        count) {
      throw const FormatException('product_reviews_distribution_count');
    }
    final items = _list(
      payload,
      'items',
      pageSize,
    ).map(_public).toList(growable: false);
    _unique(items.map((item) => item.id));
    final last = items.lastOrNull;
    return StorefrontProductReviews(
      averageRating: average.toDouble(),
      publishedCount: count,
      distribution: distribution,
      items: items,
      nextCursor: items.length == pageSize && last != null
          ? StorefrontReviewCursor(
              beforeCreatedAt: last.createdAt,
              beforeId: last.id,
            )
          : null,
      serverTime: _date(payload, 'serverTime'),
    );
  });

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(timeout);
    } on CustomerReviewException {
      rethrow;
    } on TimeoutException {
      throw const CustomerReviewException('timeout');
    } on SocketException {
      throw const CustomerReviewException('offline');
    } on AuthException {
      throw const CustomerReviewException('unauthorized');
    } on PostgrestException catch (error) {
      throw CustomerReviewException(error.code ?? 'unexpected');
    } on FormatException {
      throw const CustomerReviewException('unexpected');
    } on Object {
      throw const CustomerReviewException('unexpected');
    }
  }
}

void _customerRoot(Map<String, Object?> payload) {
  if (payload['apiVersion'] != 'customer-reviews.v1') {
    throw const FormatException('customer_reviews_version');
  }
  final status = _string(payload, 'status');
  if (status != 'ok') throw CustomerReviewException(status);
}

CustomerReviewMutation _mutation(Object? raw) {
  final payload = _payload(raw, const {
    'apiVersion',
    'status',
    'reviewId',
    'moderationStatus',
    'version',
  }, 'customer_review_mutation');
  _customerRoot(payload);
  if (payload.length != 5) {
    throw const FormatException('customer_review_mutation_shape');
  }
  final version = _integer(payload, 'version');
  if (version < 1) throw const FormatException('customer_review_version');
  return CustomerReviewMutation(
    reviewId: _uuid(payload, 'reviewId'),
    status: _status(_string(payload, 'moderationStatus')),
    version: version,
  );
}

CustomerReview _mine(Object? raw) {
  final map = _strict(raw, const {
    'id',
    'orderId',
    'orderItemId',
    'publicationId',
    'rating',
    'comment',
    'status',
    'version',
    'submittedAt',
    'updatedAt',
  }, 'customer_review');
  final rating = _integer(map, 'rating');
  final version = _integer(map, 'version');
  if (rating < 1 || rating > 5 || version < 1) {
    throw const FormatException('customer_review_invariant');
  }
  return CustomerReview(
    id: _uuid(map, 'id'),
    orderId: _uuid(map, 'orderId'),
    orderItemId: _uuid(map, 'orderItemId'),
    publicationId: _uuid(map, 'publicationId'),
    rating: rating,
    comment: _safeOptional(map, 'comment', 1000),
    status: _status(_string(map, 'status')),
    version: version,
    submittedAt: _date(map, 'submittedAt'),
    updatedAt: _date(map, 'updatedAt'),
  );
}

CustomerReviewEligibleLine _eligible(Object? raw) {
  final map = _strict(raw, const {
    'orderId',
    'orderItemId',
    'publicationId',
    'name',
  }, 'customer_review_eligible');
  return CustomerReviewEligibleLine(
    orderId: _uuid(map, 'orderId'),
    orderItemId: _uuid(map, 'orderItemId'),
    publicationId: _uuid(map, 'publicationId'),
    name: _safe(map, 'name', 200),
  );
}

StorefrontProductReview _public(Object? raw) {
  final map = _strict(raw, const {
    'id',
    'rating',
    'comment',
    'createdAt',
    'verifiedPurchase',
  }, 'product_review');
  final rating = _integer(map, 'rating');
  if (rating < 1 || rating > 5 || map['verifiedPurchase'] != true) {
    throw const FormatException('product_review_invariant');
  }
  return StorefrontProductReview(
    id: _uuid(map, 'id'),
    rating: rating,
    comment: _safeOptional(map, 'comment', 1000),
    createdAt: _date(map, 'createdAt'),
    verifiedPurchase: true,
  );
}

CustomerReviewStatus _status(String value) => switch (value) {
  'pending' => CustomerReviewStatus.pending,
  'published' => CustomerReviewStatus.published,
  'rejected' => CustomerReviewStatus.rejected,
  'withdrawn' => CustomerReviewStatus.withdrawn,
  _ => throw const FormatException('customer_review_status'),
};

Map<String, Object?> _payload(Object? raw, Set<String> allowed, String label) {
  if (raw is! Map) throw FormatException('${label}_map');
  final map = raw.map((key, value) => MapEntry(key.toString(), value));
  if (map.keys.any((key) => !allowed.contains(key))) {
    throw FormatException('${label}_keys');
  }
  return map;
}

Map<String, Object?> _strict(Object? raw, Set<String> keys, String label) {
  final map = _payload(raw, keys, label);
  if (map.length != keys.length) throw FormatException('${label}_shape');
  return map;
}

List<Object?> _list(Map<String, Object?> map, String key, int maximum) {
  final value = map[key];
  if (value is! List || value.length > maximum) {
    throw FormatException('customer_review_$key');
  }
  return value.cast<Object?>();
}

String _string(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('customer_review_$key');
  }
  return value;
}

String _safe(Map<String, Object?> map, String key, int maximum) {
  final value = _string(map, key);
  if (value != value.trim() ||
      value.runes.length > maximum ||
      value.contains('<')) {
    throw FormatException('customer_review_$key');
  }
  return value;
}

String? _safeOptional(Map<String, Object?> map, String key, int maximum) {
  if (!map.containsKey(key) || map[key] == null) return null;
  return _safe(map, key, maximum);
}

String _uuid(Map<String, Object?> map, String key) {
  final value = _string(map, key);
  if (!_uuidPattern.hasMatch(value)) {
    throw FormatException('customer_review_$key');
  }
  return value;
}

int _integer(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('customer_review_$key');
  return value;
}

DateTime _date(Map<String, Object?> map, String key) {
  final value = DateTime.tryParse(_string(map, key))?.toUtc();
  if (value == null || value.year < 2020 || value.year > 2200) {
    throw FormatException('customer_review_$key');
  }
  return value;
}

void _inputReview(int rating, String? comment) {
  final normalized = comment?.trim();
  if (rating < 1 ||
      rating > 5 ||
      normalized != comment ||
      (normalized != null &&
          (normalized.isEmpty || normalized.runes.length > 1000))) {
    throw const CustomerReviewException('invalid');
  }
}

void _inputUuid(String value) {
  if (!_uuidPattern.hasMatch(value)) {
    throw const CustomerReviewException('invalid');
  }
}

void _unique(Iterable<String> values) {
  final list = values.toList(growable: false);
  if (list.toSet().length != list.length) {
    throw const FormatException('customer_review_duplicate');
  }
}

void _inputShop(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const CustomerReviewException('invalid');
  }
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
