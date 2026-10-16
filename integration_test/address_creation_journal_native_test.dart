// Fixture nativa senza Auth/backend, eseguita due volte nello stesso bundle.
// Il runner assegna un UUID nuovo, termina il processo seed e avvia recover
// senza reinstallare o cancellare dati. Il runner attesta stop e identità nativa.
import 'dart:convert';
import 'dart:io';

import 'package:client_merchandise_control/features/account/data/secure_address_creation_journal.dart';
import 'package:client_merchandise_control/features/account/domain/address_creation_intent.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/common.dart' as integration_results;
import 'package:integration_test/integration_test.dart';
// Stesso terminal gate postTest/tearDownAll della fixture guest già separata.
// ignore: depend_on_referenced_packages, implementation_imports
import 'package:test_api/src/backend/invoker.dart' show Invoker;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

const _apiVersion = 'address-journal-native-evidence.v2';
const _failureApiVersion = 'address-journal-native-evidence.v5';
const _fixtureOwner = 'f0540000-0000-4000-8000-000000000001';

CustomerAddressDraft _draft(String runId, int seedPid) => CustomerAddressDraft(
  label: 'Fixture journal',
  recipientName: 'Cliente sintetico',
  addressLine1: 'Calle de prueba 123',
  addressLine2: null,
  commune: 'Santiago',
  region: 'Metropolitana',
  postalCode: null,
  countryCode: 'CL',
  deliveryInstructions: 'fixture-run:$runId;seed-pid:$seedPid',
);

void main() {
  final publisher = _NativeAddressTerminalPublisher(
    const String.fromEnvironment('ADDRESS_JOURNAL_RUN_ID'),
  );
  late final _NativeAddressTestBinding binding;
  // Registrazione precedente al binding SDK: tearDownAll LIFO pubblica il file
  // solo dopo postTest e dopo report/cleanup native SDK, con Future atteso.
  tearDownAll(() => publisher.publish(binding));
  binding = _NativeAddressTestBinding();
  testWidgets('journal indirizzo: persistenza nativa dopo processo terminato', (
    tester,
  ) async {
    try {
      expect(Platform.isAndroid || Platform.isIOS, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      const runId = String.fromEnvironment('ADDRESS_JOURNAL_RUN_ID');
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ).hasMatch(runId),
        isTrue,
        reason: 'Occorre un UUID fixture nuovo assegnato dal runner.',
      );

      final support = await getApplicationSupportDirectory();
      final directory = Directory(
        path.join(support.path, 'task054-address-journal-$runId'),
      );
      await directory.create(recursive: true);
      publisher.directory = directory;

      // Plugin nativo reale: barriera Android o Keychain iOS, senza mock.
      final journal = SecureAddressCreationJournal();
      final pending = await journal.read(_fixtureOwner);
      final phase = pending == null ? 'seed' : 'recover';
      final int seedPid;
      if (pending == null) {
        seedPid = pid;
        await journal.write(
          _fixtureOwner,
          AddressCreationIntent(id: runId, draft: _draft(runId, seedPid)),
        );
      } else {
        expect(
          pending.id,
          runId,
          reason: 'Nessun journal precedente va riusato.',
        );
        publisher.phase = phase;
        final marker = RegExp(
          '^fixture-run:$runId;seed-pid:([1-9][0-9]*)\$',
        ).firstMatch(pending.draft.deliveryInstructions ?? '');
        publisher.checkRecover('recover_marker', () {
          expect(marker, isNotNull);
        });
        seedPid = int.parse(marker!.group(1)!);
        publisher.checkRecover('recover_process', () {
          expect(
            pid,
            isNot(seedPid),
            reason: 'Serve un processo nativo nuovo.',
          );
        });
      }
      final restored = await SecureAddressCreationJournal().read(_fixtureOwner);
      publisher.checkRecover('restored_identity', () {
        expect(restored?.id, runId);
      });
      publisher.checkRecover('restored_payload', () {
        expect(restored?.matches(_draft(runId, seedPid)), isTrue);
      });
      if (phase == 'recover') {
        await journal.clear(_fixtureOwner);
        final cleared = await journal.read(_fixtureOwner);
        publisher.checkRecover('cleared_readback', () {
          expect(cleared, isNull);
        });
      }
      final candidate = <String, Object?>{
        'apiVersion': _apiVersion,
        'phase': phase,
        'processId': pid,
        'seedProcessId': seedPid,
        'runId': runId,
        'nativeWriteRead': phase == 'seed' ? 'PASS' : 'NOT_RUN',
        'processRestartRead': phase == 'recover' ? 'PASS' : 'NOT_RUN',
        'cleanup': phase == 'recover' ? 'PASS' : 'NOT_RUN',
        'backend': 'NOT_RUN',
      };
      // Compatibilità del solo driver VM storico. Il runner file non legge questa
      // candidate: attende esclusivamente il file del publisher terminale.
      binding.reportData = candidate;
      publisher.successCandidate = Map<String, Object?>.unmodifiable(candidate);
    } catch (error) {
      publisher.errorType = error is TestFailure
          ? 'assertion'
          : error is FileSystemException
          ? 'filesystem'
          : 'unexpected';
      rethrow;
    }
  });
}

