import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/navigation/app_navigator.dart';
import '../presentation/google_address_map.dart';
import '../../delivery_tracking/presentation/delivery_live_map.dart'
    show deliveryMapNativeConfigurationProbeProvider;
import '../../account/application/customer_account_providers.dart';
import '../data/address_provider_adapters.dart';
import '../data/photon_address_provider.dart';
import '../data/shared_preferences_delivery_context_cache.dart';
import '../data/supabase_delivery_context_repository.dart';
import '../domain/delivery_address_ports.dart';
import '../domain/delivery_context_cache.dart';
import '../domain/delivery_context_repository.dart';

final deliveryContextIdentityProvider = customerAccountIdentityProvider;

final deliveryContextShopSlugProvider = customerAccountShopSlugProvider;

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
  ref.watch(deliveryContextIdentityProvider);
  var disposed = false;
  ref.onDispose(() => disposed = true);
  return GoogleAddressMapPort(
    nativeConfigurationProbe: ref.watch(
      deliveryMapNativeConfigurationProbeProvider,
    ),
    isCurrent: () => !disposed,
    navigatorKey: ref.watch(appNavigatorKeyProvider),
    enabled:
        ref.watch(appConfigProvider).environment == AppEnvironment.staging &&
        const bool.fromEnvironment('ADDRESS_MAPS_ENABLED') &&
        const bool.fromEnvironment('DELIVERY_MAPS_NATIVE_CONFIGURED'),
  );
});

final addressProviderConfigurationProvider =
    Provider<AddressProviderConfiguration>(
      (ref) => AddressProviderConfiguration.fromEnvironment(),
    );

final photonAddressProvider = Provider<PhotonAddressProvider>((ref) {
  ref.watch(deliveryContextIdentityProvider);
  final provider = PhotonAddressProvider(
    configuration: ref.watch(addressProviderConfigurationProvider),
    client: http.Client(),
  );
  ref.onDispose(provider.dispose);
  return provider;
});

final addressSearchPortProvider = Provider<AddressSearchPort>(
  (ref) => ref.watch(photonAddressProvider),
);
final reverseGeocodingPortProvider = Provider<ReverseGeocodingPort>(
  (ref) => ref.watch(photonAddressProvider),
);

final currentLocationPortProvider = Provider<CurrentLocationPort>((ref) {
  return const PlatformCurrentLocationPort();
});
