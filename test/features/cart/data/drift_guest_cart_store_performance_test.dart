import 'package:client_merchandise_control/features/cart/data/drift_guest_cart_store.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'carrello guest al cap rispetta budget warm read e mutation',
    () async {
      final database = StorefrontCacheDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftGuestCartStore(database);

      for (var index = 0; index < customerCartMaximumLines; index++) {
        await store.setProduct(
          shopSlug: 'storefront-test',
          product: _product(index),
          quantity: 1,
        );
      }

      for (var warmUp = 0; warmUp < 5; warmUp++) {
        final snapshot = await store.read(shopSlug: 'storefront-test');
        expect(snapshot.items, hasLength(customerCartMaximumLines));
      }

      final reads = <int>[];
      final mutations = <int>[];
      for (var sample = 0; sample < 30; sample++) {
        final readWatch = Stopwatch()..start();
        final snapshot = await store.read(shopSlug: 'storefront-test');
        readWatch.stop();
        expect(snapshot.items, hasLength(customerCartMaximumLines));
        reads.add(readWatch.elapsedMicroseconds);

        final mutationWatch = Stopwatch()..start();
        final updated = await store.setQuantity(
          shopSlug: 'storefront-test',
          publicationId: _publicationId(sample),
          quantity: sample.isEven ? 2 : 1,
        );
        mutationWatch.stop();
        expect(updated.items, hasLength(customerCartMaximumLines));
        mutations.add(mutationWatch.elapsedMicroseconds);
      }

      final readP50 = _percentile(reads, 0.50);
      final readP95 = _percentile(reads, 0.95);
      final readP99 = _percentile(reads, 0.99);
      final mutationP50 = _percentile(mutations, 0.50);
      final mutationP95 = _percentile(mutations, 0.95);
      final mutationP99 = _percentile(mutations, 0.99);
      debugPrint(
        'GUEST_CART_PERF rows=$customerCartMaximumLines '
        'read_us=$readP50/$readP95/$readP99 '
        'mutation_us=$mutationP50/$mutationP95/$mutationP99',
      );

      expect(readP95, lessThan(15000));
      expect(mutationP95, lessThan(50000));
    },
    tags: const ['performance'],
  );
}

int _percentile(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * percentile).ceil()];
}

String _publicationId(int index) =>
    '50000000-0000-4000-8000-${index.toString().padLeft(12, '0')}';

StorefrontProductSummary _product(int index) => StorefrontProductSummary(
  id: _publicationId(index),
  category: StorefrontCategory(
    id:
        '40000000-0000-4000-8000-'
        '${(index % 20).toString().padLeft(12, '0')}',
    slug: 'categoria-${index % 20}',
    name: 'Categoría ${index % 20}',
    sortRank: index % 20,
  ),
  name: 'Producto público $index',
  priceClp: 1000 + index,
  featured: false,
  sortRank: index,
  availability: StorefrontAvailability.available,
  fulfillment: const StorefrontFulfillment(
    pickup: true,
    delivery: true,
    reservation: false,
  ),
  catalogVersion: 7,
  publishedAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);
