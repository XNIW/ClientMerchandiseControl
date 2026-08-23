import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../account/application/customer_account_providers.dart';
import '../data/address_provider_adapters.dart';
import '../data/shared_preferences_delivery_context_cache.dart';
import '../data/supabase_delivery_context_repository.dart';
import '../domain/delivery_address_ports.dart';
import '../domain/delivery_context_cache.dart';
import '../domain/delivery_context_repository.dart';

final deliveryContextIdentityProvider = customerAccountIdentityProvider;

final deliveryContextShopSlugProvider = Provider<String?>((ref) {
  return ref.watch(appConfigProvider).storefrontShopSlug;
});

final deliveryContextRepositoryProvider = Provider<DeliveryContextRepository>((
  ref,
) {
  return SupabaseDeliveryContextRepository(
    port: PlatformDeliveryContextPort(Supabase.instance.client),
  );
});

final deliveryContextCacheProvider = Provider<DeliveryContextCacheStore>((ref) {
  return SharedPreferencesDeliveryContextCache();
});

final deliveryAddressMapPortProvider = Provider<DeliveryAddressMapPort>((ref) {
  return const NotConfiguredDeliveryAddressMapPort();
});

final addressSearchPortProvider = Provider<AddressSearchPort>((ref) {
  return const NotConfiguredAddressSearchPort();
});

final reverseGeocodingPortProvider = Provider<ReverseGeocodingPort>((ref) {
  return const NotConfiguredReverseGeocodingPort();
});

final currentLocationPortProvider = Provider<CurrentLocationPort>((ref) {
  return const PlatformCurrentLocationPort();
});
