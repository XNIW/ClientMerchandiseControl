import 'dart:io';

import 'package:client_merchandise_control/features/cart/data/drift_guest_cart_store.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_failure.dart';
import 'package:client_merchandise_control/features/storefront/cache/drift_storefront_cache_repository.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';

void main() {
  test('persiste solo snapshot pubblici attraverso un riavvio reale', () async {
    final directory = await Directory.systemTemp.createTemp('guest-cart-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/cart.sqlite');

    var database = StorefrontCacheDatabase(NativeDatabase(file));
    var store = DriftGuestCartStore(database);
    final written = await store.setProduct(
      shopSlug: 'storefront-test',
      product: _product(),
      quantity: 2,
    );
    expect(written.totalQuantity, 2);
    expect(written.subtotalClp, 2400);
    await database.close();

    database = StorefrontCacheDatabase(NativeDatabase(file));
    addTearDown(database.close);
    store = DriftGuestCartStore(database);
    final restored = await store.read(shopSlug: 'storefront-test');

    expect(restored.items.single.publicationId, _publicationId);
    expect(restored.items.single.publicName, 'Café público');
    expect(restored.items.single.imageUrl.toString(), contains('/public/'));
    expect(restored.items.single.isGuest, isTrue);
    expect(restored.version, 0);
  });

  test('isola shop e supporta quantità, remove e clear', () async {
    final database = StorefrontCacheDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftGuestCartStore(database);
    await store.setProduct(
      shopSlug: 'storefront-test',
      product: _product(),
      quantity: 1,
    );

    expect((await store.read(shopSlug: 'storefront-other')).items, isEmpty);
    expect(
      (await store.setQuantity(
        shopSlug: 'storefront-test',
        publicationId: _publicationId,
        quantity: 3,
      )).items.single.quantity,
      3,
    );
    expect(
      (await store.remove(
        shopSlug: 'storefront-test',
        publicationId: _publicationId,
      )).items,
      isEmpty,
    );
    await store.setProduct(
      shopSlug: 'storefront-test',
      product: _product(),
      quantity: 1,
    );
    expect((await store.clear(shopSlug: 'storefront-test')).items, isEmpty);
  });

  test('refresh catalogo non cancella il carrello guest', () async {
    final database = StorefrontCacheDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftGuestCartStore(database);
    final cache = DriftStorefrontCacheRepository(database);
    await store.setProduct(
      shopSlug: 'storefront-test',
      product: _product(),
      quantity: 1,
    );

    await cache.clearShop(shopSlug: 'storefront-test');

    expect(
      (await store.read(
        shopSlug: 'storefront-test',
      )).items.single.publicationId,
      _publicationId,
    );
  });

  test(
    'refresh prodotto rivalida snapshot cart e favorite senza perdere quantità',
    () async {
      final database = StorefrontCacheDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftGuestCartStore(database);
      final cache = DriftStorefrontCacheRepository(database);
      final initial = _product();
      await cache.writeProductDetail(
        shopSlug: 'storefront-test',
        product: initial,
      );
      await cache.toggleFavorite(
        shopSlug: 'storefront-test',
        publicationId: initial.id,
      );
      await store.setProduct(
        shopSlug: 'storefront-test',
        product: initial,
        quantity: 2,
      );

      for (final availability in StorefrontAvailability.values) {
        final refreshed = _product(
          name: 'Café rivalidado',
          priceClp: 1800,
          compareAtPriceClp: 2200,
          availability: availability,
        );
        await cache.writeProductDetail(
          shopSlug: 'storefront-test',
          product: refreshed,
        );

        final cart = await store.read(shopSlug: 'storefront-test');
        final favorite = await cache.readFavorites(shopSlug: 'storefront-test');
        expect(cart.items, hasLength(1));
        expect(cart.items.single.quantity, 2);
        expect(cart.items.single.publicName, 'Café rivalidado');
        expect(cart.items.single.priceClp, 1800);
        expect(cart.items.single.compareAtPriceClp, 2200);
        expect(cart.items.single.availability, availability);
        expect(
          cart.subtotalClp,
          availability == StorefrontAvailability.unavailable ? 0 : 3600,
        );
        expect(favorite.single.publicationId, _publicationId);
        expect(favorite.single.product?.availability, availability);
      }
    },
  );

  test('refresh prodotto resta isolato per shop e publication', () async {
    final database = StorefrontCacheDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftGuestCartStore(database);
    final cache = DriftStorefrontCacheRepository(database);
    await store.setProduct(
      shopSlug: 'storefront-test',
      product: _product(),
      quantity: 2,
    );

    await cache.writeProductDetail(
      shopSlug: 'storefront-other',
      product: _product(
        name: 'Altro negozio',
        priceClp: 9900,
        availability: StorefrontAvailability.unavailable,
      ),
    );
    await cache.writeProductDetail(
      shopSlug: 'storefront-test',
      product: _product(
        id: '50000000-0000-4000-8000-000000000002',
        name: 'Altro prodotto',
        priceClp: 8800,
        availability: StorefrontAvailability.unavailable,
      ),
    );

    final cart = await store.read(shopSlug: 'storefront-test');
    expect(cart.items.single.publicName, 'Café público');
    expect(cart.items.single.priceClp, 1200);
    expect(cart.items.single.availability, StorefrontAvailability.available);
    expect(cart.items.single.quantity, 2);
  });

  test('retainOnly elimina solo gli item confermati dal merge', () async {
    final database = StorefrontCacheDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftGuestCartStore(database);
    final rejectedId = '50000000-0000-4000-8000-000000000002';
    await store.setProduct(
      shopSlug: 'storefront-test',
      product: _product(),
      quantity: 1,
    );
    await store.setProduct(
      shopSlug: 'storefront-test',
      product: _product(id: rejectedId, name: 'Té público'),
      quantity: 2,
    );

    final retained = await store.retainOnly(
      shopSlug: 'storefront-test',
      publicationIds: {rejectedId},
    );

    expect(retained.items.map((item) => item.publicationId), [rejectedId]);
    expect(retained.items.single.quantity, 2);
  });

  test('rifiuta quantità, prodotto unavailable e URL interno', () async {
    final database = StorefrontCacheDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftGuestCartStore(database);

    for (final product in [
      _product(availability: StorefrontAvailability.unavailable),
      _product(internalImage: true),
    ]) {
      await expectLater(
        store.setProduct(
          shopSlug: 'storefront-test',
          product: product,
          quantity: 1,
        ),
        throwsA(isA<CartRepositoryException>()),
      );
    }
    await expectLater(
      store.setProduct(
        shopSlug: 'storefront-test',
        product: _product(),
        quantity: 100,
      ),
      throwsA(
        isA<CartRepositoryException>().having(
          (error) => error.kind,
          'kind',
          CartFailureKind.invalidInput,
        ),
      ),
    );
  });

  test(
    'corruzione locale fallisce chiusa senza restituire righe parziali',
    () async {
      final database = StorefrontCacheDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftGuestCartStore(database);
      await store.setProduct(
        shopSlug: 'storefront-test',
        product: _product(),
        quantity: 1,
      );
      await database.customStatement(
        "UPDATE storefront_guest_cart_items SET image_url = "
        "'https://example.invalid/storefront-product-images/item.webp?token=secret'",
      );

      await expectLater(
        store.read(shopSlug: 'storefront-test'),
        throwsA(
          isA<CartRepositoryException>().having(
            (error) => error.kind,
            'kind',
            CartFailureKind.unexpected,
          ),
        ),
      );
    },
  );
}

