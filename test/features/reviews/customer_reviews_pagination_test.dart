import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/reviews/application/customer_review_providers.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_models.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_repository.dart';
import 'package:client_merchandise_control/features/reviews/presentation/customer_reviews.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _publication = '50000000-0000-4000-8000-000000000001';

void main() {
  testWidgets('carica pagine successive senza perdere recensioni esistenti', (
    tester,
  ) async {
    final repository = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.fromValues(
              appEnvironment: 'staging',
              supabaseUrl: 'https://staging.example.invalid',
              supabasePublishableKey: 'sb_publishable_staging',
              authRedirectUri: AppConfig.allowedAuthRedirectUri,
              googleAuthEnabled: 'false',
              storefrontShopSlug: 'storefront-test',
            ),
          ),
          customerReviewRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StorefrontProductReviewsSection(
                publicationId: _publication,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Prima pagina'), findsOneWidget);
    expect(find.text('Seconda pagina'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('product-reviews-load-more')));
    await tester.pumpAndSettle();

    expect(find.text('Prima pagina'), findsOneWidget);
    expect(find.text('Seconda pagina'), findsOneWidget);
    expect(repository.cursors, [null, 'review-1']);
  });
}

final class _Repository implements CustomerReviewRepository {
  final List<String?> cursors = [];

  @override
  Future<StorefrontProductReviews> listProduct({
    required String shopSlug,
    required String publicationId,
    StorefrontReviewCursor? cursor,
    int pageSize = 20,
  }) async {
    cursors.add(cursor?.beforeId);
    final isFirstPage = cursor == null;
    return StorefrontProductReviews(
      averageRating: 4.5,
      publishedCount: 2,
      distribution: const {1: 0, 2: 0, 3: 0, 4: 1, 5: 1},
      items: [
        StorefrontProductReview(
          id: isFirstPage ? 'review-1' : 'review-2',
          rating: isFirstPage ? 5 : 4,
          comment: isFirstPage ? 'Prima pagina' : 'Seconda pagina',
          createdAt: DateTime.utc(2026, 8, isFirstPage ? 23 : 22),
          verifiedPurchase: true,
        ),
      ],
      nextCursor: isFirstPage
          ? StorefrontReviewCursor(
              beforeCreatedAt: DateTime.utc(2026, 8, 23),
              beforeId: 'review-1',
            )
          : null,
      serverTime: DateTime.utc(2026, 8, 23),
    );
  }

  @override
  Future<CustomerReviewsAccount> listMine({required String shopSlug}) =>
      throw UnimplementedError();

  @override
  Future<CustomerReviewMutation> submit({
    required String orderItemId,
    required int rating,
    required String? comment,
  }) => throw UnimplementedError();

  @override
  Future<CustomerReviewMutation> update({
    required String reviewId,
    required int expectedVersion,
    required int rating,
    required String? comment,
    required bool withdraw,
  }) => throw UnimplementedError();
}
