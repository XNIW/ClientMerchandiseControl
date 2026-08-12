import 'package:drift/drift.dart';

import '../../storefront/cache/storefront_cache_database.dart';
import '../../storefront/domain/storefront_models.dart';
import '../domain/cart_failure.dart';
import '../domain/cart_models.dart';
import '../domain/cart_repository.dart';

final class DriftGuestCartStore implements GuestCartStore {
  const DriftGuestCartStore(this._database);

  static final _shopSlug = RegExp(r'^[a-z0-9][a-z0-9-]{2,62}$');
  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final StorefrontCacheDatabase _database;

  @override
  Future<CustomerCartSnapshot> read({required String shopSlug}) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      return _snapshot(shopSlug, await _readRows(shopSlug));
    });
  }

  @override
  Future<CustomerCartSnapshot> setProduct({
    required String shopSlug,
    required StorefrontProductSummary product,
    required int quantity,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      _requirePublicationId(product.id);
      _requireQuantity(quantity);
      _requirePublicName(product.name);
      if (product.priceClp < 0 ||
          (product.compareAtPriceClp != null &&
              product.compareAtPriceClp! < product.priceClp) ||
          product.availability == StorefrontAvailability.unavailable) {
        throw const CartRepositoryException(CartFailureKind.unavailable);
      }
      final imageUrl = product.images?.thumb;
      if (imageUrl != null) _requirePublicImage(imageUrl);

      return _database.transaction(() async {
        final existing = await _find(shopSlug, product.id);
        if (existing == null) {
          final count =
              await (_database.selectOnly(_database.storefrontGuestCartItems)
                    ..addColumns([
                      _database.storefrontGuestCartItems.publicationId.count(),
                    ])
                    ..where(
                      _database.storefrontGuestCartItems.shopSlug.equals(
                        shopSlug,
                      ),
                    ))
                  .map(
                    (row) => row.read(
                      _database.storefrontGuestCartItems.publicationId.count(),
                    ),
                  )
                  .getSingle();
          if ((count ?? 0) >= customerCartMaximumLines) {
            throw const CartRepositoryException(CartFailureKind.limitReached);
          }
        }

        await _database
            .into(_database.storefrontGuestCartItems)
            .insertOnConflictUpdate(
              StorefrontGuestCartItemsCompanion.insert(
                shopSlug: shopSlug,
                publicationId: product.id,
                quantity: quantity,
                publicName: product.name,
                priceClp: product.priceClp,
                compareAtPriceClp: Value(product.compareAtPriceClp),
                imageUrl: Value(imageUrl?.toString()),
                availability: _availabilityToWire(product.availability),
                updatedAt: DateTime.now().toUtc(),
              ),
            );
        return _snapshot(shopSlug, await _readRows(shopSlug));
      });
    });
  }

  @override
  Future<CustomerCartSnapshot> setQuantity({
    required String shopSlug,
    required String publicationId,
    required int quantity,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      _requirePublicationId(publicationId);
      _requireQuantity(quantity);
      return _database.transaction(() async {
        final updated =
            await (_database.update(_database.storefrontGuestCartItems)..where(
                  (row) =>
                      row.shopSlug.equals(shopSlug) &
                      row.publicationId.equals(publicationId),
                ))
                .write(
                  StorefrontGuestCartItemsCompanion(
                    quantity: Value(quantity),
                    updatedAt: Value(DateTime.now().toUtc()),
                  ),
                );
        if (updated != 1) {
          throw const CartRepositoryException(CartFailureKind.invalidInput);
        }
        return _snapshot(shopSlug, await _readRows(shopSlug));
      });
    });
  }

  @override
  Future<CustomerCartSnapshot> remove({
    required String shopSlug,
    required String publicationId,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      _requirePublicationId(publicationId);
      return _database.transaction(() async {
        await (_database.delete(_database.storefrontGuestCartItems)..where(
              (row) =>
                  row.shopSlug.equals(shopSlug) &
                  row.publicationId.equals(publicationId),
            ))
            .go();
        return _snapshot(shopSlug, await _readRows(shopSlug));
      });
    });
  }

  @override
  Future<CustomerCartSnapshot> clear({required String shopSlug}) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      await (_database.delete(
        _database.storefrontGuestCartItems,
      )..where((row) => row.shopSlug.equals(shopSlug))).go();
      return CustomerCartSnapshot.empty(
        shopSlug: shopSlug,
        source: CartSource.guest,
      );
    });
  }

  @override
  Future<CustomerCartSnapshot> retainOnly({
    required String shopSlug,
    required Set<String> publicationIds,
  }) {
    return _guard(() async {
      _requireShopSlug(shopSlug);
      for (final publicationId in publicationIds) {
        _requirePublicationId(publicationId);
      }
      return _database.transaction(() async {
        final statement = _database.delete(_database.storefrontGuestCartItems)
          ..where((row) {
            final sameShop = row.shopSlug.equals(shopSlug);
            return publicationIds.isEmpty
                ? sameShop
                : sameShop & row.publicationId.isNotIn(publicationIds);
          });
        await statement.go();
        return _snapshot(shopSlug, await _readRows(shopSlug));
      });
    });
  }

  Future<StorefrontGuestCartItemRow?> _find(
    String shopSlug,
    String publicationId,
  ) {
    final query = _database.select(_database.storefrontGuestCartItems)
      ..where(
        (row) =>
            row.shopSlug.equals(shopSlug) &
            row.publicationId.equals(publicationId),
      );
    return query.getSingleOrNull();
  }

  Future<List<StorefrontGuestCartItemRow>> _readRows(String shopSlug) {
    final query = _database.select(_database.storefrontGuestCartItems)
      ..where((row) => row.shopSlug.equals(shopSlug))
      ..orderBy([
        (row) => OrderingTerm.desc(row.updatedAt),
        (row) => OrderingTerm.asc(row.publicationId),
      ])
      ..limit(customerCartMaximumLines + 1);
    return query.get();
  }

  CustomerCartSnapshot _snapshot(
    String shopSlug,
    List<StorefrontGuestCartItemRow> rows,
  ) {
    if (rows.length > customerCartMaximumLines) {
      throw const FormatException('guest_cart_limit');
    }
    final seen = <String>{};
    final items = rows
        .map((row) {
          if (row.shopSlug != shopSlug || !seen.add(row.publicationId)) {
            throw const FormatException('guest_cart_scope');
          }
          _requirePublicationId(row.publicationId, corrupt: true);
          _requireQuantity(row.quantity, corrupt: true);
          _requirePublicName(row.publicName, corrupt: true);
          if (row.priceClp < 0 ||
              (row.compareAtPriceClp != null &&
                  row.compareAtPriceClp! < row.priceClp)) {
            throw const FormatException('guest_cart_price');
          }
          final imageUrl = row.imageUrl == null
              ? null
              : Uri.tryParse(row.imageUrl!);
          if (row.imageUrl != null && imageUrl == null) {
            throw const FormatException('guest_cart_image');
          }
          if (imageUrl != null) _requirePublicImage(imageUrl, corrupt: true);
          final availability = _availabilityFromWire(row.availability);
          return CartLine(
            publicationId: row.publicationId,
            publicName: row.publicName,
            quantity: row.quantity,
            priceClp: row.priceClp,
            snapshotPriceClp: row.priceClp,
            compareAtPriceClp: row.compareAtPriceClp,
            imageUrl: imageUrl,
            availability: availability,
            status: availability == StorefrontAvailability.unavailable
                ? CartLineStatus.unavailable
                : CartLineStatus.available,
            changeType: availability == StorefrontAvailability.unavailable
                ? CartLineChangeType.unavailable
                : CartLineChangeType.none,
            isGuest: true,
          );
        })
        .toList(growable: false);
    final subtotal = items.fold<int>(
      0,
      (total, item) => total + item.lineSubtotalClp,
    );
    return CustomerCartSnapshot(
      shopSlug: shopSlug,
      version: 0,
      items: items,
      source: CartSource.guest,
      quoteStatus: CartQuoteStatus.indicative,
      requiresCustomerReview: false,
      subtotalClp: subtotal,
      idempotent: true,
    );
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on CartRepositoryException {
      rethrow;
    } on FormatException {
      throw const CartRepositoryException(CartFailureKind.unexpected);
    } on Object {
      throw const CartRepositoryException(CartFailureKind.unexpected);
    }
  }

  static void _requireShopSlug(String value) {
    if (!_shopSlug.hasMatch(value)) {
      throw const CartRepositoryException(CartFailureKind.invalidInput);
    }
  }

  static void _requirePublicationId(String value, {bool corrupt = false}) {
    if (!_uuid.hasMatch(value)) {
      if (corrupt) throw const FormatException('guest_cart_publication');
      throw const CartRepositoryException(CartFailureKind.invalidInput);
    }
  }

  static void _requireQuantity(int value, {bool corrupt = false}) {
    if (value < 1 || value > customerCartMaximumQuantity) {
      if (corrupt) throw const FormatException('guest_cart_quantity');
      throw const CartRepositoryException(CartFailureKind.invalidInput);
    }
  }

  static void _requirePublicName(String value, {bool corrupt = false}) {
    final invalid =
        value.isEmpty ||
        value.trim() != value ||
        value.runes.length > 200 ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(value) ||
        RegExp(
          r'[\u061c\u200e\u200f\u202a-\u202e\u2066-\u2069]',
        ).hasMatch(value);
    if (!invalid) return;
    if (corrupt) throw const FormatException('guest_cart_name');
    throw const CartRepositoryException(CartFailureKind.invalidInput);
  }

  static void _requirePublicImage(Uri uri, {bool corrupt = false}) {
    final invalid =
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        !uri.pathSegments.contains('storefront-product-images') ||
        uri.pathSegments.contains('product-images');
    if (!invalid) return;
    if (corrupt) throw const FormatException('guest_cart_image');
    throw const CartRepositoryException(CartFailureKind.invalidInput);
  }
}

String _availabilityToWire(StorefrontAvailability value) => switch (value) {
  StorefrontAvailability.available => 'available',
  StorefrontAvailability.lowStock => 'low_stock',
  StorefrontAvailability.unavailable => 'unavailable',
  StorefrontAvailability.reservationOnly => 'reservation_only',
  StorefrontAvailability.pickupOnly => 'pickup_only',
  StorefrontAvailability.deliveryOnly => 'delivery_only',
};

StorefrontAvailability _availabilityFromWire(String value) => switch (value) {
  'available' => StorefrontAvailability.available,
  'low_stock' => StorefrontAvailability.lowStock,
  'unavailable' => StorefrontAvailability.unavailable,
  'reservation_only' => StorefrontAvailability.reservationOnly,
  'pickup_only' => StorefrontAvailability.pickupOnly,
  'delivery_only' => StorefrontAvailability.deliveryOnly,
  _ => throw const FormatException('guest_cart_availability'),
};
