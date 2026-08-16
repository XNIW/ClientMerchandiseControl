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
      expect(value?.courierCoordinate?.longitude, -70.655);

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
}
