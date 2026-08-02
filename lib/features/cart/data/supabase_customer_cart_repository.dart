import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../storefront/domain/storefront_models.dart';
import '../domain/cart_failure.dart';
import '../domain/cart_models.dart';
import '../domain/cart_repository.dart';

abstract interface class CustomerCartPort {
  Future<Object?> invoke(String function, Map<String, Object?> parameters);
}

final class PlatformCustomerCartPort implements CustomerCartPort {
  PlatformCustomerCartPort(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String function, Map<String, Object?> parameters) {
    return _client.rpc(function, params: parameters);
  }
}

final class SupabaseCustomerCartRepository implements CustomerCartRepository {
  factory SupabaseCustomerCartRepository({
    required CustomerCartPort port,
    Duration requestTimeout = const Duration(seconds: 12),
  }) {
    return SupabaseCustomerCartRepository._(port, requestTimeout);
  }

  const SupabaseCustomerCartRepository._(this._port, this.requestTimeout);

  final CustomerCartPort _port;
  final Duration requestTimeout;

  @override
  Future<CartRemoteResponse> read({required String shopSlug}) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      final payload = _payload(
        await _port.invoke('customer_cart_read_v1', {'p_shop_slug': shopSlug}),
      );
      _throwMinimalFailure(payload);
      return CartRemoteResponse(
        status: CartRemoteStatus.ok,
        snapshot: _parseSnapshot(
          payload,
          shopSlug: shopSlug,
          allowedStatuses: const {'ok'},
        ),
      );
    });
  }

  @override
  Future<CartRemoteResponse> mutate(CartMutationRequest request) {
    return _guard(() async {
      _requireMutation(request);
      final payload = _payload(
        await _port.invoke('customer_cart_mutate_v1', {
          'p_shop_slug': request.shopSlug,
          'p_operation': request.operation.name,
          'p_publication_id': request.publicationId,
          'p_quantity': request.quantity,
          'p_expected_version': request.expectedVersion,
          'p_idempotency_key': request.idempotencyKey,
        }),
      );
      _throwMinimalFailure(payload);
      const statuses = {
        'ok',
        'version_conflict',
        'unavailable',
        'cart_limit_reached',
      };
      final snapshot = _parseSnapshot(
        payload,
        shopSlug: request.shopSlug,
        allowedStatuses: statuses,
      );
      return CartRemoteResponse(
        status: _remoteStatus(_requiredString(payload, 'status')),
        snapshot: snapshot,
      );
    });
  }

  @override
  Future<CartRemoteResponse> mergeGuest({
    required String shopSlug,
    required List<CartLine> guestItems,
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      _requireVersion(expectedVersion);
      _requireUuid(idempotencyKey);
      if (guestItems.length > customerCartMaximumLines) {
        throw const CartRepositoryException(CartFailureKind.invalidInput);
      }
      final byPublication = <String, int>{};
      for (final item in guestItems) {
        _requireUuid(item.publicationId);
        _requireQuantity(item.quantity);
        byPublication.update(
          item.publicationId,
          (value) => value > item.quantity ? value : item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
      final ids = byPublication.keys.toList(growable: false)..sort();
      final payload = _payload(
        await _port.invoke('customer_cart_merge_guest_v1', {
          'p_shop_slug': shopSlug,
          'p_guest_items': [
            for (final id in ids)
              <String, Object>{
                'publicationId': id,
                'quantity': byPublication[id]!,
              },
          ],
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        }),
      );
      _throwMinimalFailure(payload);
      final status = _requiredString(payload, 'status');
      if (status == 'version_conflict') {
        return CartRemoteResponse(
          status: CartRemoteStatus.versionConflict,
          snapshot: _parseSnapshot(
            payload,
            shopSlug: shopSlug,
            allowedStatuses: const {'version_conflict'},
          ),
        );
      }
      if (status != 'merged' && status != 'partial') {
        throw const FormatException('cart_merge_status');
      }
      final rejected = _parseRejectedIds(payload, ids.toSet());
      final acceptedCount = _requiredNonNegativeInt(payload, 'acceptedCount');
      final expectedAccepted = ids.length - rejected.length;
      final mergeStatus = _requiredString(payload, 'mergeStatus');
      final expectedMergeStatus = rejected.isEmpty
          ? 'complete'
          : acceptedCount == 0
          ? 'no_eligible_items'
          : 'partial';
      if (acceptedCount != expectedAccepted ||
          mergeStatus != expectedMergeStatus ||
          (status == 'merged') != rejected.isEmpty) {
        throw const FormatException('cart_merge_consistency');
      }
      return CartRemoteResponse(
        status: _remoteStatus(status),
        snapshot: _parseSnapshot(
          payload,
          shopSlug: shopSlug,
          allowedStatuses: const {'merged', 'partial'},
          mergeFields: true,
        ),
        rejectedPublicationIds: rejected,
      );
    });
  }

  @override
  Future<CartRemoteResponse> revalidate({
    required String shopSlug,
    required int expectedVersion,
    required String idempotencyKey,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      _requireVersion(expectedVersion);
      _requireUuid(idempotencyKey);
      final payload = _payload(
        await _port.invoke('customer_cart_revalidate_v1', {
          'p_shop_slug': shopSlug,
          'p_expected_version': expectedVersion,
          'p_idempotency_key': idempotencyKey,
        }),
      );
      _throwMinimalFailure(payload);
      final snapshot = _parseSnapshot(
        payload,
        shopSlug: shopSlug,
        allowedStatuses: const {'revalidated', 'version_conflict'},
      );
      return CartRemoteResponse(
        status: _remoteStatus(_requiredString(payload, 'status')),
        snapshot: snapshot,
      );
    });
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation().timeout(requestTimeout);
    } on CartRepositoryException {
      rethrow;
    } on TimeoutException {
      throw const CartRepositoryException(CartFailureKind.timeout);
    } on SocketException {
      throw const CartRepositoryException(CartFailureKind.offline);
    } on AuthException {
      throw const CartRepositoryException(CartFailureKind.unauthorized);
    } on PostgrestException catch (error) {
      throw CartRepositoryException(_postgrestFailure(error.code));
    } on FormatException {
      throw const CartRepositoryException(CartFailureKind.unexpected);
    } on Object {
      throw const CartRepositoryException(CartFailureKind.unexpected);
    }
  }
}

