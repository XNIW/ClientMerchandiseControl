import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../account/application/customer_account_controller.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/application/cart_state.dart';
import '../data/shared_preferences_checkout_draft_store.dart';
import '../data/supabase_checkout_repository.dart';
import '../domain/checkout_repository.dart';

final checkoutCartStateProvider = Provider<CartState>((ref) {
  return ref.watch(cartControllerProvider);
});

final checkoutAccountStateProvider = Provider<CustomerAccountState>((ref) {
  return ref.watch(customerAccountControllerProvider);
});

final checkoutCartRefreshProvider = Provider<Future<void> Function()>((ref) {
  return ref.read(cartControllerProvider.notifier).refresh;
});

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return SupabaseCheckoutRepository(
    port: PlatformCheckoutPort(Supabase.instance.client),
  );
});

final checkoutDraftStoreProvider = Provider<CheckoutDraftStore>((ref) {
  return SharedPreferencesCheckoutDraftStore();
});

final checkoutClockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});
