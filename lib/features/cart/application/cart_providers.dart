import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../storefront/application/storefront_providers.dart';
import '../data/drift_guest_cart_store.dart';
import '../data/supabase_customer_cart_repository.dart';
import '../domain/cart_repository.dart';
import '../../delivery_context/application/delivery_context_controller.dart';

final cartDeliveryContextStateProvider = Provider<DeliveryContextState>((ref) {
  return ref.watch(deliveryContextControllerProvider);
});

final guestCartStoreProvider = Provider<GuestCartStore>((ref) {
  return DriftGuestCartStore(ref.watch(storefrontCacheDatabaseProvider));
});

final customerCartRepositoryProvider = Provider<CustomerCartRepository>((ref) {
  return SupabaseCustomerCartRepository(
    port: PlatformCustomerCartPort(Supabase.instance.client),
  );
});
