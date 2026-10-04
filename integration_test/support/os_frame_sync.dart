import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

const osFrameRequestEvent = 'cmc.task054.osFrameRequest';
const osFrameAckExtension = 'ext.cmc.task054.osFrameAck';
const osFramePendingExtension = 'ext.cmc.task054.osFramePending';
const osFrameClaimExtension = 'ext.cmc.task054.osFrameClaim';

bool validOsFrameMarker(String name) =>
    name.length <= 100 &&
    RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9-]*$').hasMatch(name) &&
    RegExp(r'(^|-)focus(-|$)').hasMatch(name);

/// Bridge solo test: il focus resta montato finché il driver non risponde.
class OsFrameSync {
  OsFrameSync({
    // Include il timeout del capture host e il cleanup prima dell'ACK.
    this.timeout = const Duration(seconds: 60),
    this.readinessTimeout = const Duration(seconds: 20),
    void Function(String, Map<String, Object?>)? post,
    void Function(String, developer.ServiceExtensionHandler)? register,
  }) : _post = post ?? developer.postEvent,
       _register = register ?? developer.registerExtension;

  final Duration timeout;
  final Duration readinessTimeout;
  final void Function(String, Map<String, Object?>) _post;
  final void Function(String, developer.ServiceExtensionHandler) _register;
  var _registered = false;
  var _sequence = 0;
  String? _name;
  String? _requestId;
  Completer<void>? _pending;
  Completer<void>? _ready;

  Future<void> capture(String name) async {
    if (!validOsFrameMarker(name)) {
      throw ArgumentError.value(name, 'name', 'marker OS focus non valido');
    }
    if (_pending != null) throw StateError('Richiesta OS già in corso');
    if (!_registered) {
      _register(osFrameAckExtension, acknowledge);
      _register(osFramePendingExtension, pendingRequest);
      _register(osFrameClaimExtension, claim);
      _registered = true;
    }
    final pending = Completer<void>();
    _pending = pending;
    final ready = Completer<void>();
    _ready = ready;
    _name = name;
    _requestId = '${++_sequence}';
    try {
      _post(osFrameRequestEvent, <String, Object?>{
        'name': name,
        'request_id': _requestId,
      });
      await ready.future.timeout(readinessTimeout);
      await pending.future.timeout(timeout);
    } finally {
      _pending = null;
      _name = null;
      _requestId = null;
      _ready = null;
    }
  }

  Future<developer.ServiceExtensionResponse> acknowledge(
    String method,
    Map<String, String> parameters,
  ) async {
    final accepted =
        method == osFrameAckExtension &&
        _pending != null &&
        _ready?.isCompleted == true &&
        !_pending!.isCompleted &&
        parameters['name'] == _name &&
        parameters['request_id'] == _requestId &&
        (parameters['result'] == 'true' || parameters['result'] == 'false');
    if (accepted) {
      if (parameters['result'] == 'true') {
        _pending!.complete();
      } else {
        _pending!.completeError(StateError('FAIL: cattura OS non completata'));
      }
    }
    return developer.ServiceExtensionResponse.result(
      jsonEncode(<String, Object?>{'accepted': accepted}),
    );
  }

  Future<developer.ServiceExtensionResponse> claim(
    String method,
    Map<String, String> parameters,
  ) async {
    final accepted =
        method == osFrameClaimExtension &&
        _pending != null &&
        _ready != null &&
        !_ready!.isCompleted &&
        parameters['name'] == _name &&
        parameters['request_id'] == _requestId;
    if (accepted) _ready!.complete();
    return developer.ServiceExtensionResponse.result(
      jsonEncode(<String, Object?>{'accepted': accepted}),
    );
  }

  Future<developer.ServiceExtensionResponse> pendingRequest(
    String method,
    Map<String, String> parameters,
  ) async => developer.ServiceExtensionResponse.result(
    jsonEncode(<String, Object?>{
      'pending': method == osFramePendingExtension && _pending != null
          ? <String, Object?>{'name': _name, 'request_id': _requestId}
          : null,
    }),
  );
}

/// L'host risponde anche alle richieste non valide senza avviare alcun tool OS.
class OsFrameHost {
  OsFrameHost({
    required this.claim,
    required this.capture,
    required this.acknowledge,
  });

  final Future<bool> Function(Map<String, String>) claim;
  final Future<bool> Function(String) capture;
  final Future<void> Function(Map<String, String>) acknowledge;
  var _busy = false;
  final _handled = <String>{};

  Future<void> handle(Map<dynamic, dynamic>? request) async {
    final name = request?['name'];
    final requestId = request?['request_id'];
    var success = false;
    if (name is String &&
        validOsFrameMarker(name) &&
        requestId is String &&
        RegExp(r'^[0-9]+$').hasMatch(requestId)) {
      final key = '$name/$requestId';
      // Evento live e lettura pending possono rappresentare la stessa richiesta.
      if (!_handled.add(key)) return;
      if (_busy) {
        await acknowledge(<String, String>{
          'name': name,
          'request_id': requestId,
          'result': 'false',
        });
        return;
      }
      _busy = true;
      try {
        if (!await claim(<String, String>{
          'name': name,
          'request_id': requestId,
        })) {
          return;
        }
        success = await capture(name);
      } on Object {
        success = false;
      } finally {
        _busy = false;
      }
    }
    await acknowledge(<String, String>{
      'name': name is String ? name : '',
      'request_id': requestId is String ? requestId : '',
      'result': '$success',
    });
  }
}
