import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_driver/flutter_driver.dart';

import '../../test_driver/support/android_startup_observer.dart';

void main() {
  late Directory temporary;
  late HttpServer server;
  final sockets = <WebSocket>[];
  final calls = <String>[];
  late AndroidStartupObserver observer;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('cmc-startup-observer-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    sockets.clear();
    calls.clear();
    observer = AndroidStartupObserver(
      File('${temporary.path}/vm.jsonl'),
      'a' * 64,
      Uri.parse('http://127.0.0.1:${server.port}/SECRET/'),
    );
  });

  tearDown(() async {
    await observer.close();
    for (final socket in sockets) {
      await socket.close();
    }
    await server.close(force: true);
    await temporary.delete(recursive: true);
  });

  void serve({bool rejected = false, bool withhold = false, int events = 2}) {
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      sockets.add(socket);
      socket.listen((dynamic raw) {
        final message = jsonDecode(raw as String) as Map<String, dynamic>;
        final method = message['method'] as String;
        calls.add(method);
        if (withhold) return;
        if (method == 'streamListen') {
          socket.add(jsonEncode({'jsonrpc': '2.0', 'id': message['id'], 'result': {'type': 'Success'}}));
          for (var index = 0; index < events; index++) {
            socket.add(jsonEncode({
              'jsonrpc': '2.0',
              'method': 'streamNotify',
              'params': {
                'streamId': 'Isolate',
                'event': {
                  'kind': index.isEven ? 'IsolateStart' : 'IsolateExit',
                  'timestamp': 1792119103000 + index,
                  'isolate': {'id': 'isolates/42', 'name': 'SECRET-name'},
                  'unsafe': 'SECRET-payload',
                },
              },
            }));
          }
        } else if (method == 'getVM') {
          socket.add(jsonEncode({
            'jsonrpc': '2.0', 'id': message['id'],
            if (rejected) 'error': {'message': 'SECRET-rpc-error'},
            if (!rejected) 'result': {
              'type': 'VM', 'pid': 2398, 'name': 'SECRET-vm',
              'isolates': [{'id': 'isolates/42', 'number': '42', 'name': 'SECRET-root'}],
            },
          }));
        } else {
          fail('RPC mutante o inatteso: $method');
        }
      });
    });
  }

  List<Map<String, dynamic>> records() => observer.output
      .readAsLinesSync()
      .map((line) => jsonDecode(line) as Map<String, dynamic>)
      .toList();

  test('one-shot read-only: PID, eventi isolate e hash senza URL o payload', () async {
    serve();
    await observer.start().timeout(const Duration(seconds: 2));
    observer.driverPhase('VMServiceFlutterDriver', 'Isolate found with number: 42');
    observer.driverPhase('VMServiceFlutterDriver', 'Attempting to resume isolate');
    observer.driverPhase('VMServiceFlutterDriver', 'SECRET-ignore');
    observer.connectResult('connected', selectedIsolate: 'isolates/42');
    await observer.close();
    final rows = records();
    expect(calls, ['streamListen', 'getVM']);
    expect(rows.where((row) => row['kind'] == 'isolate-event').map((row) => row['event']),
        ['IsolateStart', 'IsolateExit']);
    expect(rows.singleWhere((row) => row['kind'] == 'vm-snapshot')['pid'], 2398);
    expect(rows.first['expected_apk_sha256'], 'a' * 64);
    expect(rows.singleWhere((row) => row['kind'] == 'driver-isolate-found')['isolate_number'], '42');
    expect(rows.singleWhere((row) => row['kind'] == 'driver-phase')['phase'], 'resume-requested');
    expect(rows.last['kind'], 'observer-stop');
    expect(observer.output.readAsStringSync(), isNot(contains('SECRET')));
  });

  test('RPC failure conserva solo il tipo e chiude il socket proprio', () async {
    serve(rejected: true);
    await expectLater(observer.start(), throwsStateError);
    await observer.close();
    expect(records().last['kind'], 'observer-stop');
    expect(observer.output.readAsStringSync(), isNot(contains('SECRET')));
    expect(calls, ['streamListen', 'getVM']);
  });

  test('timeout pending non avvia reconnect e il cleanup termina la richiesta', () async {
    serve(withhold: true);
    final start = observer.start();
    await expectLater(start.timeout(const Duration(milliseconds: 20)), throwsA(isA<TimeoutException>()));
    await observer.close();
    await expectLater(start, throwsStateError);
    expect(calls, ['streamListen']);
    expect(records().last['kind'], 'observer-stop');
  });

  test('cap eventi con contatore omissioni e nessun payload grezzo', () async {
    serve(events: 200);
    await observer.start().timeout(const Duration(seconds: 2));
    await observer.close();
    final rows = records();
    expect(rows.length, 129);
    expect(rows.last['omitted_records'], greaterThan(0));
    expect(observer.output.lengthSync(), lessThan(65536));
    expect(observer.output.readAsStringSync(), isNot(contains('SECRET')));
  });


  test('connect fallito preserva errore, selezione, passthrough e restore logger', () async {
    serve();
    final original = driverLog;
    final forwarded = <String>[];
    final prior = (String source, String message) => forwarded.add('$source: $message');
    driverLog = prior;
    final failure = StateError('SECRET-driver-failure');
    try {
      await expectLater(connectObservedAndroidDriver(observer, connect: (remaining) async {
        expect(remaining, lessThanOrEqualTo(const Duration(seconds: 20)));
        expect(remaining, greaterThan(Duration.zero));
        driverLog('VMServiceFlutterDriver', 'Isolate found with number: 42');
        driverLog('VMServiceFlutterDriver', 'Attempting to resume isolate');
        driverLog('OtherSource', 'passthrough unchanged');
        throw failure;
      }), throwsA(same(failure)));
      expect(identical(driverLog, prior), isTrue);
      expect(forwarded, [
        'VMServiceFlutterDriver: Isolate found with number: 42',
        'VMServiceFlutterDriver: Attempting to resume isolate',
        'OtherSource: passthrough unchanged',
      ]);
      final rows = records();
      expect(rows.singleWhere((row) => row['kind'] == 'driver-isolate-found')['isolate_number'], '42');
      expect(rows.singleWhere((row) => row['kind'] == 'driver-connect-result')['result'], 'failed');
      expect(rows.last['cleanup'], 'PASS');
      expect(observer.output.readAsStringSync(), isNot(contains('SECRET')));
    } finally {
      driverLog = original;
    }
  });

  test('connessione tardiva dopo close chiude il solo socket proprio', () async {
    final pending = Completer<WebSocket>();
    final socket = ObserverSocket();
    observer = AndroidStartupObserver(
      File('${temporary.path}/late.jsonl'), 'a' * 64,
      Uri.parse('http://127.0.0.1:${server.port}/SECRET/'),
      connectSocket: (uri, client) => pending.future,
    );
    final starting = observer.start();
    final closing = observer.close();
    pending.complete(socket);
    await starting;
    await closing;
    expect(socket.closeCalls, 1);
    expect(socket.rpcCalls, isEmpty);
    expect(records().last['cleanup'], 'PASS');
  });

  test('cleanup socket fallito resta FAIL senza payload nel receipt', () async {
    final socket = ObserverSocket(failClose: true);
    observer = AndroidStartupObserver(
      File('${temporary.path}/cleanup.jsonl'), 'a' * 64,
      Uri.parse('http://127.0.0.1:${server.port}/SECRET/'),
      connectSocket: (uri, client) async => socket,
    );
    await observer.start();
    await observer.close();
    expect(observer.cleanupFailed, isTrue);
    expect(records().last['cleanup'], 'FAIL');
    expect(records().where((row) => row['kind'] == 'observer-cleanup-failure'), hasLength(1));
    expect(observer.output.readAsStringSync(), isNot(contains('SECRET')));
  });


  test('sendthrow non crea async uncaught e conserva errore primario driver', () async {
    final socket = ObserverSocket(failAdd: true);
    observer = AndroidStartupObserver(
      File('${temporary.path}/sendthrow.jsonl'), 'a' * 64,
      Uri.parse('http://127.0.0.1:${server.port}/SECRET/'),
      connectSocket: (uri, client) async => socket,
    );
    final asynchronous = <Object>[];
    final primary = StateError('SECRET-original-driver-failure');
    final completed = Completer<void>();
    runZonedGuarded(() async {
      try {
        await expectLater(connectObservedAndroidDriver(observer, connect: (remaining) async {
          throw primary;
        }), throwsA(same(primary)));
        // I completeError non ascoltati vengono consegnati alla error zone.
        // La barrier ad eventqueue permette di rilevarli anche dopo il cleanup.
        await Future<void>.delayed(Duration.zero);
      } finally {
        completed.complete();
      }
    }, (error, stack) => asynchronous.add(error));
    await completed.future;
    expect(asynchronous, isEmpty);
    expect(socket.rpcCalls, ['streamListen']);
    expect(socket.closeCalls, 1);
    final rows = records();
    expect(rows.singleWhere((row) => row['kind'] == 'observer-start-failure')['error_type'], 'StateError');
    expect(rows.singleWhere((row) => row['kind'] == 'driver-connect-result')['result'], 'failed');
    expect(observer.output.readAsStringSync(), isNot(contains('SECRET')));
  });

  test('rifiuta URL esterni prima di qualunque connessione', () async {
    observer = AndroidStartupObserver(
      File('${temporary.path}/external.jsonl'), 'a' * 64,
      Uri.parse('http://example.invalid/SECRET/'),
    );
    await expectLater(observer.start(), throwsStateError);
    expect(calls, isEmpty);
    expect(observer.output.existsSync(), isFalse);
  });
}

// Nessuna risorsa OS: risposta RPC controllata per late completion e cleanupFAIL.
class ObserverSocket extends Stream<dynamic> implements WebSocket {
  ObserverSocket({this.failClose = false, this.failAdd = false});
  final bool failClose;
  final bool failAdd;
  final _messages = StreamController<dynamic>();
  final rpcCalls = <String>[];
  int closeCalls = 0;

  @override
  void add(dynamic raw) {
    final message = jsonDecode(raw as String) as Map<String, dynamic>;
    rpcCalls.add(message['method'] as String);
    if (failAdd) throw StateError('SECRET-synchronous-send-error');
    _messages.add(jsonEncode({
      'jsonrpc': '2.0', 'id': message['id'],
      'result': message['method'] == 'getVM'
          ? {'type': 'VM', 'pid': 2398, 'isolates': <Object>[]}
          : {'type': 'Success'},
    }));
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    closeCalls++;
    if (failClose) throw StateError('SECRET-close-error');
  }

  @override
  StreamSubscription<dynamic> listen(void Function(dynamic)? onData, {
    Function? onError, void Function()? onDone, bool? cancelOnError,
  }) => _messages.stream.listen(onData, onError: onError, onDone: onDone,
      cancelOnError: cancelOnError);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
