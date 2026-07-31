import 'dart:async';

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/presentation/account_screen.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/cart/presentation/cart_screen.dart';
import 'package:client_merchandise_control/features/catalog/presentation/catalog_screen.dart';
import 'package:client_merchandise_control/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'callback fake, restore, logout e invalid callback restano safe',
    (tester) async {
      final repository = _IntegrationAuthRepository();
      final firstSource = _IntegrationCallbackSource();

      await tester.pumpWidget(_testApp(repository, firstSource));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('nav-account')));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('account-google-button')));
      await tester.pump();
      await tester.pump();
      expect(repository.launchCalls, 1);

      firstSource.emit(
        Uri.parse(
          '${AppConfig.allowedAuthRedirectUri}?code=integration-fake-code',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Integration Customer'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('account-session-status')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await firstSource.dispose();

      final restartSource = _IntegrationCallbackSource();
      await tester.pumpWidget(_testApp(repository, restartSource));
      await tester.pumpAndSettle();
      expect(
        find.byType(HomeScreen),
        findsOneWidget,
        reason: 'Il cold restore non deve forzare Account.',
      );
      await tester.tap(find.byKey(const ValueKey('nav-account')));
      await tester.pumpAndSettle();
      expect(find.text('Integration Customer'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('account-logout-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('account-google-button')),
        findsOneWidget,
      );
      expect(repository.signOutCalls, 1);

      await tester.tap(find.byKey(const ValueKey('account-google-button')));
      await tester.pump();
      await tester.pump();
      restartSource.emit(
        Uri.parse('invalid.scheme://auth-callback/?code=must-not-exchange'),
      );
      await tester.pumpAndSettle();
      expect(repository.exchangeCalls, 1);
      expect(find.byKey(const ValueKey('account-auth-status')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-catalog')));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-cart')));
      await tester.pumpAndSettle();
      expect(find.byType(CartScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      binding.reportData = <String, Object?>{
        'fakeGoogleLaunch': 'PASS',
        'validatedCallback': 'PASS',
        'authenticatedAccount': 'PASS',
        'coldRestoreWithoutForcedNavigation': 'PASS',
        'localLogout': 'PASS',
        'invalidCallbackNoExchange': 'PASS',
        'guestNavigationAfterAuthError': 'PASS',
        'processAlive': 'PASS',
      };

      await restartSource.dispose();
      await repository.dispose();
    },
  );
}

Widget _testApp(
  _IntegrationAuthRepository repository,
  _IntegrationCallbackSource source,
) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.fromValues(
          appEnvironment: 'staging',
          supabaseUrl: 'https://project.example.invalid',
          supabasePublishableKey: 'sb_publishable_test_key',
          authRedirectUri: AppConfig.allowedAuthRedirectUri,
          googleAuthEnabled: 'true',
        ),
      ),
      authRepositoryFactoryProvider.overrideWithValue(
        (config) async => repository,
      ),
      authCallbackSourceProvider.overrideWithValue(source),
    ],
    child: const ClientMerchandiseControlApp(locale: Locale('es')),
  );
}

AuthenticatedCustomer _integrationCustomer() {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: 'integration-subject',
    email: null,
    metadata: const {'name': 'Integration Customer'},
  );
}

final class _IntegrationCallbackSource implements AuthCallbackSource {
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get callbacks => _controller.stream;

  void emit(Uri callback) => _controller.add(callback);

  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

final class _IntegrationAuthRepository implements AuthRepository {
  final StreamController<AuthSessionEvent> _events =
      StreamController<AuthSessionEvent>.broadcast();

  @override
  AuthenticatedCustomer? currentCustomer;
  int launchCalls = 0;
  int exchangeCalls = 0;
  int signOutCalls = 0;

  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  @override
  Future<void> clearPendingOAuth() async {}

  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async {
    exchangeCalls++;
    currentCustomer = _integrationCustomer();
    return currentCustomer!;
  }

  @override
  Future<bool> launchGoogleSignIn() async {
    launchCalls++;
    return true;
  }

  @override
  Future<void> signOutLocal() async {
    signOutCalls++;
    currentCustomer = null;
  }

  Future<void> dispose() async {
    if (!_events.isClosed) {
      await _events.close();
    }
  }
}
