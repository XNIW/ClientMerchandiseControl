import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:client_merchandise_control/features/after_sales/data/supabase_customer_after_sales_repository.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _owner = '10000000-0000-4000-8000-000000000001';
const _case = '81000000-0000-4000-8000-000000000001';
const _ticket = '82000000-0000-4000-8000-000000000001';
const _evidence = '83000000-0000-4000-8000-000000000001';

CustomerAfterSalesEvidenceInput _input({bool Function()? canContinue}) =>
    CustomerAfterSalesEvidenceInput(
      bytes: Uint8List.fromList([1]),
      extension: 'png',
      mimeType: 'image/png',
      ownerId: _owner,
      canContinue: canContinue,
    );

void main() {
  test(
    'ACK Storage perso: register stesso path, upload e ticket una volta',
    () async {
      final port = _Port()..loseUploadAck = true;
      final input = _input();
      final repo = SupabaseCustomerAfterSalesRepository(port: port);
      expect(await repo.uploadEvidence(caseId: _case, input: input), _evidence);
      expect(await repo.uploadEvidence(caseId: _case, input: input), _evidence);
      expect(port.tickets, 1);
      expect(port.uploads, 1);
      expect(port.registers, 1);
    },
  );

  test(
    'ACK register perso: receipt esatta risolve senza replay o nuovo upload',
    () async {
      final port = _Port()..loseRegisterAck = true;
      final repo = SupabaseCustomerAfterSalesRepository(port: port);
      final input = _input();
      await expectLater(
        repo.uploadEvidence(caseId: _case, input: input),
        throwsA(isA<CustomerAfterSalesException>()),
      );
      expect(await repo.uploadEvidence(caseId: _case, input: input), _evidence);
      expect(port.tickets, 1);
      expect(port.uploads, 1);
      expect(port.registers, 1);
    },
  );

  test(
    'receipt di altro owner mai confermata né sostituita con nuovo ticket',
    () async {
      final port = _Port()..loseRegisterAck = true;
      final repo = SupabaseCustomerAfterSalesRepository(port: port);
      final input = _input();
      await expectLater(
        repo.uploadEvidence(caseId: _case, input: input),
        throwsA(isA<CustomerAfterSalesException>()),
      );
      port.wrongReceiptOwner = true;
      await expectLater(
        repo.uploadEvidence(caseId: _case, input: input),
        throwsA(isA<CustomerAfterSalesException>()),
      );
      expect(input.transfer.evidenceId, isNull);
      expect(port.tickets, 1);
      expect(port.uploads, 1);
    },
  );

  test('Storage lento: timeout e secondo tap non avviano nuove fasi', () async {
    final port = _Port()..uploadBarrier = Completer<void>();
    final repo = SupabaseCustomerAfterSalesRepository(
      port: port,
      timeout: const Duration(milliseconds: 10),
    );
    final input = _input();
    await expectLater(
      repo.uploadEvidence(caseId: _case, input: input),
      throwsA(isA<CustomerAfterSalesException>()),
    );
    await expectLater(
      repo.uploadEvidence(caseId: _case, input: input),
      throwsA(isA<CustomerAfterSalesException>()),
    );
    expect(port.uploads, 1);
    port.uploadBarrier!.complete();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    expect(
      port.registers,
      0,
      reason: 'Timeout non autorizza la coroutine vecchia a proseguire',
    );
    expect(await repo.uploadEvidence(caseId: _case, input: input), _evidence);
    expect(port.tickets, 1);
    expect(port.uploads, 1);
  });

  test('cambio owner durante upload non invoca register', () async {
    final port = _Port()..uploadBarrier = Completer<void>();
    final repo = SupabaseCustomerAfterSalesRepository(port: port);
    final input = _input();
    final pending = repo.uploadEvidence(caseId: _case, input: input);
    await Future<void>.delayed(Duration.zero);
    port.owner = '10000000-0000-4000-8000-000000000002';
    port.uploadBarrier!.complete();
    await expectLater(pending, throwsA(isA<CustomerAfterSalesException>()));
    expect(port.registers, 0);
  });

  test('navigazione durante upload ferma la fase register', () async {
    var mounted = true;
    final port = _Port()..uploadBarrier = Completer<void>();
    final repo = SupabaseCustomerAfterSalesRepository(port: port);
    final input = _input(canContinue: () => mounted);
    final pending = repo.uploadEvidence(caseId: _case, input: input);
    await Future<void>.delayed(Duration.zero);
    mounted = false;
    port.uploadBarrier!.complete();
    await expectLater(pending, throwsA(isA<CustomerAfterSalesException>()));
    expect(port.registers, 0);
  });

  test(
    'ACK ticket malformato mantiene ambiguità senza nuova prenotazione',
    () async {
      final port = _Port()..malformedTicket = true;
      final repo = SupabaseCustomerAfterSalesRepository(port: port);
      final input = _input();
      for (var attempt = 0; attempt < 2; attempt++) {
        await expectLater(
          repo.uploadEvidence(caseId: _case, input: input),
          throwsA(isA<CustomerAfterSalesException>()),
        );
      }
      expect(port.tickets, 1);
      expect(port.uploads, 0);
    },
  );

  test(
    'upload non memorizzato rinnova solo il ticket scaduto della stessa pratica',
    () async {
      var now = DateTime.utc(2026, 10, 12);
      final port = _Port()
        ..expiresAt = now.add(const Duration(minutes: 15))
        ..failWithoutObject = true;
      final repo = SupabaseCustomerAfterSalesRepository(
        port: port,
        now: () => now,
      );
      final input = _input();
      await expectLater(
        repo.uploadEvidence(caseId: _case, input: input),
        throwsA(isA<CustomerAfterSalesException>()),
      );
      expect(port.tickets, 1);
      now = now.add(const Duration(minutes: 21));
      port.expiresAt = now.add(const Duration(minutes: 15));
      port.failWithoutObject = false;
      expect(await repo.uploadEvidence(caseId: _case, input: input), _evidence);
      expect(port.tickets, 2);
      expect(port.uploads, 2);
      expect(port.caseIds.toSet(), {_case});
    },
  );
}

