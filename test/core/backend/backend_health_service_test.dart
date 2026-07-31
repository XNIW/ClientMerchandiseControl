import 'dart:async';
import 'dart:convert';

import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  const publishableKey = 'sb_publishable_test_key';
  final origin = Uri.parse(
    'https://project.example.invalid/base?ignored=true#fragment',
  );

  test('invia soltanto il GET health data-free e non segue redirect', () async {
    late http.BaseRequest capturedRequest;
    final client = _HandlerClient((request) async {
      capturedRequest = request;
      return _jsonResponse(200, _validHealthPayload);
    });
    final service = HttpBackendHealthService(client: client);
    addTearDown(service.close);

    final result = await service.check(
      origin: origin,
      publishableKey: publishableKey,
      cancellation: BackendProbeCancellation(),
    );

    expect(result, BackendHealthResult.healthy);
    expect(capturedRequest, isA<http.AbortableRequest>());
    expect(capturedRequest.method, 'GET');
    expect(
      capturedRequest.url,
      Uri.parse('https://project.example.invalid/auth/v1/health'),
    );
    expect(capturedRequest.followRedirects, isFalse);
    expect(capturedRequest.headers, <String, String>{'apikey': publishableKey});
    expect((capturedRequest as http.Request).bodyBytes, isEmpty);
  });

  test(
    'accetta solo un payload health completo con stringhe non vuote',
    () async {
      for (final payload in <Object?>[
        null,
        <Object?>[],
        <String, Object?>{},
        <String, Object?>{
          'name': 'GoTrue',
          'version': ' ',
          'description': 'Auth API',
        },
        <String, Object?>{
          'name': 'GoTrue',
          'version': 2,
          'description': 'Auth API',
        },
      ]) {
        final service = HttpBackendHealthService(
          client: _HandlerClient(
            (_) async => _textResponse(200, jsonEncode(payload)),
          ),
        );

        expect(
          await service.check(
            origin: origin,
            publishableKey: publishableKey,
            cancellation: BackendProbeCancellation(),
          ),
          BackendHealthResult.invalidResponse,
        );
        service.close();
      }

      final malformedService = HttpBackendHealthService(
        client: _HandlerClient(
          (_) async => _textResponse(200, '{"name": invalid'),
        ),
      );
      addTearDown(malformedService.close);

      expect(
        await malformedService.check(
          origin: origin,
          publishableKey: publishableKey,
          cancellation: BackendProbeCancellation(),
        ),
        BackendHealthResult.invalidResponse,
      );
    },
  );

  test(
    'mappa gli status HTTP senza interpretare auth health come login',
    () async {
      const cases = <int, BackendHealthResult>{
        401: BackendHealthResult.unauthorized,
        403: BackendHealthResult.unauthorized,
        404: BackendHealthResult.notFound,
        408: BackendHealthResult.recoverableError,
        429: BackendHealthResult.recoverableError,
        500: BackendHealthResult.recoverableError,
        503: BackendHealthResult.recoverableError,
        201: BackendHealthResult.invalidResponse,
        302: BackendHealthResult.invalidResponse,
        400: BackendHealthResult.invalidResponse,
      };

      for (final entry in cases.entries) {
        final service = HttpBackendHealthService(
          client: _HandlerClient(
            (_) async => _textResponse(entry.key, 'not inspected'),
          ),
        );

        expect(
          await service.check(
            origin: origin,
            publishableKey: publishableKey,
            cancellation: BackendProbeCancellation(),
          ),
          entry.value,
          reason: 'status ${entry.key}',
        );
        service.close();
      }
    },
  );

  test('mappa ClientException e TimeoutException su offline', () async {
    for (final error in <Object>[
      http.ClientException('transport detail'),
      TimeoutException('timeout detail'),
    ]) {
      final service = HttpBackendHealthService(
        client: _HandlerClient((_) async => throw error),
      );

      expect(
        await service.check(
          origin: origin,
          publishableKey: publishableKey,
          cancellation: BackendProbeCancellation(),
        ),
        BackendHealthResult.offline,
      );
      service.close();
    }
  });

  test('il timeout completa abortTrigger e restituisce offline', () async {
    final client = _AbortAwareClient();
    final service = HttpBackendHealthService(
      client: client,
      timeout: const Duration(milliseconds: 20),
    );
    addTearDown(service.close);

    final result = await service.check(
      origin: origin,
      publishableKey: publishableKey,
      cancellation: BackendProbeCancellation(),
    );

    expect(result, BackendHealthResult.offline);
    expect(client.abortObserved, isTrue);
    expect(client.sendCalls, 1);
  });

  test(
    'la cancellazione manuale abortisce la request ed è idempotente',
    () async {
      final client = _AbortAwareClient();
      final service = HttpBackendHealthService(
        client: client,
        timeout: const Duration(seconds: 1),
      );
      final cancellation = BackendProbeCancellation();
      addTearDown(service.close);

      final resultFuture = service.check(
        origin: origin,
        publishableKey: publishableKey,
        cancellation: cancellation,
      );
      await client.requestStarted.future;
      cancellation
        ..cancel()
        ..cancel();

      expect(await resultFuture, BackendHealthResult.cancelled);
      expect(cancellation.isCancelled, isTrue);
      expect(client.abortObserved, isTrue);
      expect(client.sendCalls, 1);
    },
  );

  test('una cancellazione già attiva evita di inviare la request', () async {
    final client = _HandlerClient(
      (_) async => _jsonResponse(200, _validHealthPayload),
    );
    final service = HttpBackendHealthService(client: client);
    final cancellation = BackendProbeCancellation()..cancel();
    addTearDown(service.close);

    expect(
      await service.check(
        origin: origin,
        publishableKey: publishableKey,
        cancellation: cancellation,
      ),
      BackendHealthResult.cancelled,
    );
    expect(client.sendCalls, 0);
  });

  test(
    'close abortisce i check attivi e chiude il client una sola volta',
    () async {
      final client = _AbortAwareClient();
      final service = HttpBackendHealthService(
        client: client,
        timeout: const Duration(seconds: 1),
      );

      final resultFuture = service.check(
        origin: origin,
        publishableKey: publishableKey,
        cancellation: BackendProbeCancellation(),
      );
      await client.requestStarted.future;
      service
        ..close()
        ..close();

      expect(await resultFuture, BackendHealthResult.cancelled);
      expect(client.abortObserved, isTrue);
      expect(client.closeCalls, 1);
      expect(
        await service.check(
          origin: origin,
          publishableKey: publishableKey,
          cancellation: BackendProbeCancellation(),
        ),
        BackendHealthResult.cancelled,
      );
    },
  );
}

const _validHealthPayload = <String, String>{
  'name': 'GoTrue',
  'version': 'v2.60.7',
  'description': 'Authentication API',
};

http.StreamedResponse _jsonResponse(int statusCode, Object? payload) =>
    _textResponse(statusCode, jsonEncode(payload));

http.StreamedResponse _textResponse(int statusCode, String body) =>
    http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      statusCode,
    );

final class _HandlerClient extends http.BaseClient {
  _HandlerClient(this._handler);

  final Future<http.StreamedResponse> Function(http.BaseRequest request)
  _handler;

  int sendCalls = 0;
  int closeCalls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sendCalls += 1;
    return _handler(request);
  }

  @override
  void close() {
    closeCalls += 1;
  }
}

final class _AbortAwareClient extends http.BaseClient {
  final Completer<void> requestStarted = Completer<void>();

  int sendCalls = 0;
  int closeCalls = 0;
  bool abortObserved = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sendCalls += 1;
    if (!requestStarted.isCompleted) {
      requestStarted.complete();
    }

    final abortableRequest = request as http.AbortableRequest;
    await abortableRequest.abortTrigger;
    abortObserved = true;
    throw http.RequestAbortedException(request.url);
  }

  @override
  void close() {
    closeCalls += 1;
  }
}
