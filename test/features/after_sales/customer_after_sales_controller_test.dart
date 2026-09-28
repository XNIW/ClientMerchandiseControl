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

CustomerAfterSalesCase _case() => CustomerAfterSalesCase(
  id: _caseId,
  caseCode: 'CS-1234567890ABCDEF',
  orderId: _order,
  type: CustomerAfterSalesType.orderProblem,
  status: CustomerAfterSalesStatus.submitted,
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
      status: CustomerAfterSalesStatus.submitted,
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
  bool failFirstCreate = false;
  final List<String> idempotencyKeys = [];

  @override
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug}) async =>
      const [];

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
    return _case();
  }

  @override
  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  }) async => _case();

  @override
  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  }) async {
    expect(input.bytes, isA<Uint8List>());
    return '90000000-0000-4000-8000-000000000001';
  }
}
