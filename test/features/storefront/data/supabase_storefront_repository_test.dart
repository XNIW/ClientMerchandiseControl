import 'dart:async';

import 'package:client_merchandise_control/features/storefront/data/supabase_storefront_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../storefront_test_fixture.dart';

void main() {
  test('invoca soltanto storefront_home_v1 con parametri bounded', () async {
    String? function;
    Map<String, Object?>? parameters;
    final repository = SupabaseStorefrontRepository(
      invoke: (name, values) async {
        function = name;
        parameters = values;
        return validStorefrontHomePayload();
      },
    );

    final result = await repository.fetchHome(
      shopSlug: 'storefront-test',
      cancellation: StorefrontRequestCancellation(),
    );

    expect(result.featured, hasLength(1));
    expect(function, 'storefront_home_v1');
    expect(parameters, {
      'p_shop_slug': 'storefront-test',
      'p_category_limit': 12,
      'p_featured_limit': 8,
      'p_offer_limit': 8,
    });
  });

  test('mappa timeout e rete senza propagare dettagli', () async {
    final timeoutRepository = SupabaseStorefrontRepository(
      requestTimeout: const Duration(milliseconds: 1),
      invoke: (name, values) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return validStorefrontHomePayload();
      },
    );
    await expectLater(
      timeoutRepository.fetchHome(
        shopSlug: 'storefront-test',
        cancellation: StorefrontRequestCancellation(),
      ),
      throwsA(
        isA<StorefrontFailure>().having(
          (failure) => failure.kind,
          'kind',
          StorefrontFailureKind.timeout,
        ),
      ),
    );

    final offlineRepository = SupabaseStorefrontRepository(
      invoke: (name, values) =>
          throw http.ClientException('sensitive transport detail'),
    );
    await expectLater(
      offlineRepository.fetchHome(
        shopSlug: 'storefront-test',
        cancellation: StorefrontRequestCancellation(),
      ),
      throwsA(
        isA<StorefrontFailure>()
            .having(
              (failure) => failure.kind,
              'kind',
              StorefrontFailureKind.offline,
            )
            .having(
              (failure) => failure.toString(),
              'sanitized',
              isNot(contains('sensitive')),
            ),
      ),
    );
  });

  test('scarta una risposta completata dopo cancellazione', () async {
    final response = Completer<Object?>();
    final repository = SupabaseStorefrontRepository(
      invoke: (name, values) => response.future,
    );
    final cancellation = StorefrontRequestCancellation();
    final operation = repository.fetchHome(
      shopSlug: 'storefront-test',
      cancellation: cancellation,
    );

    cancellation.cancel();
    response.complete(validStorefrontHomePayload());

    await expectLater(
      operation,
      throwsA(
        isA<StorefrontFailure>().having(
          (failure) => failure.kind,
          'kind',
          StorefrontFailureKind.cancelled,
        ),
      ),
    );
  });

  test(
    'invoca categorie e catalogo con cursor keyset e filtri bounded',
    () async {
      final calls = <(String, Map<String, Object?>)>[];
      final repository = SupabaseStorefrontRepository(
        invoke: (name, values) async {
          calls.add((name, values));
          return name == 'storefront_categories_v1'
              ? validStorefrontCategoriesPayload()
              : validStorefrontCatalogPayload();
        },
      );
      final cancellation = StorefrontRequestCancellation();

      await repository.fetchCategories(
        shopSlug: 'storefront-test',
        cursor: null,
        limit: 100,
        cancellation: cancellation,
      );
      await repository.fetchCatalog(
        shopSlug: 'storefront-test',
        cursor: validStorefrontCursor,
        limit: 24,
        categorySlug: 'te',
        sort: StorefrontCatalogSort.catalog,
        cancellation: cancellation,
      );

      expect(calls.first.$1, 'storefront_categories_v1');
      expect(calls.first.$2, {
        'p_shop_slug': 'storefront-test',
        'p_cursor': null,
        'p_limit': 100,
      });
      expect(calls.last.$1, 'storefront_catalog_v1');
      expect(calls.last.$2, {
        'p_shop_slug': 'storefront-test',
        'p_cursor': validStorefrontCursor,
        'p_limit': 24,
        'p_category_slug': 'te',
        'p_availability': null,
        'p_discounted': null,
        'p_featured': null,
        'p_sort': 'catalog',
      });
    },
  );

  test('rifiuta limit e category slug invalidi prima della rete', () async {
    var calls = 0;
    final repository = SupabaseStorefrontRepository(
      invoke: (name, values) async {
        calls += 1;
        return validStorefrontCatalogPayload();
      },
    );

    for (final operation in <Future<Object?> Function()>[
      () => repository.fetchCategories(
        shopSlug: 'storefront-test',
        cursor: null,
        limit: 101,
        cancellation: StorefrontRequestCancellation(),
      ),
      () => repository.fetchCatalog(
        shopSlug: 'storefront-test',
        cursor: null,
        limit: 24,
        categorySlug: '../internal',
        sort: StorefrontCatalogSort.catalog,
        cancellation: StorefrontRequestCancellation(),
      ),
    ]) {
      await expectLater(operation, throwsA(isA<StorefrontFailure>()));
    }
    expect(calls, 0);
  });
}
