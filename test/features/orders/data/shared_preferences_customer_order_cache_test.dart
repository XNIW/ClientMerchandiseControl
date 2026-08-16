import 'dart:convert';

import 'package:client_merchandise_control/features/orders/data/shared_preferences_customer_order_cache.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../customer_order_test_support.dart';

void main() {
  late _MemoryPreferences preferences;
  late SharedPreferencesCustomerOrderCache cache;

  setUp(() {
    preferences = _MemoryPreferences();
    cache = SharedPreferencesCustomerOrderCache(preferences: preferences);
  });

  test(
    'roundtrip conserva lista, dettaglio, cursor e retry idempotente',
    () async {
      final placed = orderTestNow.subtract(const Duration(minutes: 2));
      final snapshot = orderTestCache(
        nextCursor: CustomerOrderCursor(
          beforePlacedAt: placed,
          beforeOrderId: orderTestOrder,
        ),
        pendingCancellation: CustomerOrderPendingCancellation(
          orderId: orderTestOrder,
          expectedStatusVersion: 1,
          idempotencyKey: orderTestKey,
          createdAt: orderTestNow,
        ),
      );

      await cache.save(snapshot);
      final restored = await cache.read(
        ownerSubjectId: orderTestOwner,
        shopSlug: orderTestShop,
      );

      expect(restored?.orders.single.id, orderTestOrder);
      expect(restored?.details[orderTestOrder]?.totalClp, 2400);
      expect(restored?.nextCursor?.beforeOrderId, orderTestOrder);
      expect(restored?.pendingCancellation?.idempotencyKey, orderTestKey);
      final encoded = preferences.values.values.single;
      expect(encoded, isNot(contains('source_product_id')));
      expect(encoded, isNot(contains('owner_user_id')));
      expect(encoded, isNot(contains('supplier')));
      expect(encoded, isNot(contains('token')));
    },
  );

  test(
    'account o shop diverso non eredita cache e rimuove il record',
    () async {
      await cache.save(orderTestCache());

      expect(
        await cache.read(
          ownerSubjectId: '10000000-0000-4000-8000-000000028002',
          shopSlug: orderTestShop,
        ),
        isNull,
      );
      expect(preferences.values, isEmpty);

      await cache.save(orderTestCache());
      expect(
        await cache.read(
          ownerSubjectId: orderTestOwner,
          shopSlug: 'other-shop',
        ),
        isNull,
      );
      expect(preferences.values, isEmpty);
    },
  );

  test('record corrotto o sovradimensionato viene eliminato', () async {
    preferences.values[SharedPreferencesCustomerOrderCache.storageKey] =
        '{"version":1,"ownerSubjectId":"$orderTestOwner"}';
    expect(
      await cache.read(ownerSubjectId: orderTestOwner, shopSlug: orderTestShop),
      isNull,
    );
    expect(preferences.values, isEmpty);

    preferences.values[SharedPreferencesCustomerOrderCache.storageKey] =
        'x' * (SharedPreferencesCustomerOrderCache.maximumEncodedBytes + 1);
    expect(
      await cache.read(ownerSubjectId: orderTestOwner, shopSlug: orderTestShop),
      isNull,
    );
    expect(preferences.values, isEmpty);
  });

  test('tampering economico nel dettaglio cached fallisce chiuso', () async {
    await cache.save(orderTestCache());
    final root = jsonDecode(preferences.values.values.single) as Map;
    final details = root['details'] as List;
    final detail = details.single as Map;
    final items = detail['items'] as List;
    (items.single as Map)['lineTotalClp'] = 1;
    preferences.values[SharedPreferencesCustomerOrderCache.storageKey] =
        jsonEncode(root);

    expect(
      await cache.read(ownerSubjectId: orderTestOwner, shopSlug: orderTestShop),
      isNull,
    );
    expect(preferences.values, isEmpty);
  });

  test('save rifiuta timeline e linee incoerenti', () async {
    final valid = orderTestDetail();
    final badLine = CustomerOrderDetail(
      id: valid.id,
      code: valid.code,
      status: valid.status,
      version: valid.version,
      shopSlug: valid.shopSlug,
      fulfillment: valid.fulfillment,
      subtotalClp: valid.subtotalClp,
      deliveryFeeClp: valid.deliveryFeeClp,
      totalClp: valid.totalClp,
      items: [
        CustomerOrderLine(
          publicationId: valid.items.single.publicationId,
          publicName: valid.items.single.publicName,
          quantity: 2,
          unitPriceClp: 1200,
          compareAtPriceClp: 1500,
          lineTotalClp: 1,
          promotionName: null,
          promotionEndsAt: null,
        ),
      ],
      timeline: valid.timeline,
      cancellation: valid.cancellation,
      placedAt: valid.placedAt,
      updatedAt: valid.updatedAt,
      serverTime: valid.serverTime,
      idempotent: false,
      timeZone: valid.timeZone,
    );

    await expectLater(
      cache.save(orderTestCache(details: {orderTestOrder: badLine})),
      throwsFormatException,
    );
    expect(preferences.values, isEmpty);
  });

  test('clear è owner/shop scoped e serializzato', () async {
    await cache.save(orderTestCache());
    await cache.clear(ownerSubjectId: orderTestOwner, shopSlug: 'other-shop');
    expect(preferences.values, isNotEmpty);

    await cache.clear(ownerSubjectId: orderTestOwner, shopSlug: orderTestShop);
    expect(preferences.values, isEmpty);
  });
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
