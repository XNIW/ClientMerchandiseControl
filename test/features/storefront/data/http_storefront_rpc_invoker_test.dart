import 'dart:convert';

import 'package:client_merchandise_control/features/storefront/data/http_storefront_rpc_invoker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const key = 'sb_publishable_test_key';
  final origin = Uri.parse('https://project.example.invalid');

  test('invia soltanto il contratto pubblico con la publishable key', () async {
    late http.Request request;
    final invoker = HttpStorefrontRpcInvoker(
      origin: origin,
      publishableKey: key,
      client: MockClient((candidate) async {
        request = candidate;
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }),
    );

    final result = await invoker.call('storefront_home_v1', {
      'p_shop_slug': 'storefront-test',
    });

    expect(result, {'status': 'ok'});
    expect(
      request.url,
      Uri.parse(
        'https://project.example.invalid/rest/v1/rpc/storefront_home_v1',
      ),
    );
    expect(request.method, 'POST');
    expect(request.headers['apikey'], key);
    expect(request.headers['authorization'], 'Bearer $key');
    expect(jsonDecode(request.body), {'p_shop_slug': 'storefront-test'});
    expect(request.body, isNot(contains('service_role')));
  });

  test('rifiuta funzioni non Storefront senza inviare richieste', () async {
    var requests = 0;
    final invoker = HttpStorefrontRpcInvoker(
      origin: origin,
      publishableKey: key,
      client: MockClient((_) async {
        requests += 1;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      invoker.call('internal_inventory_v1', const {}),
      throwsA(isA<FormatException>()),
    );
    expect(requests, 0);
  });

  test('riduce gli errori remoti a status e codice bounded', () async {
    final invoker = HttpStorefrontRpcInvoker(
      origin: origin,
      publishableKey: key,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'code': '42501', 'message': 'sensitive detail'}),
          403,
        ),
      ),
    );

    await expectLater(
      invoker.call('storefront_catalog_v1', const {}),
      throwsA(
        isA<StorefrontRpcResponseException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having((error) => error.code, 'code', '42501')
            .having(
              (error) => error.toString(),
              'sanitized error',
              isNot(contains('sensitive detail')),
            ),
      ),
    );
  });

  test('rifiuta JSON non valido e risposte oltre il limite', () async {
    final malformed = HttpStorefrontRpcInvoker(
      origin: origin,
      publishableKey: key,
      client: MockClient((_) async => http.Response('{', 200)),
    );
    await expectLater(
      malformed.call('storefront_home_v1', const {}),
      throwsA(isA<FormatException>()),
    );

    final oversized = HttpStorefrontRpcInvoker(
      origin: origin,
      publishableKey: key,
      client: MockClient(
        (_) async => http.Response('x' * (2 * 1024 * 1024 + 1), 200),
      ),
    );
    await expectLater(
      oversized.call('storefront_home_v1', const {}),
      throwsA(isA<FormatException>()),
    );
  });
}
