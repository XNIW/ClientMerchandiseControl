import 'dart:async';

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/account/presentation/account_screen.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../orders/customer_order_test_support.dart';
import 'customer_account_test_support.dart';

const ownerB = '00000000-0000-4000-8000-000000021002';
AuthenticatedCustomer user(String owner) =>
    AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: owner,
      email: null,
      metadata: const {},
    );

void main() {
  testWidgets(
    'same-owner AuthController refresh preserves address ACK and releases busy state',
    (tester) async {
      final rig = await openAccount(tester);
      final controller = rig.container.read(
        customerAccountControllerProvider.notifier,
      );
      final barrier = Completer<void>();
      rig.account.addressMutationBarrier = barrier;
      final pending = controller.createAddress(testCustomerAddress().toDraft());
      await tester.pump();
      expect(rig.account.createAddressAttempts, 1);
      rig.auth.signIn(user(testCustomerSubject));
      await tester.idle();
      await tester.pump();
      barrier.complete();
      final result = await pending;
      await tester.pump();
      final state = rig.container.read(customerAccountControllerProvider);
      expect(result, isNotNull);
      expect(state.isMutating, isFalse);
    },
  );
  testWidgets(
    'real AuthController and /account route latch opening A-B-A without forced identity reads',
    (tester) async {
      final rig = await openAccount(tester);
      final add = find.byKey(const ValueKey('customer-address-add'));
      await tester.ensureVisible(add);
      await tester.tap(add);
      rig.auth.signIn(user(ownerB));
      rig.auth.signIn(user(testCustomerSubject));
      await tester.idle();
      await tester.pumpAndSettle();
      expect(
        (rig.container.read(authControllerProvider) as AuthAuthenticated)
            .customer
            .subjectId,
        testCustomerSubject,
      );
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'real /account export opening cannot reveal owner A after owner B',
    (tester) async {
      final rig = await openAccount(tester);
      final export = find.byKey(const ValueKey('customer-data-export'));
      await tester.ensureVisible(export);
      await tester.tap(export);
      // Export e push completati, prima del primo frame del dialogo.
      await tester.idle();
      rig.auth.signIn(user(ownerB));
      await tester.idle();
      await tester.pumpAndSettle();
      expect(
        (rig.container.read(authControllerProvider) as AuthAuthenticated)
            .customer
            .subjectId,
        ownerB,
      );
      expect(
        find.byKey(const ValueKey('customer-export-dialog')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('export opening latches A-B-A before the first frame', (
    tester,
  ) async {
    final rig = await openAccount(tester);
    final export = find.byKey(const ValueKey('customer-data-export'));
    await tester.ensureVisible(export);
    await tester.tap(export);
    await tester.idle();
    rig.auth.signIn(user(ownerB));
    rig.auth.signIn(user(testCustomerSubject));
    await tester.idle();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('customer-export-dialog')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final returnToOwnerA in [false, true]) {
    testWidgets(
      'confirmation opening rejects account change without mutation, return to A: $returnToOwnerA',
      (tester) async {
        final rig = await openAccount(tester);
        final request = find.byKey(const ValueKey('customer-deletion-request'));
        await tester.ensureVisible(request);
        await tester.tap(request);
        rig.auth.signIn(user(ownerB));
        if (returnToOwnerA) rig.auth.signIn(user(testCustomerSubject));
        await tester.idle();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-confirm-action')),
          findsNothing,
        );
        expect(rig.account.requestDeletionCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'invalidated mounted confirmation cannot invoke destructive action before next frame',
    (tester) async {
      final rig = await openAccount(tester);
      final request = find.byKey(const ValueKey('customer-deletion-request'));
      await tester.ensureVisible(request);
      await tester.tap(request);
      await tester.pumpAndSettle();
      final staleConfirm = tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('customer-confirm-action')),
          )
          .onPressed!;
      rig.auth.signIn(user(ownerB));
      await tester.idle();
      // Il callback resta catturato dal frame precedente; il risultato del dialogo
      // deve essere rifiutato dal latch anche prima del successivo rebuild.
      staleConfirm();
      await tester.pumpAndSettle();
      expect(rig.account.requestDeletionCalls, 0);
      expect(
        find.byKey(const ValueKey('customer-confirm-action')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Future<
  ({
    ProviderContainer container,
    SessionRepository auth,
    FakeCustomerAccountRepository account,
  })
>
openAccount(WidgetTester tester) async {
  final auth = SessionRepository(user(testCustomerSubject));
  final source = CallbackSource();
  final account = FakeCustomerAccountRepository();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.authFlowTest()),
      authRepositoryFactoryProvider.overrideWithValue((_) async => auth),
      authCallbackSourceProvider.overrideWithValue(source),
      customerAccountRepositoryProvider.overrideWithValue(account),
      customerOrderRepositoryProvider.overrideWithValue(
        FakeCustomerOrderRepository(),
      ),
      customerOrderCacheStoreProvider.overrideWithValue(
        MemoryCustomerOrderCacheStore(),
      ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
    await auth.dispose();
    await source.dispose();
  });
  container.read(authControllerProvider);
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (container.read(authControllerProvider) is AuthAuthenticated) break;
  }
  expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
  final router = container.read(appRouterProvider);
  router.go(AppRoutes.accountLocation);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ClientMerchandiseControlApp(locale: Locale('en')),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(AccountScreen), findsOneWidget);
  final settings = find.byKey(
    const ValueKey('account-personal-settings-section'),
  );
  await tester.ensureVisible(settings);
  await tester.tap(settings);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('customer-account-ready')), findsOneWidget);
  return (container: container, auth: auth, account: account);
}

class CallbackSource implements AuthCallbackSource {
  final events = StreamController<Uri>.broadcast();
  @override
  Stream<Uri> get callbacks => events.stream;
  @override
  Future<void> dispose() => events.close();
}

class SessionRepository implements AuthRepository {
  SessionRepository(this.currentCustomer);
  final events = StreamController<AuthSessionEvent>.broadcast();
  @override
  AuthenticatedCustomer? currentCustomer;
  @override
  Stream<AuthSessionEvent> get sessionChanges => events.stream;
  void signIn(AuthenticatedCustomer customer) {
    currentCustomer = customer;
    events.add(
      AuthSessionEvent(type: AuthSessionEventType.signedIn, customer: customer),
    );
  }

  @override
  Future<void> beginSignOut() async {}
  @override
  Future<void> completeSignOut() => signOutLocal();
  @override
  Future<void> signOutLocal() async {
    currentCustomer = null;
  }

  @override
  Future<void> retryPendingRemoteRevocations() async {}
  @override
  Future<void> clearPendingOAuth() async {}
  @override
  Future<bool> launchGoogleSignIn() async => true;
  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async =>
      currentCustomer!;
  Future<void> dispose() => events.close();
}
