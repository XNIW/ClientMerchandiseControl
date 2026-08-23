import 'package:client_merchandise_control/features/reviews/data/supabase_customer_review_repository.dart';
import 'package:client_merchandise_control/features/reviews/domain/customer_review_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _publication = '50000000-0000-4000-8000-000000000001';
const _review = '91000000-0000-4000-8000-000000000001';

void main() {
  test(
    'aggregate pubblicato e recensione verificata arrivano solo dal server',
    () async {
      final port = _Port(_payload());
      final value = await SupabaseCustomerReviewRepository(
        port: port,
      ).listProduct(shopSlug: 'storefront-test', publicationId: _publication);

      expect(value.averageRating, 5);
      expect(value.publishedCount, 1);
      expect(value.items.single.verifiedPurchase, isTrue);
      expect(port.parameters, isNot(contains('ownerUserId')));
    },
  );

  test('recensione pubblica non verificata fallisce chiusa', () async {
    final payload = _payload();
    final items = payload['items']! as List<Object?>;
    payload['items'] = [
      {...items.single! as Map<String, Object?>, 'verifiedPurchase': false},
    ];
    await expectLater(
      SupabaseCustomerReviewRepository(
        port: _Port(payload),
      ).listProduct(shopSlug: 'storefront-test', publicationId: _publication),
      throwsA(isA<CustomerReviewException>()),
    );
  });
}

Map<String, Object?> _payload() => {
  'apiVersion': 'storefront-reviews.v1',
  'status': 'ok',
  'averageRating': 5,
  'publishedCount': 1,
  'distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 1},
  'items': [
    {
      'id': _review,
      'rating': 5,
      'comment': 'Ottimo',
      'createdAt': '2026-08-23T12:00:00Z',
      'verifiedPurchase': true,
    },
  ],
  'serverTime': '2026-08-23T12:00:00Z',
};

final class _Port implements CustomerReviewPort {
  _Port(this.response);

  final Object? response;
  Map<String, Object?>? parameters;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    this.parameters = parameters;
    return response;
  }
}