const _baseKeys = <String>{
  'apiVersion',
  'status',
  'idempotent',
  'shopSlug',
  'cartVersion',
  'currencyCode',
  'quoteStatus',
  'quotedAt',
  'quoteExpiresAt',
  'requiresCustomerReview',
  'itemCount',
  'totalQuantity',
  'unavailableItemCount',
  'subtotalClp',
  'items',
};

const _mergeKeys = <String>{
  'mergeStatus',
  'acceptedCount',
  'rejectedPublicationIds',
};

const _itemKeys = <String>{
  'publicationId',
  'quantity',
  'publicName',
  'imageUrl',
  'status',
  'availabilityMode',
  'snapshotPriceClp',
  'priceClp',
  'compareAtPriceClp',
  'promotionId',
  'promotionName',
  'promotionEndsAt',
  'changeType',
};

CustomerCartSnapshot _parseSnapshot(
  Map<String, Object?> payload, {
  required String shopSlug,
  required Set<String> allowedStatuses,
  bool mergeFields = false,
}) {
  final allowedKeys = mergeFields ? {..._baseKeys, ..._mergeKeys} : _baseKeys;
  if (payload.length != allowedKeys.length ||
      payload.keys.any((key) => !allowedKeys.contains(key)) ||
      payload['apiVersion'] != 'customer-cart.v1' ||
      !allowedStatuses.contains(payload['status']) ||
      payload['shopSlug'] != shopSlug ||
      payload['currencyCode'] != 'CLP' ||
      payload['idempotent'] is! bool ||
      payload['requiresCustomerReview'] is! bool) {
    throw const FormatException('cart_response_shape');
  }
  _requireShopSlug(shopSlug);
  final version = _requiredNonNegativeInt(payload, 'cartVersion');
  final itemCount = _boundedInt(
    payload,
    'itemCount',
    0,
    customerCartMaximumLines,
  );
  final totalQuantity = _boundedInt(
    payload,
    'totalQuantity',
    0,
    customerCartMaximumLines * customerCartMaximumQuantity,
  );
  final unavailableCount = _boundedInt(
    payload,
    'unavailableItemCount',
    0,
    customerCartMaximumLines,
  );
  final subtotal = _requiredNonNegativeInt(payload, 'subtotalClp');
  final quoteStatus = switch (_requiredString(payload, 'quoteStatus')) {
    'indicative' => CartQuoteStatus.indicative,
    'confirmed' => CartQuoteStatus.confirmed,
    _ => throw const FormatException('cart_quote_status'),
  };
  final quotedAt = _optionalDate(payload, 'quotedAt');
  final quoteExpiresAt = _optionalDate(payload, 'quoteExpiresAt');
  if (quoteStatus == CartQuoteStatus.confirmed) {
    if (quotedAt == null ||
        quoteExpiresAt == null ||
        !quotedAt.isBefore(quoteExpiresAt)) {
      throw const FormatException('cart_quote_timing');
    }
  } else if (quotedAt != null || quoteExpiresAt != null) {
    throw const FormatException('cart_quote_timing');
  }
  final rawItems = payload['items'];
  if (rawItems is! List || rawItems.length != itemCount) {
    throw const FormatException('cart_items');
  }
  final seen = <String>{};
  final items = rawItems
      .map((raw) {
        final item = _payload(raw);
        if (item.length != _itemKeys.length ||
            item.keys.any((key) => !_itemKeys.contains(key))) {
          throw const FormatException('cart_item_shape');
        }
        final publicationId = _requiredString(item, 'publicationId');
        _requirePayloadUuid(publicationId);
        if (!seen.add(publicationId)) {
          throw const FormatException('cart_item_duplicate');
        }
        final quantity = _boundedInt(
          item,
          'quantity',
          1,
          customerCartMaximumQuantity,
        );
        final publicName = _safePublicName(item, 'publicName');
        final status = switch (_requiredString(item, 'status')) {
          'available' => CartLineStatus.available,
          'unavailable' => CartLineStatus.unavailable,
          _ => throw const FormatException('cart_item_status'),
        };
        final availability = _availability(
          _requiredString(item, 'availabilityMode'),
        );
        if ((status == CartLineStatus.unavailable) !=
            (availability == StorefrontAvailability.unavailable)) {
          throw const FormatException('cart_item_availability');
        }
        final snapshotPrice = _requiredNonNegativeInt(item, 'snapshotPriceClp');
        final currentPrice = _optionalNonNegativeInt(item, 'priceClp');
        final compareAt = _optionalNonNegativeInt(item, 'compareAtPriceClp');
        if ((status == CartLineStatus.available) != (currentPrice != null) ||
            (status == CartLineStatus.unavailable && compareAt != null) ||
            (compareAt != null &&
                currentPrice != null &&
                compareAt < currentPrice)) {
          throw const FormatException('cart_item_price');
        }
        final image = _optionalPublicImage(item, 'imageUrl');
        _validatePromotion(item, status);
        final changeType = switch (_requiredString(item, 'changeType')) {
          'none' => CartLineChangeType.none,
          'price_changed' => CartLineChangeType.priceChanged,
          'promotion_changed' => CartLineChangeType.promotionChanged,
          'unavailable' => CartLineChangeType.unavailable,
          _ => throw const FormatException('cart_change_type'),
        };
        if ((status == CartLineStatus.unavailable) !=
            (changeType == CartLineChangeType.unavailable)) {
          throw const FormatException('cart_change_consistency');
        }
        return CartLine(
          publicationId: publicationId,
          publicName: publicName,
          quantity: quantity,
          priceClp: currentPrice ?? snapshotPrice,
          snapshotPriceClp: snapshotPrice,
          compareAtPriceClp: compareAt,
          imageUrl: image,
          availability: availability,
          status: status,
          changeType: changeType,
          isGuest: false,
        );
      })
      .toList(growable: false);
  final calculatedQuantity = items.fold<int>(
    0,
    (total, item) => total + item.quantity,
  );
  final calculatedUnavailable = items.where((item) => !item.isAvailable).length;
  final calculatedSubtotal = items.fold<int>(
    0,
    (total, item) => total + item.lineSubtotalClp,
  );
  if (calculatedQuantity != totalQuantity ||
      calculatedUnavailable != unavailableCount ||
      calculatedSubtotal != subtotal) {
    throw const FormatException('cart_totals');
  }
  return CustomerCartSnapshot(
    shopSlug: shopSlug,
    version: version,
    items: items,
    source: CartSource.account,
    quoteStatus: quoteStatus,
    requiresCustomerReview: payload['requiresCustomerReview']! as bool,
    subtotalClp: subtotal,
    idempotent: payload['idempotent']! as bool,
    quotedAt: quotedAt,
    quoteExpiresAt: quoteExpiresAt,
  );
}

