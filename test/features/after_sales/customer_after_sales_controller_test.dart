import 'dart:async';
import 'dart:typed_data';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/after_sales/application/customer_after_sales_controller.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _ownerA = '00000000-0000-4000-8000-000000000001';
const _ownerB = '00000000-0000-4000-8000-000000000002';
const _order = '84000000-0000-4000-8000-000000000001';
const _orderItem = '85000000-0000-4000-8000-000000000001';
const _caseId = '86000000-0000-4000-8000-000000000001';
const _idempotencyKey = '87000000-0000-4000-8000-000000000001';

void main() {
  test(
    'refresh stesso owner senza schermata conserva la pratica incompleta',
    () async {
      final repository = _Repository();
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _customer(_ownerA),
      );
      final container = _container(repository, identity);
      addTearDown(container.dispose);
      final subscription = container.listen(
        customerAfterSalesControllerProvider,
        (_, _) {},
      );
      await _settle();
      final controller = container.read(
        customerAfterSalesControllerProvider.notifier,
      );
      final file = CustomerAfterSalesLocalAttachment(
        name: 'originale.png',
        extension: 'png',
        mimeType: 'image/png',
        readBytes: () async => throw StateError('File sintetico assente'),
      );
      await controller.submitWithEvidence(
        draft: _draft(),
        attachments: [file],
        canContinue: () => true,
      );
      subscription.close();
      container
          .read(identity.notifier)
          .state = AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: _ownerA,
        email: null,
        metadata: const {'full_name': 'Profilo sintetico aggiornato'},
      );
      // Nessun read/listener finché la schermata viene riaperta.
      await _settle();
      final reopened = container.read(
        customerAfterSalesControllerProvider.notifier,
      );
      expect(reopened.openedCaseForOrder(_order)?.id, _caseId);
      expect(reopened.attachmentsFor(_caseId).single, same(file));
      await reopened.submitWithEvidence(
        draft: _draft(),
        attachments: [],
        canContinue: () => true,
      );
      expect(repository.idempotencyKeys, hasLength(1));
    },
  );
  test('refresh identità stesso owner conserva recovery e bozza', () async {
    final repository = _Repository();
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _customer(_ownerA),
    );
    final container = _container(repository, identity);
    addTearDown(container.dispose);
    container.listen(customerAfterSalesControllerProvider, (_, _) {});
    await _settle();
    final controller = container.read(
      customerAfterSalesControllerProvider.notifier,
    );
    final file = CustomerAfterSalesLocalAttachment(
      name: 'originale.png',
      extension: 'png',
      mimeType: 'image/png',
      readBytes: () async => throw StateError('File sintetico assente'),
    );
    await controller.submitWithEvidence(
      draft: _draft(),
      attachments: [file],
      canContinue: () => true,
    );
    container.read(identity.notifier).state = _customer(_ownerA);
    container.read(customerAfterSalesControllerProvider);
    await _settle();
    expect(controller.openedCaseForOrder(_order)?.id, _caseId);
    expect(controller.attachmentsFor(_caseId).single.name, 'originale.png');
  });
  test('pratica incompleta poi chiusa non blocca nuova richiesta', () async {
    final repository = _Repository();
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _customer(_ownerA),
    );
    final container = _container(repository, identity);
    addTearDown(container.dispose);
    container.listen(customerAfterSalesControllerProvider, (_, _) {});
    await _settle();
    final controller = container.read(
      customerAfterSalesControllerProvider.notifier,
    );
    final file = CustomerAfterSalesLocalAttachment(
      name: 'perso.png',
      extension: 'png',
      mimeType: 'image/png',
      readBytes: () async => throw StateError('File sintetico perso'),
    );
    final created = await controller.submitWithEvidence(
      draft: _draft(),
      attachments: [file],
      canContinue: () => true,
    );
    expect(controller.openedCaseForOrder(_order)?.id, _caseId);
    await controller.cancel(created!);
    expect(controller.openedCaseForOrder(_order), isNull);
    await controller.submitWithEvidence(
      draft: _draft(),
      attachments: [],
      canContinue: () => true,
    );
    expect(repository.idempotencyKeys, hasLength(2));
  });
  test(
    'intera sequenza protegge lettura file, refresh e secondo invio',
    () async {
      final repository = _Repository();
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _customer(_ownerA),
      );
      final container = _container(repository, identity);
      addTearDown(container.dispose);
      container.listen(customerAfterSalesControllerProvider, (_, _) {});
      await _settle();
      final reader = Completer<Uint8List>();
      final file = CustomerAfterSalesLocalAttachment(
        name: 'originale.png',
        extension: 'png',
        mimeType: 'image/png',
        readBytes: () => reader.future,
      );
      final controller = container.read(
        customerAfterSalesControllerProvider.notifier,
      );
      final pending = controller.submitWithEvidence(
        draft: _draft(),
        attachments: [file],
        canContinue: () => true,
      );
      await _settle();
      expect(
        container.read(customerAfterSalesControllerProvider).isMutating,
        isTrue,
      );
      await controller.refresh();
      expect(
        await controller.submitWithEvidence(
          draft: _draft(),
          attachments: [file],
          canContinue: () => true,
        ),
        isNull,
      );
      expect(repository.idempotencyKeys, hasLength(1));
      reader.complete(Uint8List.fromList([1]));
      expect((await pending)?.id, _caseId);
      expect(file.status, CustomerAfterSalesAttachmentStatus.confirmed);
      expect(file.input, isNull, reason: 'I byte ricevuti vengono liberati');
      expect(repository.uploadCaseIds, [_caseId]);
      expect(
        controller.openedCaseForOrder(_order),
        isNull,
        reason:
            'Una nuova richiesta legittima resta possibile dopo completamento',
      );
      await controller.submitWithEvidence(
        draft: _draft(),
        attachments: [],
        canContinue: () => true,
      );
      expect(repository.idempotencyKeys, hasLength(2));
    },
  );

  test(
    'lista precedente non cancella ACK e retry conserva stessa pratica',
    () async {
      final repository = _Repository()
        ..listBarrier = Completer<List<CustomerAfterSalesCase>>();
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _customer(_ownerA),
      );
      final container = _container(repository, identity);
      addTearDown(container.dispose);
      container.listen(customerAfterSalesControllerProvider, (_, _) {});
      await _settle();
      var fails = true;
      final file = CustomerAfterSalesLocalAttachment(
        name: 'mancante.png',
        extension: 'png',
        mimeType: 'image/png',
        readBytes: () async {
          if (fails) throw StateError('File sintetico assente');
          return Uint8List.fromList([1]);
        },
      );
      final controller = container.read(
        customerAfterSalesControllerProvider.notifier,
      );
      await controller.submitWithEvidence(
        draft: _draft(),
        attachments: [file],
        canContinue: () => true,
      );
      repository.listBarrier!.complete([]);
      await _settle();
      expect(
        container.read(customerAfterSalesControllerProvider).cases.single.id,
        _caseId,
      );
      expect(file.status, CustomerAfterSalesAttachmentStatus.fileUnavailable);
      // Cambiare pratica non perde il checkpoint della prima.
      const other = '86000000-0000-4000-8000-000000000002';
      controller.selectAttachments(other, [
        CustomerAfterSalesLocalAttachment(
          name: 'altro.png',
          extension: 'png',
          mimeType: 'image/png',
          readBytes: () async => Uint8List.fromList([2]),
        ),
      ]);
      expect(controller.attachmentsFor(_caseId).single.name, 'mancante.png');
      expect(controller.openedCaseForOrder(_order)?.id, _caseId);
      fails = false;
      await controller.completeAttachments(_caseId, () => true);
      expect(repository.idempotencyKeys, hasLength(1));
      expect(repository.uploadCaseIds, [_caseId]);
    },
  );

  for (final change in ['account', 'navigation', 'dispose']) {
    test('risposta lettura tardiva fermata dopo $change', () async {
      final repository = _Repository();
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _customer(_ownerA),
      );
      final container = _container(repository, identity);
      container.listen(customerAfterSalesControllerProvider, (_, _) {});
      await _settle();
      var current = true;
      final reader = Completer<Uint8List>();
      final file = CustomerAfterSalesLocalAttachment(
        name: 'privato.png',
        extension: 'png',
        mimeType: 'image/png',
        readBytes: () => reader.future,
      );
      final controller = container.read(
        customerAfterSalesControllerProvider.notifier,
      );
      final pending = controller.submitWithEvidence(
        draft: _draft(),
        attachments: [file],
        canContinue: () => current,
      );
      await _settle();
      if (change == 'account') {
        container.read(identity.notifier).state = _customer(_ownerB);
        container.read(customerAfterSalesControllerProvider);
        await _settle();
        container.read(identity.notifier).state = _customer(_ownerA);
        container.read(customerAfterSalesControllerProvider);
      } else if (change == 'dispose') {
        container.dispose();
      } else {
        current = false;
      }
      reader.complete(Uint8List.fromList([1]));
      await pending;
      expect(repository.uploadCaseIds, isEmpty);
      if (change != 'dispose') container.dispose();
    });
  }
  test('refresh durante create conserva mutex e ACK della pratica', () async {
    final repository = _Repository()..createBarrier = Completer<void>();
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _customer(_ownerA),
    );
    final container = _container(repository, identity);
    addTearDown(container.dispose);
    final subscription = container.listen(
      customerAfterSalesControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await _settle();
    final controller = container.read(
      customerAfterSalesControllerProvider.notifier,
    );
    final pending = controller.create(_draft());
    await controller.refresh();
    expect(
      container.read(customerAfterSalesControllerProvider).isMutating,
      isTrue,
    );
    expect(await controller.create(_draft()), isNull);
    expect(repository.idempotencyKeys, hasLength(1));
    repository.createBarrier!.complete();
    expect((await pending)?.id, _caseId);
  });
  test(
    'account switch scarta risposta create del proprietario precedente',
    () async {
      final repository = _Repository()..createBarrier = Completer<void>();
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _customer(_ownerA),
      );
      final container = _container(repository, identity);
      addTearDown(container.dispose);
      final subscription = container.listen(
        customerAfterSalesControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await _settle();

      final pending = container
          .read(customerAfterSalesControllerProvider.notifier)
          .create(_draft());
      await _settle();
      container.read(identity.notifier).state = _customer(_ownerB);
      container.read(customerAfterSalesControllerProvider);
      await _settle();
      repository.createBarrier!.complete();

      expect(await pending, isNull);
      await _settle();
      expect(
        container.read(customerAfterSalesControllerProvider).cases,
        isEmpty,
      );
    },
  );

  test('create dopo dispose scarta la risposta senza accedere a ref', () async {
    final repository = _Repository()..createBarrier = Completer<void>();
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _customer(_ownerA),
    );
    final container = _container(repository, identity);
    container.listen(customerAfterSalesControllerProvider, (_, _) {});
    await _settle();
    final pending = container
        .read(customerAfterSalesControllerProvider.notifier)
        .create(_draft());
    container.dispose();
    repository.createBarrier!.complete();
    expect(await pending, isNull);
  });

  test('retry create riusa la stessa idempotency key dopo timeout', () async {
    final repository = _Repository()..failFirstCreate = true;
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _customer(_ownerA),
    );
    final container = _container(repository, identity);
    addTearDown(container.dispose);
    final subscription = container.listen(
      customerAfterSalesControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await _settle();
    final controller = container.read(
      customerAfterSalesControllerProvider.notifier,
    );

    expect(await controller.create(_draft()), isNull);
    expect(await controller.create(_draft()), isNotNull);
    expect(repository.idempotencyKeys, [_idempotencyKey, _idempotencyKey]);
  });
}