class _NativeAddressTestBinding extends IntegrationTestWidgetsFlutterBinding {
  bool postTestCompleted = false;
  bool postTestFailed = false;

  void _recordPostTestFailure() {
    postTestFailed = true;
    results['address-journal-postTest'] = integration_results.Failure(
      'address-journal-postTest',
      'sanitized_post_test_failure',
    );
  }

  @override
  void postTest() {
    if (Invoker.current?.liveTest.state.result.isFailing ?? true) {
      _recordPostTestFailure();
    }
    try {
      super.postTest();
    } catch (_) {
      _recordPostTestFailure();
      rethrow;
    } finally {
      postTestCompleted = true;
    }
  }
}

class _NativeAddressTerminalPublisher {
  _NativeAddressTerminalPublisher(this.runId);

  final String runId;
  Directory? directory;
  String phase = 'seed';
  String? errorType;
  String? failureCheckpoint;
  Map<String, Object?>? successCandidate;
  bool _started = false;

  // Solo il singolo expect recover resta attribuibile se solleva TestFailure.
  // Letture/clear async e failure terminali conservano checkpoint non osservato.
  void checkRecover(String checkpoint, void Function() check) {
    failureCheckpoint = phase == 'recover' ? checkpoint : null;
    check();
    failureCheckpoint = null;
  }

  Future<void> publish(_NativeAddressTestBinding binding) async {
    if (_started) {
      throw StateError('Publisher terminale già avviato.');
    }
    _started = true;
    // Nessuna .then scartata: il test runner attende questo callback completo.
    final sdkPassed = await binding.allTestsPassed.future;
    // Il loop LIFO SDK usa whenComplete: prima della lettura del risultato,
    // lascia propagare le failure microtask della precedente callback.
    await Future<void>.delayed(Duration.zero);
    final teardownResult = Invoker.current?.liveTest.state.result.isFailing;
    final teardownFailed = teardownResult ?? true;
    // Un solo snapshot sincrono: il gate e la diagnosi usano gli stessi valori.
    final postTestCompleted = binding.postTestCompleted;
    final postTestFailed = binding.postTestFailed;
    final failureMethodsEmpty = binding.failureMethodsDetails.isEmpty;
    final candidate = successCandidate;
    final bodyErrorType = errorType;
    final terminalPassed =
        sdkPassed &&
        postTestCompleted &&
        !postTestFailed &&
        !teardownFailed &&
        failureMethodsEmpty &&
        bodyErrorType == null &&
        candidate != null;
    final terminalGateMask =
        (sdkPassed ? 0 : 1) |
        (postTestCompleted ? 0 : 2) |
        (postTestFailed ? 4 : 0) |
        (teardownFailed ? 8 : 0) |
        (failureMethodsEmpty ? 0 : 16) |
        (candidate != null ? 0 : 32) |
        (teardownResult == null ? 64 : 0);
    final checkpoint = bodyErrorType == 'assertion' && phase == 'recover'
        ? failureCheckpoint
        : null;
    final targetDirectory = directory;
    if (targetDirectory == null) {
      // Setup senza sandbox attestato: nessun file success, runner FAIL/timeout.
      return;
    }
    final result = terminalPassed
        ? candidate
        : <String, Object?>{
            'apiVersion': _failureApiVersion,
            'phase': phase,
            'runId': runId,
            'processId': pid,
            'status': 'FAIL',
            'failureOrigin': bodyErrorType == null ? 'terminal_gate' : 'body',
            'failureCheckpoint': checkpoint,
            'terminalGateMask': bodyErrorType == null ? terminalGateMask : null,
            'errorType': bodyErrorType ?? 'assertion',
          };
    binding.reportData = result;
    await _publishTerminalJson(
      File(path.join(targetDirectory.path, '$phase.json')),
      result,
    );
  }
}

Future<void> _publishTerminalJson(
  File target,
  Map<String, Object?> value,
) async {
  // Unico publisher nel sandbox/run proprio. Prima si chiude il record completo;
  // il rename finale lo rende osservabile. Un record precedente è preservato.
  final pending = File('${target.path}.pending-$pid');
  if (await target.exists()) {
    throw StateError('Record terminale già presente.');
  }
  await _writeNewJson(pending, value);
  if (await target.exists()) {
    throw StateError('Record terminale già presente.');
  }
  await pending.rename(target.path);
}

Future<void> _writeNewJson(File file, Map<String, Object?> value) async {
  // dart:io non espone O_EXCL portabile. Lock esclusivo, verifica length==0
  // e append evitano truncate/sovrascrittura; il runner possiede l'unico bundle.
  if (await file.exists()) {
    throw StateError('Record fixture già presente.');
  }
  final output = await file.open(mode: FileMode.append);
  var locked = false;
  try {
    await output.lock(FileLock.exclusive);
    locked = true;
    if (await output.length() != 0) {
      throw StateError('Record fixture già presente.');
    }
    await output.writeString(jsonEncode(value));
    await output.flush();
  } finally {
    if (locked) await output.unlock();
    await output.close();
  }
}
