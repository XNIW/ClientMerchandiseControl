// ignore_for_file: file_names, avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../integration_test/support/os_frame_sync.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> fails<T extends Object>(Future<void> operation) async {
  try {
    await operation;
  } on Object catch (error) {
    check(error is T, 'Tipo di failure inatteso: ${error.runtimeType}');
    return;
  }
  throw StateError('La failure attesa non è arrivata');
}

class Fixture {
  Fixture({Duration timeout = const Duration(seconds: 1)}) {
    sync = OsFrameSync(
      timeout: timeout,
      readinessTimeout: timeout,
      post: (event, data) {
        check(event == osFrameRequestEvent, 'Tipo evento errato');
        requests.add(data);
      },
      register: (name, handler) {
        check(
          name == osFrameAckExtension ||
              name == osFramePendingExtension ||
              name == osFrameClaimExtension,
          'Extension errata',
        );
        registrations++;
        if (name == osFrameAckExtension) acknowledgement = handler;
      },
    );
  }

  late final OsFrameSync sync;
  late developer.ServiceExtensionHandler acknowledgement;
  final requests = <Map<String, Object?>>[];
  var registrations = 0;

  Future<bool> ack({
    String? name,
    String? id,
    String result = 'true',
    String method = osFrameAckExtension,
  }) async {
    final request = requests.last;
    final response = await acknowledgement(method, <String, String>{
      'name': name ?? request['name']! as String,
      'request_id': id ?? request['request_id']! as String,
      'result': result,
    });
    return (jsonDecode(response.result!) as Map<String, dynamic>)['accepted'] ==
        true;
  }

  Future<bool> claim({String? name, String? id}) async {
    final request = requests.last;
    final response = await sync.claim(osFrameClaimExtension, <String, String>{
      'name': name ?? request['name']! as String,
      'request_id': id ?? request['request_id']! as String,
    });
    return (jsonDecode(response.result!) as Map)['accepted'] == true;
  }
}

