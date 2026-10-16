import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

// Connessione diagnostica one-shot: nessun resume, retry o selezione isolate.
// Non registra URL VM, token, nomi isolate, stack, RPC payload o dati applicativi.
class AndroidStartupObserver {
  AndroidStartupObserver(this.output, this.expectedApkSha256, this.uri, {
    Future<WebSocket> Function(Uri, HttpClient)? connectSocket,
  }) : _connectSocket = connectSocket ?? _openSocket;

  static Future<WebSocket> _openSocket(Uri uri, HttpClient client) =>
      WebSocket.connect(uri.toString(), customClient: client);

  final File output;
  final String expectedApkSha256;
  final Uri uri;
  final Future<WebSocket> Function(Uri, HttpClient) _connectSocket;
  final _clock = Stopwatch()..start();
  final _client = HttpClient();
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  WebSocket? _socket;
  Future<void>? _connectionTask;
  bool cleanupFailed = false;
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;
  bool _writable = false;
  int _sequence = 0;
  int _count = 0;
  int _omitted = 0;

  static String? isolateId(Object? value) =>
      value is String && RegExp(r'^isolates/[0-9]{1,32}$').hasMatch(value)
      ? value
      : null;

  void _record(String kind, [Map<String, Object?> fields = const {}]) {
    if (!_writable) return;
    if (_count >= 128 && kind != 'observer-stop') {
      _omitted++;
      return;
    }
    _count++;
    try {
      output.writeAsStringSync(
      '${jsonEncode({
        'kind': kind,
        'host_epoch_us': DateTime.now().toUtc().microsecondsSinceEpoch,
        'observer_elapsed_us': _clock.elapsedMicroseconds,
        ...fields,
      })}\n',
        mode: FileMode.append,
      );
    } on FileSystemException {
      _writable = false;
      stderr.writeln('FAIL: observer write FileSystemException');
    }
  }

  Future<Map<String, dynamic>> _call(String method, Map<String, Object> args) {
    final id = ++_sequence;
    final reply = Completer<Map<String, dynamic>>();
    _pending[id] = reply;
    try {
      _socket!.add(jsonEncode({'jsonrpc': '2.0', 'id': id, 'method': method, 'params': args}));
    } on Object {
      // add può lanciare prima che il caller riceva il Future: il cleanup non
      // deve completeError su una reply che nessuno ha potuto ascoltare.
      _pending.remove(id);
      rethrow;
    }
    return reply.future;
  }

  void _message(dynamic raw) {
    if (_closed) return;
    try {
      if (raw is! String || raw.length > 65536) {
        throw const FormatException('observer message bound');
      }
      final message = jsonDecode(raw) as Map<String, dynamic>;
      final id = message['id'];
      if (id is int && _pending.containsKey(id)) {
        final reply = _pending.remove(id)!;
        final result = message['result'];
        if (message.containsKey('error') || result is! Map<String, dynamic>) {
          reply.completeError(StateError('observer RPC rejected'));
        } else {
          reply.complete(result);
        }
        return;
      }
      if (message['method'] != 'streamNotify') return;
      final parameters = message['params'];
      if (parameters is! Map || parameters['streamId'] != 'Isolate') return;
      final event = parameters['event'];
      if (event is! Map || !const {
        'IsolateStart', 'IsolateRunnable', 'IsolateExit',
      }.contains(event['kind'])) return;
      final isolate = event['isolate'];
      final ownId = isolate is Map ? isolateId(isolate['id']) : null;
      if (ownId == null) return;
      _record('isolate-event', {
        'event': event['kind'] as String,
        'isolate_id': ownId,
        'vm_epoch_ms': event['timestamp'] is int ? event['timestamp'] as int : null,
      });
    } on Object catch (error) {
      _record('observer-message-failure', {'error_type': error.runtimeType.toString()});
    }
  }

  // Questi due RPC osservano soltanto la VM già pubblicata dal tool Flutter.
  // La finestra inizia dopo streamListen: eventi precedenti non sono recuperabili.
  Future<void> start() async {
    try {
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedApkSha256) ||
          !const {'http', 'ws'}.contains(uri.scheme) ||
          !const {'127.0.0.1', 'localhost', '::1'}.contains(uri.host) ||
          uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment ||
          output.existsSync() || FileSystemEntity.isLinkSync(output.path)) {
        throw StateError('observer context rejected');
      }
      output.parent.createSync(recursive: true);
      output.createSync(exclusive: true);
      _writable = true;
      _record('observer-start', {
        'package': 'com.xniw.clientmerchandisecontrol',
        'expected_apk_sha256': expectedApkSha256,
        'max_records': 129,
      });
      final segments = <String>[
        if (uri.pathSegments.isNotEmpty) uri.pathSegments.first,
        'ws',
      ];
      final socketFuture = _connectSocket(
        uri.replace(scheme: 'ws', pathSegments: segments), _client,
      );
      // Il timeout non cancella un Future: chiude anche un socket tardivo proprio.
      _connectionTask = socketFuture.then<void>((socket) async {
        if (_closed) await _closeSocket(socket);
      }, onError: (Object error) {});
      _socket = await socketFuture;
      if (_closed) return;
      _subscription = _socket!.listen(_message, onError: (Object error) {
        _record('observer-stream-failure', {'error_type': error.runtimeType.toString()});
      }, onDone: () {
        _record('observer-stream-closed');
        _failPending();
      });
      await _call('streamListen', {'streamId': 'Isolate'});
      _record('isolate-subscription-ready');
      final vm = await _call('getVM', const {});
      final pid = vm['pid'];
      final isolates = vm['isolates'];
      _record('vm-snapshot', {
        'pid': pid is int && pid > 0 ? pid : null,
        'vm_start_epoch_ms': vm['startTime'] is int ? vm['startTime'] as int : null,
        'isolates': isolates is List
            ? isolates.whereType<Map>().where((item) => isolateId(item['id']) != null).take(32).map((item) => {
                'id': isolateId(item['id']),
                'number': item['number'] is String && RegExp(r'^[0-9]{1,32}$').hasMatch(item['number'] as String)
                    ? item['number'] as String : null,
              }).toList()
            : <Map<String, Object?>>[],
      });
    } on Object catch (error) {
      _record('observer-start-failure', {'error_type': error.runtimeType.toString()});
      rethrow;
    }
  }

  void driverPhase(String source, String message) {
    if (source != 'VMServiceFlutterDriver') return;
    final found = RegExp(r'^Isolate found with number: ([0-9]{1,32})$').firstMatch(message);
    if (found != null) {
      _record('driver-isolate-found', {'isolate_number': found[1]});
      return;
    }
    final runnable = RegExp(r'^Isolate ([0-9]{1,32}) is runnable\.$').firstMatch(message);
    if (runnable != null) {
      _record('driver-isolate-runnable', {'isolate_number': runnable[1]});
      return;
    }
    const phases = {
      'Isolate is paused at start.': 'paused-at-start',
      'Isolate is paused mid-flight.': 'paused-mid-flight',
      'Attempting to resume isolate': 'resume-requested',
      'Connected to Flutter application.': 'connected',
    };
    if (phases.containsKey(message)) {
      _record('driver-phase', {'phase': phases[message]});
    }
  }

  void connectResult(String result, {String? selectedIsolate, Object? error}) {
    _record('driver-connect-result', {
      'result': result,
      'selected_isolate_id': isolateId(selectedIsolate),
      'error_type': error?.runtimeType.toString(),
    });
  }

  void _failPending() {
    final replies = _pending.values.toList();
    _pending.clear();
    for (final reply in replies) {
      reply.completeError(StateError('observer closed'));
    }
  }

  Future<void> _closeSocket(WebSocket socket) async {
    try {
      await socket.close().timeout(const Duration(seconds: 1));
    } on Object catch (error) {
      cleanupFailed = true;
      _record('observer-cleanup-failure', {'error_type': error.runtimeType.toString()});
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _client.close(force: true);
    _failPending();
    try {
      await _subscription?.cancel();
      if (_socket != null) await _closeSocket(_socket!);
      await _connectionTask?.timeout(const Duration(seconds: 1));
    } on Object catch (error) {
      cleanupFailed = true;
      _record('observer-cleanup-failure', {'error_type': error.runtimeType.toString()});
    } finally {
      _record('observer-stop', {'omitted_records': _omitted,
        'cleanup': cleanupFailed ? 'FAIL' : 'PASS'});
    }
  }
}

// Il callback iniettato serve soltanto ai test del protocollo del driver host.
// Il caller produzione mantiene FlutterDriver.connect e il suo resume invariati.
Future<FlutterDriver> connectObservedAndroidDriver(
  AndroidStartupObserver observer, {
  required Future<FlutterDriver> Function(Duration remaining) connect,
}) async {
  final clock = Stopwatch()..start();
  final originalLog = driverLog;
  try {
    try {
      await observer.start().timeout(const Duration(seconds: 2));
    } on Object {
      await observer.close();
    }
    driverLog = (source, message) {
      observer.driverPhase(source, message);
      originalLog(source, message);
    };
    final remaining = const Duration(seconds: 20) - clock.elapsed;
    if (remaining <= Duration.zero) throw TimeoutException('driver connect budget');
    final driver = await connect(remaining);
    observer.connectResult('connected', selectedIsolate: driver.appIsolate.id);
    return driver;
  } on Object catch (error) {
    observer.connectResult('failed', error: error);
    rethrow;
  } finally {
    driverLog = originalLog;
    await observer.close();
  }
}
