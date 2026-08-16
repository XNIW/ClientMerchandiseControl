import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../orders/application/customer_order_providers.dart';
import '../data/secure_delivery_tracking_cache.dart';
import '../data/supabase_delivery_tracking_repository.dart';
import '../domain/delivery_tracking_repository.dart';

final deliveryTrackingIdentityProvider = customerOrderIdentityProvider;
final deliveryTrackingShopSlugProvider = customerOrderShopSlugProvider;

final deliveryTrackingRepositoryProvider = Provider<DeliveryTrackingRepository>(
  (ref) => SupabaseDeliveryTrackingRepository(
    port: PlatformDeliveryTrackingPort(Supabase.instance.client),
  ),
);

final deliveryTrackingCacheProvider = Provider<DeliveryTrackingCacheStore>(
  (ref) => SecureDeliveryTrackingCache(),
);

final deliveryTrackingClockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);

final deliveryTrackingPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 15),
);

final deliveryTrackingFreshnessThresholdProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 120),
);

final deliveryTrackingReconnectBaseProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 2),
);
