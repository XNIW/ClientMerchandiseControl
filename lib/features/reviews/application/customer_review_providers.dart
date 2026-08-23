import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../account/application/customer_account_providers.dart';
import '../data/supabase_customer_review_repository.dart';
import '../domain/customer_review_models.dart';
import '../domain/customer_review_repository.dart';

final customerReviewRepositoryProvider = Provider<CustomerReviewRepository>((
  ref,
) {
  return SupabaseCustomerReviewRepository(
    port: PlatformCustomerReviewPort(Supabase.instance.client),
  );
});

final customerReviewsAccountProvider = FutureProvider<CustomerReviewsAccount>((
  ref,
) async {
  final identity = ref.watch(customerAccountIdentityProvider);
  final shopSlug = ref.watch(appConfigProvider).storefrontShopSlug;
  if (identity == null || shopSlug == null) {
    return CustomerReviewsAccount(items: const [], eligible: const []);
  }
  return ref
      .read(customerReviewRepositoryProvider)
      .listMine(shopSlug: shopSlug);
});

final storefrontProductReviewsProvider = FutureProvider.autoDispose
    .family<StorefrontProductReviews, String>((ref, publicationId) async {
      final shopSlug = ref.watch(appConfigProvider).storefrontShopSlug;
      if (shopSlug == null) throw const CustomerReviewException('unavailable');
      return ref
          .read(customerReviewRepositoryProvider)
          .listProduct(shopSlug: shopSlug, publicationId: publicationId);
    });
