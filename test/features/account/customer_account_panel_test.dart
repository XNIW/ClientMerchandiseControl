import 'dart:ui' as ui;

import 'package:client_merchandise_control/app/client_merchandise_control_app.dart';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/presentation/customer_account_panel.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'customer_account_test_support.dart';

void main() {
  testWidgets(
    'profilo, address CRUD, consent, export e deletion sono data-backed',
    (tester) async {
      final repository = FakeCustomerAccountRepository();
      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('customer-account-ready')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('customer-profile-name')),
        'Cliente Actualizado',
      );
      await tester.tap(find.byKey(const ValueKey('customer-profile-locale')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Italiano').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('customer-profile-save')));
      await tester.pumpAndSettle();

      expect(repository.profile?.displayName, 'Cliente Actualizado');
      expect(repository.profile?.locale, 'it');
      expect(repository.saveProfileCalls, 1);

      final addAddress = find.byKey(const ValueKey('customer-address-add'));
      await tester.ensureVisible(addAddress);
      await tester.tap(addAddress);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsOneWidget,
      );

      for (final entry in const {
        'label': 'Trabajo',
        'recipient': 'Cliente Actualizado',
        'line1': 'Calle Dos 456',
        'commune': 'Providencia',
        'region': 'Metropolitana',
      }.entries) {
        await tester.enterText(
          find.byKey(ValueKey('customer-address-field-${entry.key}')),
          entry.value,
        );
      }
      await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
      await tester.pumpAndSettle();
      expect(repository.createAddressCalls, 1);
      expect(find.text('Trabajo'), findsOneWidget);

      final consent = find.byKey(const ValueKey('customer-privacy-consent'));
      await tester.ensureVisible(consent);
      await tester.tap(consent);
      await tester.pumpAndSettle();
      expect(repository.profile?.hasPrivacyConsent, isTrue);

      final export = find.byKey(const ValueKey('customer-data-export'));
      await tester.ensureVisible(export);
      await tester.tap(export);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('customer-export-dialog')),
        findsOneWidget,
      );
      expect(find.textContaining('customer.v1'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          AppLocalizations.of(
            tester.element(
              find.byKey(const ValueKey('customer-export-dialog')),
            ),
          ).customerDialogClose,
        ),
      );
      await tester.pumpAndSettle();

      final requestDeletion = find.byKey(
        const ValueKey('customer-deletion-request'),
      );
      await tester.ensureVisible(requestDeletion);
      await tester.tap(requestDeletion);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('customer-confirm-action')));
      await tester.pumpAndSettle();
      expect(repository.requestDeletionCalls, 1);
      expect(
        find.byKey(const ValueKey('customer-deletion-cancel')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'offline è esplicito, non ritenta in loop e recupera manualmente',
    (tester) async {
      final repository = FakeCustomerAccountRepository()
        ..loadError = offlineCustomerFailure();
      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('customer-account-load-failure')),
        findsOneWidget,
      );
      expect(repository.loadCalls, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(repository.loadCalls, 1);

      repository.loadError = null;
      await tester.tap(find.byKey(const ValueKey('customer-account-retry')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('customer-account-ready')),
        findsOneWidget,
      );
      expect(repository.loadCalls, 2);
    },
  );

  testWidgets('quattro locale, dark e text scale 200% non producono overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(320, 568));

    for (final locale in appSupportedLocales) {
      final repository = FakeCustomerAccountRepository();
      await tester.pumpWidget(
        _buildApp(repository, locale: locale, themeMode: ThemeMode.dark),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('customer-account-ready')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: locale.toLanguageTag());
    }
  });

  testWidgets('azioni principali hanno Semantics e target almeno 48', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_buildApp(FakeCustomerAccountRepository()));
    await tester.pumpAndSettle();

    for (final key in const [
      ValueKey('customer-profile-save'),
      ValueKey('customer-address-add'),
      ValueKey('customer-data-export'),
    ]) {
      final finder = find.byKey(key);
      await tester.ensureVisible(finder);
      final size = tester.getSize(finder);
      expect(size.height, greaterThanOrEqualTo(48), reason: key.toString());
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.flagsCollection.isEnabled, ui.Tristate.isTrue);
    }
    semantics.dispose();
  });
}

Widget _buildApp(
  FakeCustomerAccountRepository repository, {
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: [
      customerAccountIdentityProvider.overrideWithValue(_identity()),
      customerAccountRepositoryProvider.overrideWithValue(repository),
      customerIdempotencyKeyFactoryProvider.overrideWithValue(
        () => '21000000-0000-4000-8000-000000000777',
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: CustomerAccountPanel(authDisplayName: 'Cliente Auth'),
        ),
      ),
    ),
  );
}

AuthenticatedCustomer _identity() {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: testCustomerSubject,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Cliente Uno'},
  );
}
