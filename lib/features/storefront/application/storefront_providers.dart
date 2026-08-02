import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_storefront_repository.dart';
import '../domain/storefront_repository.dart';

final storefrontRpcInvokerProvider = Provider<StorefrontRpcInvoker>((ref) {
  return (function, parameters) async {
    return Supabase.instance.client.rpc(function, params: parameters);
  };
});

final storefrontRepositoryProvider = Provider<StorefrontRepository>((ref) {
  return SupabaseStorefrontRepository(
    invoke: ref.watch(storefrontRpcInvokerProvider),
  );
});