List<String> _parseRejectedIds(
  Map<String, Object?> payload,
  Set<String> requestedIds,
) {
  final raw = payload['rejectedPublicationIds'];
  if (raw is! List || raw.length > requestedIds.length) {
    throw const FormatException('cart_rejected_items');
  }
  final seen = <String>{};
  final ids = raw
      .map((value) {
        if (value is! String) throw const FormatException('cart_rejected_item');
        _requirePayloadUuid(value);
        if (!requestedIds.contains(value) || !seen.add(value)) {
          throw const FormatException('cart_rejected_item');
        }
        return value;
      })
      .toList(growable: false);
  final sorted = [...ids]..sort();
  if (!_sameStrings(ids, sorted)) {
    throw const FormatException('cart_rejected_order');
  }
  return ids;
}

void _validatePromotion(Map<String, Object?> item, CartLineStatus status) {
  final id = item['promotionId'];
  final name = item['promotionName'];
  final ends = item['promotionEndsAt'];
  if (status == CartLineStatus.unavailable) {
    if (id != null || name != null || ends != null) {
      throw const FormatException('cart_promotion_unavailable');
    }
    return;
  }
  final hasAny = id != null || name != null || ends != null;
  final hasAll = id != null && name != null && ends != null;
  if (hasAny != hasAll) throw const FormatException('cart_promotion_shape');
  if (!hasAll) return;
  final promotionId = _requiredString(item, 'promotionId');
  _requirePayloadUuid(promotionId);
  _safePublicName(item, 'promotionName', maximum: 160);
  _requiredDate(item, 'promotionEndsAt');
}

