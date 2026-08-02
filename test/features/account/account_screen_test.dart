import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/design_system/tokens/app_sizes.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/account/presentation/account_presentation_model.dart';
import 'package:client_merchandise_control/features/account/presentation/account_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const locale = Locale('es');

  Widget buildApp(Widget child) {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.fromValues())],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );
  }

  Widget buildMatrixApp(Widget child, ThemeMode themeMode) {
    return ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(AppConfig.fromValues())],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: Scaffold(body: child),
      ),
    );
  }

  Future<AppLocalizations> loadL10n() {
    return AppLocalizations.delegate.load(locale);
  }

  testWidgets('AccountScreen presenta il guest e Google fail-closed', (
    tester,
  ) async {
    final l10n = await loadL10n();

    await tester.pumpWidget(buildApp(const AccountScreen()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.accountGuestTitle), findsOneWidget);
    expect(find.text(l10n.accountGuestBenefit), findsOneWidget);
    expect(find.text(l10n.accountGoogleComingSoon), findsOneWidget);
    expect(find.byType(Form), findsNothing);

    final googleButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('account-google-button')),
    );
    expect(googleButton.onPressed, isNull);
    expect(
      find.bySemanticsLabel(l10n.accountContinueWithGoogle),
      findsOneWidget,
    );
    final googleSemantics = tester
        .getSemantics(find.bySemanticsLabel(l10n.accountContinueWithGoogle))
        .getSemanticsData();
    expect(googleSemantics.flagsCollection.isButton, isTrue);
    expect(googleSemantics.flagsCollection.isEnabled, ui.Tristate.isFalse);
    expect(googleSemantics.hasAction(ui.SemanticsAction.tap), isFalse);
    expect(find.byKey(const ValueKey('account-browse-button')), findsOneWidget);
  });

  testWidgets('guest abilita soltanto le callback esplicitamente iniettate', (
    tester,
  ) async {
    final l10n = await loadL10n();
    var googleCalls = 0;
    var browseCalls = 0;

    await tester.pumpWidget(
      buildApp(
        AccountView.guest(
          onContinueWithGoogle: () => googleCalls++,
          onBrowseAsGuest: () => browseCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('account-google-button')));
    await tester.tap(find.byKey(const ValueKey('account-browse-button')));
    await tester.pump();

    expect(googleCalls, 1);
    expect(browseCalls, 1);
    expect(find.text(l10n.accountGoogleComingSoon), findsNothing);
  });

  testWidgets('authenticated mostra identita sessione e logout', (
    tester,
  ) async {
    final l10n = await loadL10n();
    var logoutCalls = 0;

    await tester.pumpWidget(
      buildApp(
        AccountView.authenticated(
          model: AuthenticatedAccountPresentationModel(
            displayName: 'María',
            email: 'maria@example.test',
          ),
          onLogout: () => logoutCalls++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.accountAuthenticatedTitle), findsOneWidget);
    expect(find.text('María'), findsOneWidget);
    expect(find.text('maria@example.test'), findsOneWidget);
    expect(find.text(l10n.accountSessionActive), findsOneWidget);
    expect(find.byKey(const ValueKey('account-google-button')), findsNothing);
    expect(find.byType(Form), findsNothing);

    await tester.tap(find.byKey(const ValueKey('account-logout-button')));
    await tester.pump();
    expect(logoutCalls, 1);
  });

  testWidgets('authenticated localizza nome ed email mancanti', (tester) async {
    final l10n = await loadL10n();

    await tester.pumpWidget(
      buildApp(
        AccountView.authenticated(
          model: AuthenticatedAccountPresentationModel(
            displayName: '   ',
            email: '',
          ),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.accountNameFallback), findsOneWidget);
    expect(find.text(l10n.accountEmailFallback), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                l10n.accountAvatarLabel(l10n.accountNameFallback),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('account-avatar-fallback')),
      findsOneWidget,
    );
  });

  testWidgets('avatar non valido ricade nel fallback locale deterministico', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        AccountView.authenticated(
          model: AuthenticatedAccountPresentationModel(
            displayName: 'María',
            email: 'maria@example.test',
            avatarBytes: Uint8List.fromList(const [0, 1, 2, 3]),
          ),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('account-avatar-fallback')),
      findsOneWidget,
    );
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('account-avatar-image')),
    );
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).imageProvider, isA<MemoryImage>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('avatar locale valido usa solo memoria e resta visibile', (
    tester,
  ) async {
    final avatarBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
      '+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    );
    var createdHttpClients = 0;

    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(
          buildApp(
            AccountView.authenticated(
              model: AuthenticatedAccountPresentationModel(
                displayName: 'María',
                email: 'maria@example.test',
                avatarBytes: avatarBytes,
              ),
              onLogout: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
      },
      createHttpClient: (_) {
        createdHttpClients++;
        throw StateError('L’avatar locale non deve creare client HTTP.');
      },
    );

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('account-avatar-image')),
    );
    expect(image.image, isA<ResizeImage>());
    expect((image.image as ResizeImage).imageProvider, isA<MemoryImage>());
    expect(find.byKey(const ValueKey('account-avatar-fallback')), findsNothing);
    expect(createdHttpClients, 0);
    expect(tester.takeException(), isNull);
  });

  test('avatar locale è bounded e copiato difensivamente', () {
    final source = Uint8List.fromList(const [1, 2, 3, 4]);
    final model = AuthenticatedAccountPresentationModel(avatarBytes: source);
    source[0] = 99;

    final firstRead = model.avatarBytes!;
    expect(firstRead, const [1, 2, 3, 4]);
    firstRead[1] = 88;
    expect(model.avatarBytes, const [1, 2, 3, 4]);

    expect(
      () => AuthenticatedAccountPresentationModel(
        avatarBytes: Uint8List(
          AuthenticatedAccountPresentationModel.maxAvatarBytes + 1,
        ),
      ),
      throwsArgumentError,
    );
  });

  testWidgets('testi lunghi e scala 200% non causano overflow', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(320, 568));

    final longName = List.filled(30, 'NombreExtenso').join(' ');
    final longEmail =
        '${List.filled(20, 'correo.muy.largo').join('.')}'
        '@example.test';

    await tester.pumpWidget(
      buildApp(
        AccountView.authenticated(
          model: AuthenticatedAccountPresentationModel(
            displayName: longName,
            email: longEmail,
          ),
          onLogout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(longName), findsOneWidget);
    expect(find.text(longEmail), findsOneWidget);
    expect(tester.takeException(), isNull);

    final name = tester.widget<Text>(
      find.byKey(const ValueKey('account-display-name')),
    );
    final email = tester.widget<Text>(
      find.byKey(const ValueKey('account-email')),
    );
    expect(name.maxLines, 2);
    expect(name.overflow, TextOverflow.ellipsis);
    expect(email.maxLines, 2);
    expect(email.overflow, TextOverflow.ellipsis);
  });

  testWidgets('azioni Account rispettano semantica e target minimi', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final l10n = await loadL10n();

    await tester.pumpWidget(
      buildApp(
        AccountView.guest(onContinueWithGoogle: () {}, onBrowseAsGuest: () {}),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in const [
      ValueKey('account-google-button'),
      ValueKey('account-browse-button'),
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.height, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
      expect(size.width, greaterThanOrEqualTo(AppSizes.minimumTouchTarget));
    }

    expect(
      find.bySemanticsLabel(l10n.accountContinueWithGoogle),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(l10n.accountBrowseAsGuest), findsOneWidget);
    expect(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });

  testWidgets(
    'matrice completa stati Auth rifluisce a 200% con semantica e target',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final semantics = tester.ensureSemantics();
      final l10n = await loadL10n();
      final model = AuthenticatedAccountPresentationModel(
        displayName: 'Cliente con nombre extenso',
        email: 'customer@example.test',
      );
      final cases =
          <
            ({
              String name,
              AccountView view,
              List<ValueKey<String>> actions,
              bool liveStatus,
            })
          >[
            (
              name: 'guest',
              view: AccountView.guest(onContinueWithGoogle: () {}),
              actions: const [ValueKey('account-google-button')],
              liveStatus: false,
            ),
            (
              name: 'authenticating',
              view: AccountView.status(
                title: l10n.accountSigningInTitle,
                message: l10n.accountSigningInMessage,
                isProgress: true,
                secondaryLabel: l10n.accountCancelSignIn,
                onSecondary: () {},
              ),
              actions: const [ValueKey('account-auth-secondary')],
              liveStatus: true,
            ),
            (
              name: 'cancelling',
              view: AccountView.status(
                title: l10n.accountCancellingTitle,
                message: l10n.accountCancellingMessage,
                isProgress: true,
              ),
              actions: const [],
              liveStatus: true,
            ),
            (
              name: 'cancelled',
              view: AccountView.status(
                title: l10n.accountCancelledTitle,
                message: l10n.accountCancelledMessage,
                primaryLabel: l10n.accountRetry,
                onPrimary: () {},
              ),
              actions: const [ValueKey('account-auth-primary')],
              liveStatus: true,
            ),
            (
              name: 'authenticated',
              view: AccountView.authenticated(model: model, onLogout: () {}),
              actions: const [ValueKey('account-logout-button')],
              liveStatus: false,
            ),
            (
              name: 'signingOut',
              view: AccountView.authenticated(
                model: model,
                onLogout: null,
                isSigningOut: true,
              ),
              actions: const [ValueKey('account-logout-button')],
              liveStatus: false,
            ),
            (
              name: 'recoverableError',
              view: AccountView.status(
                title: l10n.accountAuthErrorTitle,
                message: l10n.accountAuthOffline,
                primaryLabel: l10n.accountRetry,
                onPrimary: () {},
              ),
              actions: const [ValueKey('account-auth-primary')],
              liveStatus: true,
            ),
            (
              name: 'configurationError',
              view: AccountView.status(
                title: l10n.accountConfigurationErrorTitle,
                message: l10n.accountAuthConfiguration,
              ),
              actions: const [],
              liveStatus: true,
            ),
          ];
      const viewports = [Size(320, 568), Size(568, 320), Size(1024, 768)];

      for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
        for (final viewport in viewports) {
          await tester.binding.setSurfaceSize(viewport);
          for (final testCase in cases) {
            await tester.pumpWidget(buildMatrixApp(testCase.view, themeMode));
            await tester.pump();

            expect(
              find.byKey(const ValueKey('account-card')),
              findsOneWidget,
              reason: '${testCase.name} / $themeMode / $viewport',
            );
            expect(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.header == true,
              ),
              findsAtLeastNWidgets(1),
              reason: 'header ${testCase.name} / $themeMode / $viewport',
            );
            if (testCase.liveStatus) {
              expect(
                find.byWidgetPredicate(
                  (widget) =>
                      widget is Semantics &&
                      widget.properties.liveRegion == true,
                ),
                findsAtLeastNWidgets(1),
                reason: 'live ${testCase.name} / $themeMode / $viewport',
              );
            }

            for (final key in testCase.actions) {
              final action = find.byKey(key);
              await tester.ensureVisible(action);
              await tester.pump();
              final size = tester.getSize(action);
              expect(
                size.width,
                greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
                reason: '$key width ${testCase.name} / $viewport',
              );
              expect(
                size.height,
                greaterThanOrEqualTo(AppSizes.minimumTouchTarget),
                reason: '$key height ${testCase.name} / $viewport',
              );
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '${testCase.name} / $themeMode / $viewport',
            );
          }
        }
      }
      semantics.dispose();
    },
  );
}
