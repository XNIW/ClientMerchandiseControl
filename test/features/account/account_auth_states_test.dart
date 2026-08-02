import 'dart:async';
import 'dart:ui' as ui;

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/backend/secure_supabase_auth_storage.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/presentation/account_screen.dart';
import 'package:client_merchandise_control/features/auth/application/auth_providers.dart';
import 'package:client_merchandise_control/features/auth/data/auth_callback_source.dart';
import 'package:client_merchandise_control/features/auth/domain/auth_repository.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _WidgetAuthRepository repository;
  late _WidgetCallbackSource source;

  setUp(() {
    repository = _WidgetAuthRepository();
    source = _WidgetCallbackSource();
  });

  tearDown(() async {
    await repository.dispose();
    await source.dispose();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(_enabledConfig()),
        authRepositoryFactoryProvider.overrideWithValue(
          (config) async => repository,
        ),
        authCallbackSourceProvider.overrideWithValue(source),
      ],
      child: MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        theme: AppTheme.light(),
        home: const Scaffold(body: AccountScreen()),
      ),
    );
  }

  testWidgets('guest abilita Google e rende cancellazione/retry accessibili', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AccountScreen)),
    );

    final google = tester.widget<FilledButton>(
      find.byKey(const ValueKey('account-google-button')),
    );
    expect(google.onPressed, isNotNull);
    expect(find.text(l10n.accountGoogleComingSoon), findsNothing);

    await tester.tap(find.byKey(const ValueKey('account-google-button')));
    await tester.pump();
    await tester.pump();
    expect(find.text(l10n.accountSigningInTitle), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final cancelSize = tester.getSize(
      find.byKey(const ValueKey('account-auth-secondary')),
    );
    expect(cancelSize.width, greaterThanOrEqualTo(48));
    expect(cancelSize.height, greaterThanOrEqualTo(48));
    final cancelSemantics = tester
        .getSemantics(find.byKey(const ValueKey('account-auth-secondary')))
        .getSemanticsData();
    expect(cancelSemantics.label, contains(l10n.accountCancelSignIn));
    expect(cancelSemantics.hasAction(ui.SemanticsAction.tap), isTrue);

    await tester.tap(find.byKey(const ValueKey('account-auth-secondary')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.accountCancelledTitle), findsOneWidget);
    final retry = find.byKey(const ValueKey('account-auth-primary'));
    expect(retry, findsOneWidget);
    final retrySemantics = tester.getSemantics(retry).getSemanticsData();
    expect(retrySemantics.label, contains(l10n.accountRetry));
    expect(retrySemantics.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(repository.clearPendingCalls, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('callback fake mostra customer bounded e logout', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-google-button')));
    await tester.pump();
    await tester.pump();
    source.emit(
      Uri.parse('${AppConfig.allowedAuthRedirectUri}?code=widget-fake-code'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Safe Customer'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-session-status')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-avatar-fallback')),
      findsOneWidget,
    );
    expect(find.byType(Image), findsNothing);

    await tester.tap(find.byKey(const ValueKey('account-logout-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-google-button')), findsOneWidget);
    expect(repository.signOutCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signingOut disabilita logout e mostra progress', (tester) async {
    repository.currentCustomer = _customer();
    final signOut = Completer<void>();
    repository.signOutCompleter = signOut;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-logout-button')));
    await tester.pump();

    final logout = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('account-logout-button')),
    );
    expect(logout.onPressed, isNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('account-logout-button')),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    signOut.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('account-google-button')), findsOneWidget);
  });

  testWidgets('errore browser offre retry manuale senza loop', (tester) async {
    repository.launchResult = false;
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AccountScreen)),
    );

    await tester.tap(find.byKey(const ValueKey('account-google-button')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.accountAuthErrorTitle), findsOneWidget);
    expect(find.text(l10n.accountAuthBrowserLaunchFailed), findsOneWidget);
    expect(repository.launchCalls, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(repository.launchCalls, 1);
  });

  testWidgets('storage non disponibile fallisce chiuso e senza retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_enabledConfig()),
          authRepositoryFactoryProvider.overrideWithValue((config) async {
            throw const AuthStorageException(
              'secure_storage_initialization_failed',
            );
          }),
          authCallbackSourceProvider.overrideWithValue(source),
        ],
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(body: AccountScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AccountScreen)),
    );

    expect(find.text(l10n.accountConfigurationErrorTitle), findsOneWidget);
    expect(find.text(l10n.accountAuthSecureStorageUnavailable), findsOneWidget);
    expect(find.byKey(const ValueKey('account-auth-primary')), findsNothing);
  });

  testWidgets('stati Auth rifluiscono a 200% senza overflow', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(320, 568));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    final google = find.byKey(const ValueKey('account-google-button'));
    await tester.ensureVisible(google);
    await tester.pump();
    await tester.tap(google);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('account-auth-status')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

AppConfig _enabledConfig() {
  return AppConfig.fromValues(
    appEnvironment: 'staging',
    supabaseUrl: 'https://project.example.invalid',
    supabasePublishableKey: 'sb_publishable_test_key',
    authRedirectUri: AppConfig.allowedAuthRedirectUri,
    googleAuthEnabled: 'true',
    storefrontShopSlug: 'storefront-test',
  );
}

AuthenticatedCustomer _customer() {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: 'widget-subject',
    email: 'customer@example.test',
    metadata: const {'name': 'Safe Customer'},
  );
}

final class _WidgetCallbackSource implements AuthCallbackSource {
  final StreamController<Uri> _callbacks = StreamController<Uri>.broadcast();

  @override
  Stream<Uri> get callbacks => _callbacks.stream;

  void emit(Uri callback) => _callbacks.add(callback);

  @override
  Future<void> dispose() async {
    if (!_callbacks.isClosed) {
      await _callbacks.close();
    }
  }
}

final class _WidgetAuthRepository implements AuthRepository {
  final StreamController<AuthSessionEvent> _events =
      StreamController<AuthSessionEvent>.broadcast();

  @override
  AuthenticatedCustomer? currentCustomer;
  bool launchResult = true;
  Completer<void>? signOutCompleter;
  int launchCalls = 0;
  int clearPendingCalls = 0;
  int signOutCalls = 0;

  @override
  Stream<AuthSessionEvent> get sessionChanges => _events.stream;

  @override
  Future<void> clearPendingOAuth() async {
    clearPendingCalls++;
  }

  @override
  Future<AuthenticatedCustomer> exchangeCodeForSession(String code) async {
    return _customer();
  }

  @override
  Future<bool> launchGoogleSignIn() async {
    launchCalls++;
    return launchResult;
  }

  @override
  Future<void> signOutLocal() async {
    signOutCalls++;
    await signOutCompleter?.future;
  }

  Future<void> dispose() async {
    if (!_events.isClosed) {
      await _events.close();
    }
  }
}
