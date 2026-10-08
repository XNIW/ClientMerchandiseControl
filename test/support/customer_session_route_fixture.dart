import 'dart:async';

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/orders/application/customer_order_providers.dart';
import 'package:client_merchandise_control/features/orders/domain/customer_order_repository.dart';
import 'package:client_merchandise_control/features/storefront/application/storefront_providers.dart';
import 'package:client_merchandise_control/features/storefront/cache/storefront_cache_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/account/customer_account_test_support.dart';
import '../features/orders/customer_order_test_support.dart';

const routeFixtureOwnerA = orderTestOwner;
const routeFixtureOwnerB = '10000000-0000-4000-8000-000000028002';

/// Sorgenti sintetiche; AuthController, appRouter e ClientApp sono quelli reali.
Future<({ProviderContainer container, RouteFixtureAuthRepository auth})>
openCustomerSessionRoute(
  WidgetTester tester, {
  required String location,
  CustomerOrderRepository? orderRepository,
  List<Override> overrides = const [],
}) async {
  final auth = RouteFixtureAuthRepository();
  final callbacks = _CallbackSource();
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.authFlowTest()),
      authRepositoryFactoryProvider.overrideWithValue((_) async => auth),
      authCallbackSourceProvider.overrideWithValue(callbacks),
      customerAccountRepositoryProvider.overrideWithValue(
        FakeCustomerAccountRepository(),
      ),
      customerOrderRepositoryProvider.overrideWithValue(
        orderRepository ?? FakeCustomerOrderRepository(),
      ),
      customerOrderCacheStoreProvider.overrideWithValue(
        MemoryCustomerOrderCacheStore(),
      ),
      customerOrderClockProvider.overrideWithValue(() => orderTestNow),
      storefrontCacheDatabaseProvider.overrideWith((ref) {
        final database = StorefrontCacheDatabase(NativeDatabase.memory());
        ref.onDispose(database.close);
        return database;
      }),
      ...overrides,
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    container.dispose();
    await auth.dispose();
    await callbacks.dispose();
  });
  container.read(authControllerProvider);
  for (var attempt = 0; attempt < 20; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (container.read(authControllerProvider) is AuthAuthenticated) break;
  }
  expect(container.read(authControllerProvider), isA<AuthAuthenticated>());
  container.read(appRouterProvider).go(location);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ClientMerchandiseControlApp(locale: Locale('en')),
    ),
  );
  // Le risposte lasciate pendenti intenzionalmente non consentono pumpAndSettle.
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  return (container: container, auth: auth);
}

final class RouteFixtureAuthRepository implements AuthRepository {
  final _events = StreamController<AuthSessionEvent>.broadcast();

  @override
  AuthenticatedCustomer? currentCustomer = _customer(routeFixtureOwnerA);

  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  void signIn(String owner) {
    currentCustomer = _customer(owner);
    _events.add(
      AuthSessionEvent(
        type: AuthSessionEventType.signedIn,
        customer: currentCustomer,
      ),
    );
  }

  void expire() {
    currentCustomer = null;
    _events.add(
      const AuthSessionEvent(
        type: AuthSessionEventType.signedOut,
        customer: null,
        signOutReason: AuthSignOutReason.sessionExpired,
      ),
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

  Future<void> dispose() => _events.close();

  static AuthenticatedCustomer _customer(String owner) =>
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: owner,
        email: null,
        metadata: const {},
      );
}

final class _CallbackSource implements AuthCallbackSource {
  final _events = StreamController<Uri>.broadcast();
  @override
  Stream<Uri> get callbacks => _events.stream;
  @override
  Future<void> dispose() => _events.close();
}
