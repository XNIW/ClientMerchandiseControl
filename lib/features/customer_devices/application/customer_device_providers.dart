import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/auth_state.dart';
import '../../auth/domain/authenticated_customer.dart';
import '../data/shared_preferences_customer_device_store.dart';
import '../data/supabase_customer_device_repository.dart';
import '../data/unconfigured_push_token_provider.dart';
import '../domain/customer_device_repository.dart';
import 'customer_device_sign_out_coordinator.dart';

final customerDeviceIdentityProvider = Provider<AuthenticatedCustomer?>((ref) {
  return switch (ref.watch(authControllerProvider)) {
    AuthAuthenticated(:final customer) => customer,
    _ => null,
  };
});

final customerDeviceUuidFactoryProvider = Provider<CustomerDeviceUuidFactory>((
  ref,
) {
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

final customerDeviceLocalStoreProvider = Provider<CustomerDeviceLocalStore>((
  ref,
) {
  return SharedPreferencesCustomerDeviceStore(
    uuidFactory: ref.watch(customerDeviceUuidFactoryProvider),
  );
});

final customerPushTokenProvider = Provider<CustomerPushTokenProvider>((ref) {
  return const UnconfiguredPushTokenProvider();
});

final customerDeviceRepositoryProvider = Provider<CustomerDeviceRepository>((
  ref,
) {
  return SupabaseCustomerDeviceRepository(
    port: PlatformCustomerDevicePort(Supabase.instance.client),
  );
});

final customerDeviceSignOutCoordinatorProvider =
    Provider<CustomerDeviceSignOutCoordinator>((ref) {
      return CustomerDeviceSignOutCoordinator(
        repository: ref.watch(customerDeviceRepositoryProvider),
        localStore: ref.watch(customerDeviceLocalStoreProvider),
        pushTokenProvider: ref.watch(customerPushTokenProvider),
        uuidFactory: ref.watch(customerDeviceUuidFactoryProvider),
      );
    });
