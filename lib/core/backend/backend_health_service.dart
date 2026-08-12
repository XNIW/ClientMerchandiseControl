import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum BackendHealthResult {
  healthy,
  offline,
  unauthorized,
  notFound,
  recoverableError,
  invalidResponse,
  cancelled,
}

final class BackendProbeCancellation {
  final Completer<void> _cancelled = Completer<void>();

  bool get isCancelled => _cancelled.isCompleted;

  Future<void> get whenCancelled => _cancelled.future;

  void cancel() {
    if (!isCancelled) {
      _cancelled.complete();
    }
  }
}

abstract interface class BackendHealthService {
  Future<BackendHealthResult> check({
    required Uri origin,
    required String publishableKey,
    required BackendProbeCancellation cancellation,
  });

  void close();
}

final class HttpBackendHealthService implements BackendHealthService {
  static const int _maxHealthBodyBytes = 8 * 1024;

  HttpBackendHealthService({
    http.Client? client,
    Duration timeout = const Duration(seconds: 5),
    this.closeClientOnDispose = true,
  }) : _timeout = _validateTimeout(timeout),
       _client = client ?? http.Client();

  final Duration _timeout;
  final http.Client _client;
  final bool closeClientOnDispose;
  final Set<_ProbeAbortSignal> _activeAborts = <_ProbeAbortSignal>{};

  bool _isClosed = false;

  @override
  Future<BackendHealthResult> check({
    required Uri origin,
    required String publishableKey,
    required BackendProbeCancellation cancellation,
  }) async {
    if (_isClosed || cancellation.isCancelled) {
      return BackendHealthResult.cancelled;
    }

    final abortSignal = _ProbeAbortSignal();
    _activeAborts.add(abortSignal);

    unawaited(
      cancellation.whenCancelled.then(
        (_) => abortSignal.abort(_ProbeAbortReason.cancelled),
      ),
    );
    final timeoutTimer = Timer(
      _timeout,
      () => abortSignal.abort(_ProbeAbortReason.timedOut),
    );

    final request =
        http.AbortableRequest(
            'GET',
            origin.resolve('/auth/v1/health'),
            abortTrigger: abortSignal.whenAborted,
          )
          ..followRedirects = false
          ..headers['apikey'] = publishableKey;

    try {
      final streamedResponse = await _client.send(request);
      final bodyBytes = await _readBodyWithinLimit(
        streamedResponse.stream,
        abortSignal,
      );
      if (bodyBytes == null) {
        return _mapAbort(abortSignal.reason);
      }
      if (abortSignal.reason case final reason?) {
        return _mapAbort(reason);
      }

      return _mapResponse(streamedResponse.statusCode, bodyBytes);
    } on http.RequestAbortedException {
      return _mapAbort(abortSignal.reason);
    } on TimeoutException {
      return _mapAbort(abortSignal.reason);
    } on http.ClientException {
      return _mapTransportFailure(abortSignal.reason);
    } on FormatException {
      return BackendHealthResult.invalidResponse;
    } on Object {
      return _mapUnexpectedFailure(abortSignal.reason);
    } finally {
      timeoutTimer.cancel();
      _activeAborts.remove(abortSignal);
    }
  }

  @override
  void close() {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    for (final abortSignal in _activeAborts.toList(growable: false)) {
      abortSignal.abort(_ProbeAbortReason.cancelled);
    }
    if (closeClientOnDispose) {
      _client.close();
    }
  }

  static Duration _validateTimeout(Duration timeout) {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    return timeout;
  }

  static Future<List<int>?> _readBodyWithinLimit(
    Stream<List<int>> body,
    _ProbeAbortSignal abortSignal,
  ) async {
    final bodyBytes = <int>[];

    await for (final chunk in body) {
      if (chunk.length > _maxHealthBodyBytes - bodyBytes.length) {
        abortSignal.abort(_ProbeAbortReason.responseTooLarge);
        return null;
      }
      bodyBytes.addAll(chunk);
    }

    return bodyBytes;
  }

  static BackendHealthResult _mapResponse(int statusCode, List<int> bodyBytes) {
    if (statusCode == 200) {
      final payload = jsonDecode(utf8.decode(bodyBytes));
      return _isValidHealthPayload(payload)
          ? BackendHealthResult.healthy
          : BackendHealthResult.invalidResponse;
    }

    if (statusCode == 401 || statusCode == 403) {
      return BackendHealthResult.unauthorized;
    }
    if (statusCode == 404) {
      return BackendHealthResult.notFound;
    }
    if (statusCode == 408 ||
        statusCode == 429 ||
        (statusCode >= 500 && statusCode <= 599)) {
      return BackendHealthResult.recoverableError;
    }

    return BackendHealthResult.invalidResponse;
  }

  static bool _isValidHealthPayload(Object? payload) {
    if (payload is! Map<String, dynamic>) {
      return false;
    }

    return payload['name'] == 'GoTrue' &&
        _isNonEmptyString(payload['version']) &&
        _isNonEmptyString(payload['description']);
  }

  static bool _isNonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty;

  static BackendHealthResult _mapAbort(_ProbeAbortReason? reason) =>
      switch (reason) {
        _ProbeAbortReason.cancelled => BackendHealthResult.cancelled,
        _ProbeAbortReason.responseTooLarge =>
          BackendHealthResult.invalidResponse,
        _ProbeAbortReason.timedOut || null => BackendHealthResult.offline,
      };

  static BackendHealthResult _mapTransportFailure(_ProbeAbortReason? reason) =>
      _mapAbort(reason);

  static BackendHealthResult _mapUnexpectedFailure(_ProbeAbortReason? reason) {
    return switch (reason) {
      _ProbeAbortReason.cancelled => BackendHealthResult.cancelled,
      _ProbeAbortReason.timedOut => BackendHealthResult.offline,
      _ProbeAbortReason.responseTooLarge => BackendHealthResult.invalidResponse,
      null => BackendHealthResult.recoverableError,
    };
  }
}

enum _ProbeAbortReason { cancelled, timedOut, responseTooLarge }

final class _ProbeAbortSignal {
  final Completer<void> _abort = Completer<void>();

  _ProbeAbortReason? reason;

  Future<void> get whenAborted => _abort.future;

  void abort(_ProbeAbortReason requestedReason) {
    if (_abort.isCompleted) {
      return;
    }

    reason = requestedReason;
    _abort.complete();
  }
}
