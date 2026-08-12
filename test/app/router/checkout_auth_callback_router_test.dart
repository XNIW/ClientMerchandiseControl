import 'dart:async';

import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_controller.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/application/cart_state.dart';
import 'package:client_merchandise_control/features/cart/domain/cart_models.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../features/checkout/checkout_test_support.dart';

void main() {
  testWidgets('callback Google conserva la route checkout', (tester) async {
    final repository = _RouterAuthRepository();
    final source = _RouterCallbackSource();
    final accountCart = checkoutTestCart();
    final guestCart = CustomerCartSnapshot(
      shopSlug: accountCart.shopSlug,
      version: 0,
      items: accountCart.items,
      source: CartSource.guest,
      quoteStatus: CartQuoteStatus.indicative,
      requiresCustomerReview: false,
      subtotalClp: accountCart.subtotalClp,
      idempotent: true,
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(_config()),
        authRepositoryFactoryProvider.overrideWithValue(
          (config) async => repository,
        ),
        authCallbackSourceProvider.overrideWithValue(source),
        checkoutCartStateProvider.overrideWithValue(
          CartState(
            status: CartViewStatus.ready,
            isAuthenticated: false,
            snapshot: guestCart,
          ),
        ),
        checkoutAccountStateProvider.overrideWithValue(
          const CustomerAccountState.signedOut(),
        ),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await source.dispose();
      await repository.dispose();
    });
    final router = container.read(appRouterProvider);
    router.go(AppRoutes.checkoutLocation);

    await tester.pumpWidget(_app(container, router));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.checkoutLocation);
    await tester.tap(find.byKey(const ValueKey('checkout-google-sign-in')));
    await tester.pump();
    await tester.pump();
    expect(repository.launchCalls, 1);

    source.emit(
      Uri.parse('${AppConfig.allowedAuthRedirectUri}?code=checkout-code'),
    );
    for (
      var attempt = 0;
      attempt < 50 && repository.exchangeCalls == 0;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    await tester.pump();

    expect(repository.exchangeCalls, 1);
    expect(router.state.uri.path, AppRoutes.checkoutLocation);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(ProviderContainer container, GoRouter router) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('es', 'CL'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

AppConfig _config() => AppConfig.authFlowTest(
  supabaseUrl: 'https://staging.example.invalid',
  supabasePublishableKey: 'sb_publishable_staging',
);

final class _RouterCallbackSource implements AuthCallbackSource {
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get callbacks => _controller.stream;

  void emit(Uri uri) => _controller.add(uri);

  @override
  Future<void> dispose() => _controller.close();
}

final class _RouterAuthRepository implements AuthRepository {
  @override
  Future<void> beginSignOut() async {}

  @override
  Future<void> completeSignOut() => signOutLocal();

  @override
  Future<void> retryPendingRemoteRevocations() async {}

  final StreamController<AuthSessionEvent> _events =
      StreamController<AuthSessionEvent>.broadcast();

  @override
  AuthenticatedCustomer? currentCustomer;
  int launchCalls = 0;
  int exchangeCalls = 0;

  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  @override
  Future<void> clearPendingOAuth() async {}

  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async {
    exchangeCalls++;
    currentCustomer = AuthenticatedCustomer.fromUntrustedIdentity(
      subjectId: checkoutTestOwner,
      email: 'checkout@example.invalid',
      metadata: const {'name': 'Checkout Customer'},
    );
    return currentCustomer!;
  }

  @override
  Future<bool> launchGoogleSignIn() async {
    launchCalls++;
    return true;
  }

  @override
  Future<void> signOutLocal() async {
    currentCustomer = null;
  }

  Future<void> dispose() => _events.close();
}
