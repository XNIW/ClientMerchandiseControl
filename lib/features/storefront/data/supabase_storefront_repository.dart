import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/storefront_failure.dart';
import '../domain/storefront_models.dart';
import '../domain/storefront_repository.dart';
import 'storefront_home_dto.dart';

typedef StorefrontRpcInvoker =
    Future<Object?> Function(String function, Map<String, Object?> parameters);

class SupabaseStorefrontRepository implements StorefrontRepository {
  const SupabaseStorefrontRepository({
    required this.invoke,
    this.requestTimeout = const Duration(seconds: 5),
  });

  final StorefrontRpcInvoker invoke;
  final Duration requestTimeout;

  @override
  Future<StorefrontHomeData> fetchHome({
    required String shopSlug,
    required StorefrontRequestCancellation cancellation,
  }) async {
    cancellation.throwIfCancelled();
    try {
      final payload = await invoke('storefront_home_v1', {
        'p_shop_slug': shopSlug,
        'p_category_limit': 12,
        'p_featured_limit': 8,
        'p_offer_limit': 8,
      }).timeout(requestTimeout);
      cancellation.throwIfCancelled();
      return StorefrontHomeDto.decode(payload);
    } on StorefrontFailure {
      rethrow;
    } on TimeoutException {
      throw const StorefrontFailure(
        StorefrontFailureKind.timeout,
        code: 'request_timeout',
      );
    } on SocketException {
      throw const StorefrontFailure(
        StorefrontFailureKind.offline,
        code: 'network_offline',
      );
    } on http.ClientException {
      throw const StorefrontFailure(
        StorefrontFailureKind.offline,
        code: 'network_unreachable',
      );
    } on AuthException {
      throw const StorefrontFailure(
        StorefrontFailureKind.unauthorized,
        code: 'public_contract_unauthorized',
      );
    } on PostgrestException catch (error) {
      final kind = error.code == '42501'
          ? StorefrontFailureKind.unauthorized
          : StorefrontFailureKind.unavailable;
      throw StorefrontFailure(kind, code: 'public_contract_unavailable');
    } on Object {
      throw const StorefrontFailure(
        StorefrontFailureKind.unknown,
        code: 'storefront_unknown',
      );
    }
  }
}
