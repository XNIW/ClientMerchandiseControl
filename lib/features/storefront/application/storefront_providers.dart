import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../cache/drift_storefront_cache_repository.dart';
import '../cache/storefront_cache_database.dart';
import '../cache/storefront_cache_repository.dart';
import '../data/http_storefront_rpc_invoker.dart';
import '../data/supabase_storefront_repository.dart';
import '../domain/storefront_failure.dart';
import '../domain/storefront_repository.dart';

final storefrontHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final storefrontRpcInvokerProvider = Provider<StorefrontRpcInvoker>((ref) {
  final config = ref.watch(appConfigProvider);
  final origin = config.supabaseUrl;
  final publishableKey = config.supabasePublishableKey;
  if (origin == null || publishableKey == null) {
    return (_, _) => Future<Object?>.error(
      const StorefrontFailure(
        StorefrontFailureKind.invalidConfiguration,
        code: 'public_transport_unconfigured',
      ),
    );
  }
  final invoker = HttpStorefrontRpcInvoker(
    origin: Uri.parse(origin),
    publishableKey: publishableKey,
    client: ref.watch(storefrontHttpClientProvider),
  );
  return invoker.call;
});

final storefrontRepositoryProvider = Provider<StorefrontRepository>((ref) {
  return SupabaseStorefrontRepository(
    invoke: ref.watch(storefrontRpcInvokerProvider),
  );
});

final storefrontCacheDatabaseProvider = Provider<StorefrontCacheDatabase>((
  ref,
) {
  final database = StorefrontCacheDatabase.defaults();
  ref.onDispose(() => database.close());
  return database;
});

final storefrontCacheRepositoryProvider = Provider<StorefrontCacheRepository>(
  (ref) => DriftStorefrontCacheRepository(
    ref.watch(storefrontCacheDatabaseProvider),
  ),
);