void _requireMutation(CartMutationRequest request) {
  _requireShopSlug(request.shopSlug);
  _requireVersion(request.expectedVersion);
  _requireUuid(request.idempotencyKey);
  switch (request.operation) {
    case CartMutationOperation.set:
      if (request.publicationId == null || request.quantity == null) {
        throw const CartRepositoryException(CartFailureKind.invalidInput);
      }
      _requireUuid(request.publicationId!);
      _requireQuantity(request.quantity!);
    case CartMutationOperation.remove:
      if (request.publicationId == null || request.quantity != null) {
        throw const CartRepositoryException(CartFailureKind.invalidInput);
      }
      _requireUuid(request.publicationId!);
    case CartMutationOperation.clear:
      if (request.publicationId != null || request.quantity != null) {
        throw const CartRepositoryException(CartFailureKind.invalidInput);
      }
  }
}

void _throwMinimalFailure(Map<String, Object?> payload) {
  if (_isMinimalStatus(payload, 'invalid')) {
    throw const CartRepositoryException(CartFailureKind.invalidInput);
  }
  if (_isMinimalStatus(payload, 'idempotency_conflict')) {
    throw const CartRepositoryException(CartFailureKind.conflict);
  }
}

bool _isMinimalStatus(Map<String, Object?> payload, String status) {
  return payload.length == 2 &&
      payload['apiVersion'] == 'customer-cart.v1' &&
      payload['status'] == status;
}

