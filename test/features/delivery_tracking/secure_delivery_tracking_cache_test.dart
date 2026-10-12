import 'dart:convert';

import 'package:client_merchandise_control/features/delivery_tracking/data/secure_delivery_tracking_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_tracking_test_support.dart';

void main() {
  test(
    'encrypted cache round-trips only the matching owner/order context',
    () async {
      final preferences = MemoryDeliveryTrackingSecurePreferences();
      final cache = SecureDeliveryTrackingCache(
        preferences: preferences,
        clock: () => trackingTestNow,
      );
      await cache.save(
        ownerSubjectId: trackingTestOwner,
        shopSlug: trackingTestShop,
        snapshot: trackingLiveSnapshot(),
      );

      final value = await cache.read(
        ownerSubjectId: trackingTestOwner,
        shopSlug: trackingTestShop,
        orderId: trackingTestOrder,
      );
      expect(value?.courierCoordinate, isNull);
      expect(value?.storeCoordinate, isNull);
      expect(value?.destinationCoordinate, isNull);
      expect(value?.hasFreshLiveLocation, isFalse);
      expect(value?.version, 4);

      final mismatch = await cache.read(
        ownerSubjectId: '20000000-0000-4000-8000-000000044002',
        shopSlug: trackingTestShop,
        orderId: trackingTestOrder,
      );
      expect(mismatch, isNull);
      expect(preferences.value, isNull);
    },
  );

  test('precise cache expires after the bounded retention window', () async {
    final preferences = MemoryDeliveryTrackingSecurePreferences();
    var now = trackingTestNow;
    final cache = SecureDeliveryTrackingCache(
      preferences: preferences,
      clock: () => now,
    );
    await cache.save(
      ownerSubjectId: trackingTestOwner,
      shopSlug: trackingTestShop,
      snapshot: trackingLiveSnapshot(),
    );
    now = now.add(const Duration(minutes: 16));

    expect(
      await cache.read(
        ownerSubjectId: trackingTestOwner,
        shopSlug: trackingTestShop,
        orderId: trackingTestOrder,
      ),
      isNull,
    );
    expect(preferences.value, isNull);
  });
  test('delete fallibile usa tombstone senza coordinate anche dopo reopen', () async {
    final preferences = _RevocationTrackingPreferences();
    final cache = SecureDeliveryTrackingCache(
      preferences: preferences,
      clock: () => trackingTestNow,
    );
    await cache.save(
      ownerSubjectId: trackingTestOwner,
      shopSlug: trackingTestShop,
      snapshot: trackingLiveSnapshot(),
    );
    preferences.failDelete = true;
    await cache.clear(ownerSubjectId: trackingTestOwner);
    expect(jsonDecode(preferences.value!), {'version': 1, 'revoked': true});
    expect(preferences.value, isNot(contains(trackingTestOwner)));
    expect(preferences.value, isNot(contains('-33.')));
    final reopened = SecureDeliveryTrackingCache(
      preferences: preferences,
      clock: () => trackingTestNow,
    );
    expect(
      await reopened.read(
        ownerSubjectId: trackingTestOwner,
        shopSlug: trackingTestShop,
        orderId: trackingTestOrder,
      ),
      isNull,
    );
    expect(preferences.deleteCalls, 1);
  });

  test('doppio failure espone errore e nessuna cache riattiva GPS preciso', () async {
    final preferences = _RevocationTrackingPreferences();
    final cache = SecureDeliveryTrackingCache(
      preferences: preferences,
      clock: () => trackingTestNow,
    );
    await cache.save(
      ownerSubjectId: trackingTestOwner,
      shopSlug: trackingTestShop,
      snapshot: trackingLiveSnapshot(),
    );
    preferences
      ..failDelete = true
      ..failWrite = true;
    await expectLater(
      cache.clear(ownerSubjectId: trackingTestOwner),
      throwsA(isA<DeliveryTrackingCacheCleanupException>()),
    );
    expect(
      await cache.read(
        ownerSubjectId: trackingTestOwner,
        shopSlug: trackingTestShop,
        orderId: trackingTestOrder,
      ),
      isNull,
    );
    final reopened = SecureDeliveryTrackingCache(
      preferences: preferences,
      clock: () => trackingTestNow,
    );
    final context = await reopened.read(
      ownerSubjectId: trackingTestOwner,
      shopSlug: trackingTestShop,
      orderId: trackingTestOrder,
    );
    expect(context?.version, 4);
    expect(context?.courierCoordinate, isNull);
    expect(context?.destinationCoordinate, isNull);
    expect(context?.storeCoordinate, isNull);
    expect(context?.hasFreshLiveLocation, isFalse);
    preferences.failWrite = false;
    await cache.clear(ownerSubjectId: trackingTestOwner);
    expect(jsonDecode(preferences.value!), {'version': 1, 'revoked': true});
  });
}

final class _RevocationTrackingPreferences
    implements DeliveryTrackingSecurePreferences {
  String? value;
  var failDelete = false;
  var failWrite = false;
  var deleteCalls = 0;

  @override
  Future<String?> read(String key) async => value;

  @override
  Future<void> write(String key, String next) async {
    if (failWrite) throw StateError('synthetic_cache_write_failure');
    value = next;
  }

  @override
  Future<void> delete(String key) async {
    deleteCalls++;
    if (failDelete) throw StateError('synthetic_cache_delete_failure');
    value = null;
  }
}
