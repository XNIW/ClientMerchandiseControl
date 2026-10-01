import 'dart:async';
import 'dart:convert';

import 'package:client_merchandise_control/features/delivery_context/data/photon_address_provider.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_address_ports.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final config = AddressProviderConfiguration.fromValues(
    enabled: 'true',
    approved: 'true',
    endpoint: 'https://geo.example.org',
  );
  final feature = {
    'type': 'Feature',
    'properties': {
      'street': 'Via Test',
      'housenumber': '2',
      'city': 'Comune Test',
      'state': 'Regione Test',
      'countrycode': 'CL',
    },
    'geometry': {
      'type': 'Point',
      'coordinates': [-70.0, -33.0],
    },
  };
  String body([Object? item]) => jsonEncode({
    'features': [item ?? feature],
  });
  test(
    'OFF, approvazione mancante, origine non canonica e production non inviano richieste',
    () async {
      for (final c in [
        AddressProviderConfiguration.fromValues(),
        AddressProviderConfiguration.fromValues(
          enabled: 'true',
          endpoint: 'https://geo.example.org',
        ),
        AddressProviderConfiguration.fromValues(
          enabled: 'true',
          approved: 'true',
          endpoint: 'http://geo.example.org',
        ),
        AddressProviderConfiguration.fromValues(
          enabled: 'true',
          approved: 'true',
          endpoint: 'https://geo.example.org',
          environment: 'production',
        ),
      ]) {
        final provider = PhotonAddressProvider(
          configuration: c,
          client: MockClient(
            (_) async => throw TestFailure('request forbidden'),
          ),
        );
        expect(provider.configured, isFalse);
        await expectLater(
          provider.search('via test'),
          throwsA(isA<AddressProviderNotConfiguredException>()),
        );
        provider.dispose();
      }
    },
  );
  test(
    'ricerca, risoluzione e reverse usano GeoJSON bounded senza identità',
    () async {
      final requests = <http.Request>[];
      final provider = PhotonAddressProvider(
        configuration: config,
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(body(), 200);
        }),
      );
      addTearDown(provider.dispose);
      final suggestions = await provider.search('  Via   Test ');
      final resolved = await provider.resolve(suggestions.single);
      expect(resolved?.addressLine1, 'Via Test 2');
      expect(resolved?.coordinate.latitude, -33);
      expect(requests.single.url.queryParameters, {
        'q': 'Via Test',
        'limit': '8',
      });
      expect(requests.single.headers.containsKey('authorization'), isFalse);
      final reverse = await provider.reverse(
        const DeliveryCoordinate(latitude: -33.1234567, longitude: -70),
      );
      expect(reverse?.countryCode, 'CL');
      expect(reverse?.coordinate.latitude, -33.1234567);
      expect(requests.last.url.path, '/reverse');
      expect(requests.last.url.queryParameters['lat'], '-33.12346');
    },
  );
  test(
    'risposta obsoleta non sostituisce la pagina risolvibile e dispose la elimina',
    () async {
      final first = Completer<http.Response>();
      int calls = 0;
      final provider = PhotonAddressProvider(
        configuration: config,
        client: MockClient(
          (_) async => ++calls == 1 ? first.future : http.Response(body(), 200),
        ),
      );
      final old = provider.search('vecchia');
      final current = await provider.search('nuova');
      first.complete(http.Response(body(), 200));
      expect(await old, isEmpty);
      expect(await provider.resolve(current.single), isNotNull);
      provider.dispose();
      await expectLater(
        provider.resolve(current.single),
        throwsA(isA<AddressProviderNotConfiguredException>()),
      );
    },
  );
  test(
    '429 rispetta cooldown, niente retry automatici; errori non espongono URL',
    () async {
      int calls = 0;
      var now = DateTime.utc(2026);
      final provider = PhotonAddressProvider(
        configuration: config,
        clock: () => now,
        client: MockClient((_) async {
          calls++;
          return http.Response(
            'private provider body',
            429,
            headers: {'retry-after': '5'},
          );
        }),
      );
      addTearDown(provider.dispose);
      for (var i = 0; i < 2; i++) {
        await expectLater(
          provider.search('via test'),
          throwsA(isA<AddressProviderUnavailableException>()),
        );
      }
      expect(calls, 1);
      now = now.add(const Duration(seconds: 6));
      await expectLater(
        provider.search('via test'),
        throwsA(isA<AddressProviderUnavailableException>()),
      );
      expect(calls, 2);
    },
  );
  test(
    'timeout, redirect, payload enorme e schema invalido falliscono bounded',
    () async {
      for (final outcome in [
        http.Response('', 302),
        http.Response('x' * 65537, 200),
        http.Response('{}', 200),
        http.Response('not json', 200),
      ]) {
        final provider = PhotonAddressProvider(
          configuration: config,
          client: MockClient((_) async => outcome),
        );
        await expectLater(
          provider.search('via test'),
          throwsA(isA<AddressProviderUnavailableException>()),
        );
        provider.dispose();
      }
      final provider = PhotonAddressProvider(
        configuration: config,
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) => Completer<http.Response>().future),
      );
      await expectLater(
        provider.search('via test'),
        throwsA(isA<AddressProviderUnavailableException>()),
      );
      provider.dispose();
    },
  );
  test('coordinate e record non validi non diventano indirizzi', () async {
    final provider = PhotonAddressProvider(
      configuration: config,
      client: MockClient(
        (_) async => http.Response(
          body({
            'geometry': {
              'type': 'Point',
              'coordinates': [190, 10],
            },
            'properties': {'street': 'via', 'countrycode': 'CL'},
          }),
          200,
        ),
      ),
    );
    addTearDown(provider.dispose);
    expect(await provider.search('via test'), isEmpty);
    expect(
      await provider.reverse(
        const DeliveryCoordinate(latitude: double.nan, longitude: 0),
      ),
      isNull,
    );
  });
}
