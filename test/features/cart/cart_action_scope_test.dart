import 'dart:async';

import 'package:client_merchandise_control/app/router/app_routes.dart';
import 'package:client_merchandise_control/core/backend/backend_health_service.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_repository.dart';
import 'package:client_merchandise_control/core/backend/backend_readiness_state.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/auth/application/auth_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_state.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_controller.dart';
import 'package:client_merchandise_control/features/cart/application/cart_providers.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_action_result.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/cart/presentation/add_to_cart_button.dart';
import 'package:client_merchandise_control/features/home/application/home_controller.dart';
import 'package:client_merchandise_control/features/reservations/application/reservation_hold_providers.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/customer_session_route_fixture.dart';
import '../reservations/reservation_hold_test_support.dart';
import 'add_to_cart_button_test.dart' as fixtures;

// AuthController, CartController e AddToCartButton sono di produzione. I soli
// repository/callback sono sintetici; nessun SDK/backend TEST è qualificato.
void main() {
  testWidgets('add con Auth reale A-B-A scarta ACK prima del nuovo frame', (
    tester,
  ) async {
    final barrier = Completer<CartRemoteResponse>();
    final remote = fixtures.Remote([barrier.future]);
    final rig = await _mount(tester, remote);
    final controller = rig.container.read(cartControllerProvider.notifier);
    final pending = controller.addProduct(fixtures.product());
    await _untilRequest(tester, remote);

    rig.auth.signIn(routeFixtureOwnerB);
    rig.auth.signIn(routeFixtureOwnerA);
    await tester.idle();
    barrier.complete(_ack());
    await tester.idle();
    final result = await pending;

    expect(result.outcome, CartActionOutcome.contextChanged);
    expect(controller.isCurrentActionResult(result), isFalse);
    await tester.pumpAndSettle();
    expect(rig.container.read(cartControllerProvider).snapshot!.items, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(remote.requests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('profilo stesso owner senza observer conserva add e ACK', (
    tester,
  ) async {
    final barrier = Completer<CartRemoteResponse>();
    final remote = fixtures.Remote([barrier.future]);
    final rig = await _mount(tester, remote);
    final controller = rig.container.read(cartControllerProvider.notifier);
    final pending = controller.addProduct(fixtures.product());
    await _untilRequest(tester, remote);
    // Nessun widget conserva un watch del carrello durante il cambio profilo.
    await tester.pumpWidget(const SizedBox.shrink());

    rig.auth.updateProfile('Cliente actualizado');
    await tester.idle();
    final auth = rig.container.read(authControllerProvider) as AuthAuthenticated;
    expect(auth.customer.subjectId, routeFixtureOwnerA);
    expect(auth.customer.displayName, 'Cliente actualizado');
    barrier.complete(_ack());
    await tester.idle();
    final result = await pending;

    expect(result.outcome, CartActionOutcome.accountConfirmed);
    expect(controller.isCurrentActionResult(result), isTrue);
    expect(rig.container.read(cartControllerProvider).snapshot!.totalQuantity, 1);
    expect(remote.requests, hasLength(1));
    await _mountButton(tester, rig.container);
    await tester.pumpAndSettle();
    expect(rig.container.read(cartControllerProvider).snapshot!.totalQuantity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cambio shop scarta ACK completato senza pump intermedio', (
    tester,
  ) async {
    final barrier = Completer<CartRemoteResponse>();
    final remote = fixtures.Remote([barrier.future]);
    final rig = await _mount(tester, remote);
    final controller = rig.container.read(cartControllerProvider.notifier);
    final pending = controller.addProduct(fixtures.product());
    await _untilRequest(tester, remote);

    rig.container.read(rig.config.notifier).state = AppConfig.authFlowTest(
      storefrontShopSlug: 'other-store',
    );
    // La risposta viene completata prima che un frame ricostruisca il consumer.
    barrier.complete(_ack());
    await tester.idle();
    final result = await pending;

    expect(result.outcome, CartActionOutcome.contextChanged);
    expect(controller.isCurrentActionResult(result), isFalse);
    await tester.pumpAndSettle();
    final cart = rig.container.read(cartControllerProvider);
    expect(cart.snapshot!.shopSlug, 'other-store');
    expect(cart.snapshot!.items, isEmpty);
    expect(remote.requests, hasLength(1));
    expect(find.byType(SnackBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<({
  ProviderContainer container,
  _ProfileAuthRepository auth,
  StateProvider<AppConfig> config,
})> _mount(WidgetTester tester, fixtures.Remote remote) async {
  final auth = _ProfileAuthRepository();
  addTearDown(auth.dispose);
  final config = StateProvider<AppConfig>((ref) => AppConfig.authFlowTest());
  final rig = await openCustomerSessionRoute(
    tester,
    location: AppRoutes.accountLocation,
    overrides: [
      appConfigProvider.overrideWith((ref) => ref.watch(config)),
      authRepositoryFactoryProvider.overrideWithValue((_) async => auth),
      customerCartRepositoryProvider.overrideWithValue(remote),
      guestCartStoreProvider.overrideWithValue(fixtures.Guest()),
      homeControllerProvider.overrideWith(_EmptyHomeController.new),
      backendReadinessRepositoryProvider.overrideWithValue(
        const _NoNetworkReadiness(),
      ),
      reservationHoldLocalStoreProvider.overrideWithValue(
        MemoryReservationHoldStore(),
      ),
      reservationHoldRepositoryProvider.overrideWithValue(
        FakeReservationHoldRepository(),
      ),
    ],
  );
  await _mountButton(tester, rig.container);
  await tester.pumpAndSettle();
  expect(rig.container.read(cartControllerProvider).snapshot!.items, isEmpty);
  return (container: rig.container, auth: auth, config: config);
}

Future<void> _mountButton(
  WidgetTester tester,
  ProviderContainer container,
) => tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('es', 'CL'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AddToCartButton(product: fixtures.product())),
    ),
  ),
);

Future<void> _untilRequest(WidgetTester tester, fixtures.Remote remote) async {
  for (var frame = 0; frame < 30; frame++) {
    if (remote.requests.isNotEmpty) {
      expect(remote.requests, hasLength(1));
      return;
    }
    await tester.pump(const Duration(milliseconds: 20));
  }
  fail('La mutation sintetica non è iniziata.');
}

CartRemoteResponse _ack() => CartRemoteResponse(
  status: CartRemoteStatus.ok,
  snapshot: fixtures.snapshot(quantity: 1, version: 5),
);

final class _EmptyHomeController extends HomeController {
  @override
  HomeState build() => const HomeState.empty();
}

final class _NoNetworkReadiness implements BackendReadinessRepository {
  const _NoNetworkReadiness();
  @override
  BackendReadinessState get initialState => BackendReadinessState.offline;
  @override
  bool get canCheck => false;
  @override
  Future<BackendReadinessState> check({
    required BackendProbeCancellation cancellation,
  }) async => BackendReadinessState.offline;
}

final class _ProfileAuthRepository implements AuthRepository {
  final _delegate = RouteFixtureAuthRepository();
  final _events = StreamController<AuthSessionEvent>.broadcast();
  @override
  AuthenticatedCustomer? currentCustomer = _customer(
    routeFixtureOwnerA,
    'Cliente inicial',
  );
  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  void signIn(String owner) {
    currentCustomer = _customer(owner, 'Cliente inicial');
    _events.add(AuthSessionEvent(
      type: AuthSessionEventType.signedIn,
      customer: currentCustomer,
    ));
  }

  void updateProfile(String name) {
    currentCustomer = _customer(currentCustomer!.subjectId, name);
    _events.add(AuthSessionEvent(
      type: AuthSessionEventType.userUpdated,
      customer: currentCustomer,
    ));
  }

  static AuthenticatedCustomer _customer(String owner, String name) =>
      AuthenticatedCustomer.fromUntrustedIdentity(
        subjectId: owner,
        email: null,
        metadata: {'name': name},
      );

  @override
  Future<void> beginSignOut() => _delegate.beginSignOut();
  @override
  Future<void> completeSignOut() => signOutLocal();
  @override
  Future<void> signOutLocal() async { currentCustomer = null; }
  @override
  Future<void> retryPendingRemoteRevocations() =>
      _delegate.retryPendingRemoteRevocations();
  @override
  Future<void> clearPendingOAuth() => _delegate.clearPendingOAuth();
  @override
  Future<bool> launchGoogleSignIn() => _delegate.launchGoogleSignIn();
  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async =>
      currentCustomer!;
  Future<void> dispose() async {
    await _events.close();
    await _delegate.dispose();
  }
}
