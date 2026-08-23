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

  test(
    'paginazione usa cursor composto e non tronca dopo la prima pagina',
    () async {
      final secondReview = '91000000-0000-4000-8000-000000000002';
      final firstPayload = _payload(publishedCount: 2, distributionCount: 2);
      final secondPayload = _payload(
        reviewId: secondReview,
        createdAt: '2026-08-22T12:00:00Z',
        publishedCount: 2,
        distributionCount: 2,
      );
      final port = _SequencePort([firstPayload, secondPayload]);
      final repository = SupabaseCustomerReviewRepository(port: port);

      final first = await repository.listProduct(
        shopSlug: 'storefront-test',
        publicationId: _publication,
        pageSize: 1,
      );
      final second = await repository.listProduct(
        shopSlug: 'storefront-test',
        publicationId: _publication,
        cursor: first.nextCursor,
        pageSize: 1,
      );

      expect(first.nextCursor?.beforeId, _review);
      expect(second.items.single.id, secondReview);
      expect(
        port.parameters[1]['p_before_created_at'],
        '2026-08-23T12:00:00.000Z',
      );
      expect(port.parameters[1]['p_before_id'], _review);
      expect(port.parameters[1]['p_page_size'], 1);
    },
  );
}

Map<String, Object?> _payload({
  String reviewId = _review,
  String createdAt = '2026-08-23T12:00:00Z',
  int publishedCount = 1,
  int distributionCount = 1,
}) => {
  'apiVersion': 'storefront-reviews.v1',
  'status': 'ok',
  'averageRating': 5,
  'publishedCount': publishedCount,
  'distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': distributionCount},
  'items': [
    {
      'id': reviewId,
      'rating': 5,
      'comment': 'Ottimo',
      'createdAt': createdAt,
      'verifiedPurchase': true,
    },
  ],
  'serverTime': '2026-08-23T12:00:00Z',
};

final class _SequencePort implements CustomerReviewPort {
  _SequencePort(this.responses);

  final List<Object?> responses;
  final List<Map<String, Object?>> parameters = [];

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    this.parameters.add(parameters);
    return responses[this.parameters.length - 1];
  }
}

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
