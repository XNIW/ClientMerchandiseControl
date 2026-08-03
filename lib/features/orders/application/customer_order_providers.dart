import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/authenticated_customer.dart';
import '../data/shared_preferences_customer_order_cache.dart';
import '../data/supabase_customer_order_repository.dart';
import '../domain/customer_order_repository.dart';

typedef CustomerOrderIdempotencyKeyFactory = String Function();

final customerOrderIdentityProvider = Provider<AuthenticatedCustomer?>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AuthAuthenticated(:final customer) => customer,
    _ => null,
  };
});

final customerOrderShopSlugProvider = Provider<String?>((ref) {
  return ref.watch(appConfigProvider).storefrontShopSlug;
});

final customerOrderRepositoryProvider = Provider<CustomerOrderRepository>((
  ref,
) {
  return SupabaseCustomerOrderRepository(
    port: PlatformCustomerOrderPort(Supabase.instance.client),
  );
});

final customerOrderCacheStoreProvider = Provider<CustomerOrderCacheStore>((
  ref,
) {
  return SharedPreferencesCustomerOrderCache();
});

final customerOrderClockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});

final customerOrderIdempotencyKeyFactoryProvider =
    Provider<CustomerOrderIdempotencyKeyFactory>((ref) {
      final random = Random.secure();
      return () {
        final bytes = List<int>.generate(16, (_) => random.nextInt(256));
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
        bytes[8] = (bytes[8] & 0x3f) | 0x80;
        final hex = bytes
            .map((value) => value.toRadixString(16).padLeft(2, '0'))
            .join();
        return '${hex.substring(0, 8)}-'
            '${hex.substring(8, 12)}-'
            '${hex.substring(12, 16)}-'
            '${hex.substring(16, 20)}-'
            '${hex.substring(20)}';
      };
    });