CartRemoteStatus _remoteStatus(String value) => switch (value) {
  'ok' => CartRemoteStatus.ok,
  'merged' => CartRemoteStatus.merged,
  'partial' => CartRemoteStatus.partial,
  'revalidated' => CartRemoteStatus.revalidated,
  'version_conflict' => CartRemoteStatus.versionConflict,
  'unavailable' => CartRemoteStatus.unavailable,
  'cart_limit_reached' => CartRemoteStatus.limitReached,
  _ => throw const FormatException('cart_status'),
};

StorefrontAvailability _availability(String value) => switch (value) {
  'available' => StorefrontAvailability.available,
  'low_stock' => StorefrontAvailability.lowStock,
  'unavailable' => StorefrontAvailability.unavailable,
  'reservation_only' => StorefrontAvailability.reservationOnly,
  'pickup_only' => StorefrontAvailability.pickupOnly,
  'delivery_only' => StorefrontAvailability.deliveryOnly,
  _ => throw const FormatException('cart_availability'),
};

Map<String, Object?> _payload(Object? value) {
  if (value is! Map) throw const FormatException('cart_payload');
  return value.map((key, item) {
    if (key is! String) throw const FormatException('cart_payload_key');
    return MapEntry(key, item);
  });
}

String _requiredString(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String || value.isEmpty || value.trim() != value) {
    throw const FormatException('cart_string');
  }
  return value;
}

String _safePublicName(
  Map<String, Object?> payload,
  String key, {
  int maximum = 200,
}) {
  final value = _requiredString(payload, key);
  if (value.runes.length > maximum ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
      RegExp(
        r'[\u061c\u200e\u200f\u202a-\u202e\u2066-\u2069]',
      ).hasMatch(value)) {
    throw const FormatException('cart_public_text');
  }
  return value;
}

int _requiredNonNegativeInt(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! int || value < 0) {
    throw const FormatException('cart_integer');
  }
  return value;
}

int _boundedInt(
  Map<String, Object?> payload,
  String key,
  int minimum,
  int maximum,
) {
  final value = payload[key];
  if (value is! int || value < minimum || value > maximum) {
    throw const FormatException('cart_bounded_integer');
  }
  return value;
}

int? _optionalNonNegativeInt(Map<String, Object?> payload, String key) {
  return payload[key] == null ? null : _requiredNonNegativeInt(payload, key);
}

DateTime _requiredDate(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String) throw const FormatException('cart_date');
  return DateTime.parse(value).toUtc();
}

DateTime? _optionalDate(Map<String, Object?> payload, String key) {
  return payload[key] == null ? null : _requiredDate(payload, key);
}

Uri? _optionalPublicImage(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value == null) return null;
  if (value is! String) throw const FormatException('cart_image');
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      !uri.hasAuthority ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      !uri.pathSegments.contains('storefront-product-images') ||
      uri.pathSegments.contains('product-images')) {
    throw const FormatException('cart_image');
  }
  return uri;
}

void _requireShopSlug(String value) {
  if (!RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$').hasMatch(value)) {
    throw const CartRepositoryException(CartFailureKind.invalidInput);
  }
}

void _requireUuid(String value) {
  if (!_isUuid(value)) {
    throw const CartRepositoryException(CartFailureKind.invalidInput);
  }
}

void _requirePayloadUuid(String value) {
  if (!_isUuid(value)) throw const FormatException('cart_uuid');
}

bool _isUuid(String value) => RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
).hasMatch(value);

void _requireQuantity(int value) {
  if (value < 1 || value > customerCartMaximumQuantity) {
    throw const CartRepositoryException(CartFailureKind.invalidInput);
  }
}

void _requireVersion(int value) {
  if (value < 0) {
    throw const CartRepositoryException(CartFailureKind.invalidInput);
  }
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

CartFailureKind _postgrestFailure(String? code) => switch (code) {
  '28000' || '42501' || 'PGRST301' => CartFailureKind.unauthorized,
  '22023' || '23502' || '23514' || 'PGRST116' => CartFailureKind.invalidInput,
  '23505' => CartFailureKind.conflict,
  _ => CartFailureKind.unexpected,
};