StorefrontProductSummary _product({
  String id = _publicationId,
  String name = 'Café público',
  int priceClp = 1200,
  int? compareAtPriceClp = 1500,
  StorefrontAvailability availability = StorefrontAvailability.available,
  bool internalImage = false,
}) {
  final base = internalImage
      ? 'https://example.invalid/storage/v1/object/public/product-images/internal'
      : 'https://example.invalid/storage/v1/object/public/storefront-product-images/public';
  return StorefrontProductSummary(
    id: id,
    category: const StorefrontCategory(
      id: '40000000-0000-4000-8000-000000000001',
      slug: 'bebidas',
      name: 'Bebidas',
      sortRank: 1,
    ),
    name: name,
    priceClp: priceClp,
    compareAtPriceClp: compareAtPriceClp,
    discountBps: compareAtPriceClp == null ? null : 2000,
    featured: false,
    sortRank: 1,
    availability: availability,
    fulfillment: const StorefrontFulfillment(
      pickup: true,
      delivery: true,
      reservation: false,
    ),
    images: StorefrontImageSet(
      version: '90000000-0000-4000-8000-000000000001',
      thumb: Uri.parse('$base/thumb.webp'),
      card: Uri.parse('$base/card.webp'),
      detail: Uri.parse('$base/detail.webp'),
      sha256:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    ),
    catalogVersion: 7,
    publishedAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );
}