ProviderContainer _container(
  _Repository repository,
  StateProvider<AuthenticatedCustomer?> identity,
) => ProviderContainer(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://staging.example.invalid',
        supabasePublishableKey: 'sb_publishable_staging',
        authRedirectUri: AppConfig.allowedAuthRedirectUri,
        googleAuthEnabled: 'false',
        storefrontShopSlug: 'storefront-test',
      ),
    ),
    customerAccountIdentityProvider.overrideWith((ref) => ref.watch(identity)),
    customerAfterSalesRepositoryProvider.overrideWithValue(repository),
    customerOrderIdempotencyKeyFactoryProvider.overrideWithValue(
      () => _idempotencyKey,
    ),
  ],
);

AuthenticatedCustomer _customer(String subjectId) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: subjectId,
      email: null,
      metadata: const {},
    );

CustomerAfterSalesDraft _draft() => CustomerAfterSalesDraft(
  orderId: _order,
  type: CustomerAfterSalesType.orderProblem,
  reason: CustomerAfterSalesReason.damaged,
  note: 'Nota sintetica',
  lines: const [
    CustomerAfterSalesLineDraft(orderItemId: _orderItem, quantity: 1),
  ],
);

CustomerAfterSalesCase _case({
  CustomerAfterSalesStatus status = CustomerAfterSalesStatus.submitted,
}) => CustomerAfterSalesCase(
  id: _caseId,
  caseCode: 'CS-1234567890ABCDEF',
  orderId: _order,
  type: CustomerAfterSalesType.orderProblem,
  status: status,
  reason: CustomerAfterSalesReason.damaged,
  note: 'Nota sintetica',
  version: 1,
  submittedAt: DateTime.utc(2026, 8, 23),
  updatedAt: DateTime.utc(2026, 8, 23),
  lines: const [
    CustomerAfterSalesLine(
      id: '88000000-0000-4000-8000-000000000001',
      orderItemId: _orderItem,
      quantity: 1,
      name: 'Prodotto storico',
    ),
  ],
  evidence: const [],
  timeline: [
    CustomerAfterSalesEvent(
      id: '89000000-0000-4000-8000-000000000001',
      version: 1,
      status: status,
      actorKind: 'customer',
      noteKey: 'afterSales.submitted',
      createdAt: DateTime.utc(2026, 8, 23),
    ),
  ],
);

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _Repository implements CustomerAfterSalesRepository {
  Completer<void>? createBarrier;
  Completer<List<CustomerAfterSalesCase>>? listBarrier;
  final uploadCaseIds = <String>[];
  bool failFirstCreate = false;
  CustomerAfterSalesCase? currentCase;
  final List<String> idempotencyKeys = [];

  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) async =>
      listBarrier == null
      ? (currentCase == null ? const [] : [currentCase!])
      : listBarrier!.future;

  @override
  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId) =>
      throw UnimplementedError();

  @override
  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey);
    if (failFirstCreate) {
      failFirstCreate = false;
      throw const CustomerAfterSalesException('timeout');
    }
    await createBarrier?.future;
    return currentCase = _case();
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) async => currentCase = _case(status: CustomerAfterSalesStatus.closed);

  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    expect(input.bytes, isA<Uint8List>());
    uploadCaseIds.add(caseId);
    return '90000000-0000-4000-8000-000000000001';
  }
}
