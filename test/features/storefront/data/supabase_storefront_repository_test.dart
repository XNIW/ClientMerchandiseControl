import 'dart:async';

import 'package:client_merchandise_control/features/storefront/data/supabase_storefront_repository.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
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
}