Future<void> main() async {
  final tests = <String, Future<void> Function()>{
    'focus marker validato senza path o token parziali': () async {
      check(validOsFrameMarker('01-address-editor-focus-compact200'), 'Focus');
      for (final name in <String>[
        '../focus',
        'review-focus/file',
        'review-focused',
        '-focus',
        'review\nfocus',
        'focus-${List.filled(100, 'a').join()}',
      ]) {
        check(!validOsFrameMarker(name), 'Marker invalido accettato');
        final fixture = Fixture();
        await fails<ArgumentError>(fixture.sync.capture(name));
        check(fixture.requests.isEmpty, 'Evento invalido emesso');
        check(fixture.registrations == 0, 'Extension invalida registrata');
      }
    },
    'capture attende ACK positivo e registra una volta': () async {
      final fixture = Fixture();
      var complete = false;
      final pending = fixture.sync.capture('01-address-focus').then((_) {
        complete = true;
      });
      await Future<void>.value();
      check(!complete, 'Capture è avanzata prima dell\'ACK');
      check(!await fixture.ack(), 'ACK preclaim accettato');
      check(!await fixture.claim(id: 'unknown'), 'Claim unknown accettato');
      check(await fixture.claim(), 'Claim rifiutato');
      check(!await fixture.claim(), 'Claim duplicato accettato');
      check(await fixture.ack(), 'ACK valido rifiutato');
      await pending;
      check(complete, 'Capture non sbloccata');
      final second = fixture.sync.capture('02-search-focus');
      check(fixture.requests.last['request_id'] == '2', 'ID non monotono');
      check(await fixture.claim(), 'Secondo claim rifiutato');
      check(await fixture.ack(), 'Secondo ACK rifiutato');
      await second;
      check(fixture.registrations == 3, 'Extension registrate due volte');
    },
    'ACK negativo mantiene failure esplicita': () async {
      final fixture = Fixture();
      final failure = fails<StateError>(fixture.sync.capture('01-note-focus'));
      check(await fixture.claim(), 'Claim rifiutato');
      check(await fixture.ack(result: 'false'), 'ACK negativo rifiutato');
      await failure;
    },
    'ACK unknown o malformed non sblocca capture': () async {
      final fixture = Fixture();
      var complete = false;
      final pending = fixture.sync.capture('01-review-focus').then((_) {
        complete = true;
      });
      check(await fixture.claim(), 'Claim rifiutato');
      check(!await fixture.ack(name: 'other-focus'), 'Nome unknown accettato');
      check(!await fixture.ack(id: '9'), 'ID unknown accettato');
      check(!await fixture.ack(result: 'PASS'), 'Esito malformed accettato');
      check(
        !await fixture.ack(method: 'ext.other'),
        'Metodo unknown accettato',
      );
      check(!complete, 'ACK unknown ha sbloccato capture');
      check(await fixture.ack(), 'ACK valido finale rifiutato');
      check(!await fixture.ack(), 'ACK duplicato accettato');
      await pending;
    },
    'timeout è failure e ACK late non sblocca nuova richiesta': () async {
      final fixture = Fixture(timeout: const Duration(milliseconds: 1));
      await fails<TimeoutException>(fixture.sync.capture('01-note-focus'));
      check(!await fixture.ack(), 'ACK late accettato');
      check(!await fixture.claim(), 'Claim late accettato');
      final second = fixture.sync.capture('02-review-focus');
      check(!await fixture.ack(name: '01-note-focus', id: '1'), 'ACK stale');
      check(
        !await fixture.claim(name: '01-note-focus', id: '1'),
        'Claim stale',
      );
      check(await fixture.claim(), 'Claim corrente rifiutato');
      check(await fixture.ack(), 'ACK corrente rifiutato');
      await second;
    },
    'capture concorrente non sostituisce richiesta propria': () async {
      final fixture = Fixture();
      final first = fixture.sync.capture('01-note-focus');
      await fails<StateError>(fixture.sync.capture('02-review-focus'));
      check(fixture.requests.length == 1, 'Richiesta concorrente emessa');
      check(await fixture.claim(), 'Claim rifiutato');
      check(await fixture.ack(), 'Richiesta propria persa');
      await first;
    },
    'postEvent fallito libera il pending e resta failure': () async {
      final sync = OsFrameSync(
        post: (_, _) => throw StateError('post failed'),
        register: (_, _) {},
      );
      await fails<StateError>(sync.capture('01-note-focus'));
      await fails<StateError>(sync.capture('02-review-focus'));
    },
    'host ACK dopo risultato cattura e invalido senza tool': () async {
      final captured = <String>[];
      final acks = <Map<String, String>>[];
      final host = OsFrameHost(
        claim: (_) async => true,
        capture: (name) async {
          check(acks.isEmpty, 'ACK prima della cattura');
          captured.add(name);
          return true;
        },
        acknowledge: (parameters) async => acks.add(parameters),
      );
      await host.handle(<String, String>{
        'name': '01-note-focus',
        'request_id': '1',
      });
      check(captured.single == '01-note-focus', 'Cattura persa');
      check(acks.single['result'] == 'true', 'ACK positivo errato');
      for (final request in <Map<String, String>?>[
        null,
        {'name': '../focus', 'request_id': '2'},
        {'name': '02-review-focus', 'request_id': 'unknown'},
      ]) {
        await host.handle(request);
        check(acks.last['result'] == 'false', 'ACK invalido positivo');
      }
      check(captured.length == 1, 'Tool avviato su richiesta invalida');
    },
    'host failure cattura conserva ACK negativo': () async {
      for (final throwing in <bool>[false, true]) {
        final acks = <Map<String, String>>[];
        final host = OsFrameHost(
          claim: (_) async => true,
          capture: (_) async {
            if (throwing) throw StateError('capture failed');
            return false;
          },
          acknowledge: (parameters) async => acks.add(parameters),
        );
        await host.handle({'name': '01-note-focus', 'request_id': '1'});
        check(acks.single['result'] == 'false', 'Failure promossa a PASS');
      }
    },
    'host concorrente rifiutato senza avvio secondo tool': () async {
      final pending = Completer<bool>();
      final acks = <Map<String, String>>[];
      var captures = 0;
      final host = OsFrameHost(
        claim: (_) async => true,
        capture: (_) {
          captures++;
          return pending.future;
        },
        acknowledge: (parameters) async => acks.add(parameters),
      );
      final first = host.handle({'name': '01-note-focus', 'request_id': '1'});
      await host.handle({'name': '02-review-focus', 'request_id': '2'});
      check(captures == 1, 'Secondo tool concorrente avviato');
      check(acks.single['result'] == 'false', 'Concorrente accettato');
      pending.complete(true);
      await first;
      check(acks.last['result'] == 'true', 'Risultato proprio perso');
    },
    'host ACK fallito non viene assorbito come PASS': () async {
      final host = OsFrameHost(
        claim: (_) async => true,
        capture: (_) async => true,
        acknowledge: (_) async => throw TimeoutException('ack'),
      );
      await fails<TimeoutException>(
        host.handle({'name': '01-note-focus', 'request_id': '1'}),
      );
    },
    'timeout dopo claim rifiuta ACK late': () async {
      final fixture = Fixture(timeout: const Duration(milliseconds: 1));
      final failure = fails<TimeoutException>(
        fixture.sync.capture('01-note-focus'),
      );
      check(await fixture.claim(), 'Claim rifiutato');
      await failure;
      check(!await fixture.ack(), 'ACK oltre deadline accettato');
    },
    'host claim rifiutato non avvia tool o ACK': () async {
      var actions = 0;
      final host = OsFrameHost(
        claim: (_) async => false,
        capture: (_) async {
          actions++;
          return true;
        },
        acknowledge: (_) async => actions++,
      );
      await host.handle({'name': '01-note-focus', 'request_id': '1'});
      check(actions == 0, 'Richiesta stale ha avviato azioni OS');
    },
    'prima richiesta precede listener ed è recuperata da snapshot pending':
        () async {
          final fixture = Fixture();
          final first = fixture.sync.capture('01-address-focus');
          // Nessun listener era collegato quando postEvent ha emesso la richiesta.
          final snapshot = await fixture.sync.pendingRequest(
            osFramePendingExtension,
            <String, String>{},
          );
          final request =
              (jsonDecode(snapshot.result!) as Map)['pending'] as Map;
          var captures = 0;
          final host = OsFrameHost(
            claim: (parameters) async => fixture.claim(
              name: parameters['name'],
              id: parameters['request_id'],
            ),
            capture: (_) async {
              captures++;
              return true;
            },
            acknowledge: (parameters) async {
              final ack = await fixture.acknowledgement(
                osFrameAckExtension,
                parameters,
              );
              check(
                (jsonDecode(ack.result!) as Map)['accepted'] == true,
                'ACK',
              );
            },
          );
          final initial = host.handle(request);
          await host.handle(
            request,
          ); // Evento live incrociato con snapshot in corso.
          await initial;
          await first;
          await host.handle(
            request,
          ); // Lo stesso evento live arrivato dopo snapshot.
          check(captures == 1, 'Evento/snapshot ha duplicato capture o ACK');
          final empty = await fixture.sync.pendingRequest(
            osFramePendingExtension,
            <String, String>{},
          );
          check((jsonDecode(empty.result!) as Map)['pending'] == null, 'Stale');
        },
  };
  for (final entry in tests.entries) {
    await entry.value();
    print('PASS: ${entry.key}');
  }
  print('PASS: ${tests.length} regressioni bridge OS sincronizzato');
}
