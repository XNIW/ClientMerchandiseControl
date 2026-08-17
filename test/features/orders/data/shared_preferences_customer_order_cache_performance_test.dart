import 'dart:convert';

import 'package:client_merchandise_control/features/orders/data/shared_preferences_customer_order_cache.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_selectors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../customer_order_test_support.dart';

void main() {
  test(
    'cache ordini al cap rispetta size e budget encode/decode',
    () async {
      final preferences = _MemoryPreferences();
      final cache = SharedPreferencesCustomerOrderCache(
        preferences: preferences,
      );
      final orders = List.generate(
        customerOrderMaximumCachedCards,
        (index) => orderTestCard(
          id:
              '44000000-0000-4000-8000-'
              '${index.toString().padLeft(12, '0')}',
          code: 'MC-${index.toRadixString(16).toUpperCase().padLeft(20, '0')}',
          placedAt: orderTestNow.subtract(Duration(minutes: index)),
        ),
        growable: false,
      );
      final snapshot = orderTestCache(
        orders: orders,
        details: const <String, CustomerOrderDetail>{},
      );

      await cache.save(snapshot);
      await cache.read(ownerSubjectId: orderTestOwner, shopSlug: orderTestShop);
      final writes = <int>[];
      final reads = <int>[];
      for (var sample = 0; sample < 30; sample++) {
        final writeWatch = Stopwatch()..start();
        await cache.save(snapshot);
        writeWatch.stop();
        writes.add(writeWatch.elapsedMicroseconds);

        final readWatch = Stopwatch()..start();
        final restored = await cache.read(
          ownerSubjectId: orderTestOwner,
          shopSlug: orderTestShop,
        );
        readWatch.stop();
        reads.add(readWatch.elapsedMicroseconds);
        expect(restored?.orders, hasLength(customerOrderMaximumCachedCards));
      }

      final encodedBytes = utf8
          .encode(
            preferences.values[SharedPreferencesCustomerOrderCache.storageKey]!,
          )
          .length;
      final writeP50 = _percentile(writes, 0.50);
      final writeP95 = _percentile(writes, 0.95);
      final writeP99 = _percentile(writes, 0.99);
      final readP50 = _percentile(reads, 0.50);
      final readP95 = _percentile(reads, 0.95);
      final readP99 = _percentile(reads, 0.99);
      debugPrint(
        'CUSTOMER_ORDER_CACHE_PERF '
        'rows=$customerOrderMaximumCachedCards bytes=$encodedBytes '
        'write_us=$writeP50/$writeP95/$writeP99 '
        'read_us=$readP50/$readP95/$readP99',
      );

      expect(
        encodedBytes,
        lessThanOrEqualTo(
          SharedPreferencesCustomerOrderCache.maximumEncodedBytes,
        ),
      );
      expect(writeP95, lessThan(100000));
      expect(readP95, lessThan(50000));
    },
    tags: const ['performance'],
  );

  test(
    '500 ordini sintetici rispettano il budget selector e filter',
    () {
      final statuses = CustomerOrderStatus.values;
      final orders = List.generate(
        500,
        (index) => orderTestCard(
          id:
              '44000000-0000-4000-8000-'
              '${index.toString().padLeft(12, '0')}',
          code: 'MC-${index.toRadixString(16).toUpperCase().padLeft(20, '0')}',
          status: statuses[index % statuses.length],
          version: index + 1,
          placedAt: orderTestNow.subtract(Duration(minutes: index)),
        ),
        growable: false,
      );
      for (var warmUp = 0; warmUp < 20; warmUp++) {
        selectPrimaryActiveOrder(orders);
        filterCustomerOrders(orders, CustomerOrderListFilter.active);
      }
      final samples = <int>[];
      for (var sample = 0; sample < 200; sample++) {
        final watch = Stopwatch()..start();
        final active = filterCustomerOrders(
          orders,
          CustomerOrderListFilter.active,
        );
        final primary = selectPrimaryActiveOrder(active);
        watch.stop();
        expect(primary, isNotNull);
        samples.add(watch.elapsedMicroseconds);
      }
      final p50 = _percentile(samples, 0.50);
      final p95 = _percentile(samples, 0.95);
      final p99 = _percentile(samples, 0.99);
      debugPrint(
        'CUSTOMER_ORDER_SELECTOR_PERF rows=500 '
        'selector_us=$p50/$p95/$p99',
      );
      expect(p95, lessThan(5000));
    },
    tags: const ['performance'],
  );
}

int _percentile(List<int> values, double percentile) {
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * percentile).ceil()];
}

final class _MemoryPreferences implements CustomerOrderCachePreferences {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