class _Port
    implements CustomerAfterSalesPort, CustomerAfterSalesEvidenceReceiptPort {
  String? owner = _owner;
  @override
  String? get currentOwnerId => owner;
  bool loseUploadAck = false,
      loseRegisterAck = false,
      wrongReceiptOwner = false,
      malformedTicket = false,
      failWithoutObject = false;
  DateTime expiresAt = DateTime.utc(2099);
  Completer<void>? uploadBarrier;
  int tickets = 0, uploads = 0, registers = 0;
  bool stored = false, registered = false;
  String? registeredPath;
  String? path;
  final caseIds = <String>[];

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    caseIds.add(parameters['p_case_id']! as String);
    if (function == 'customer_after_sales_evidence_upload_ticket_v1') {
      tickets++;
      final ticketId = '${_ticket.substring(0, _ticket.length - 1)}$tickets';
      path = '$_owner/$_case/$ticketId.png';
      return {
        'apiVersion': 'customer-after-sales.v1',
        'status': 'ok',
        if (!malformedTicket) ...{
          'ticketId': ticketId,
          'objectPath': path,
          'expiresAt': expiresAt.toIso8601String(),
        },
      };
    }
    expect(function, 'customer_after_sales_evidence_register_v1');
    expect(parameters['p_object_path'], path);
    registers++;
    if (!stored || registered) {
      return {
        'apiVersion': 'customer-after-sales.v1',
        'status': 'invalid_evidence',
      };
    }
    registered = true;
    registeredPath = path;
    if (loseRegisterAck) {
      loseRegisterAck = false;
      throw const SocketException('Risposta sintetica persa');
    }
    return {
      'apiVersion': 'customer-after-sales.v1',
      'status': 'pending_scan',
      'evidenceId': _evidence,
    };
  }

  @override
  Future<void> uploadPrivate({
    required String objectPath,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    uploads++;
    expect(objectPath, path);
    await uploadBarrier?.future;
    if (failWithoutObject) {
      throw const SocketException('Trasporto sintetico senza commit');
    }
    stored = true;
    if (loseUploadAck) {
      loseUploadAck = false;
      throw const SocketException('Risposta sintetica persa');
    }
  }

  @override
  Future<Object?> readEvidenceReceipt({
    required String caseId,
    required String objectPath,
  }) async => registered && objectPath == registeredPath
      ? {
          'id': _evidence,
          'case_id': _case,
          'object_path': registeredPath,
          'user_id': wrongReceiptOwner
              ? '10000000-0000-4000-8000-000000000002'
              : _owner,
          'scan_status': 'pending_scan',
        }
      : null;
}
