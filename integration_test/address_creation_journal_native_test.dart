// Fixture nativa senza Auth/backend, eseguita due volte nello stesso bundle.
// Il runner assegna un UUID nuovo, termina il processo seed e avvia recover
// senza reinstallare o cancellare dati. Il runner attesta stop e identità nativa.
import 'dart:io';

import 'package:client_merchandise_control/features/account/data/secure_address_creation_journal.dart';
import 'package:client_merchandise_control/features/account/domain/address_creation_intent.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('journal indirizzo: persistenza nativa dopo processo terminato', (
    tester,
  ) async {
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
      final marker = RegExp(
        '^fixture-run:$runId;seed-pid:([1-9][0-9]*)\$',
      ).firstMatch(pending.draft.deliveryInstructions ?? '');
      expect(marker, isNotNull);
      seedPid = int.parse(marker!.group(1)!);
      expect(pid, isNot(seedPid), reason: 'Serve un processo nativo nuovo.');
    }
    final restored = await SecureAddressCreationJournal().read(_fixtureOwner);
    expect(restored?.id, runId);
    expect(restored?.matches(_draft(runId, seedPid)), isTrue);
    if (phase == 'recover') {
      await journal.clear(_fixtureOwner);
      expect(await journal.read(_fixtureOwner), isNull);
    }
    binding.reportData = {
      'apiVersion': 'address-journal-native-evidence.v2',
      'phase': phase,
      'processId': pid,
      'seedProcessId': seedPid,
      'runId': runId,
      'nativeWriteRead': phase == 'seed' ? 'PASS' : 'NOT_RUN',
      'processRestartRead': phase == 'recover' ? 'PASS' : 'NOT_RUN',
      'cleanup': phase == 'recover' ? 'PASS' : 'NOT_RUN',
      'backend': 'NOT_RUN',
    };
  });
}
