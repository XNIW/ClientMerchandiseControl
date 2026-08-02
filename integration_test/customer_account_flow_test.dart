import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/presentation/customer_account_panel.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/features/account/customer_account_test_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profilo cliente owner-only completo in processo reale', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = FakeCustomerAccountRepository();

    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('customer-account-ready')),
      findsOneWidget,
    );
    expect(repository.subjectId, testCustomerSubject);

    await tester.enterText(
      find.byKey(const ValueKey('customer-profile-name')),
      'Cliente Integración',
    );
    await _tap(tester, const ValueKey('customer-profile-locale'));
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await _tap(tester, const ValueKey('customer-profile-save'));
    expect(repository.profile?.displayName, 'Cliente Integración');
    expect(repository.profile?.locale, 'en');

    await _tap(tester, ValueKey('customer-address-edit-$testAddressId'));
    await tester.enterText(
      find.byKey(const ValueKey('customer-address-field-label')),
      'Casa principal',
    );
    await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
    await tester.pumpAndSettle();
    expect(repository.addresses.single.label, 'Casa principal');

    await _tap(tester, const ValueKey('customer-address-add'));
    for (final entry in const {
      'label': 'Trabajo',
      'recipient': 'Cliente Integración',
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
    expect(repository.addresses, hasLength(2));

    final createdAddress = repository.addresses.last;
    expect(createdAddress.id, isNot(testAddressId));
    await _tap(
      tester,
      ValueKey('customer-address-delete-${createdAddress.id}'),
    );
    await tester.tap(find.byKey(const ValueKey('customer-confirm-action')));
    await tester.pumpAndSettle();
    expect(repository.addresses, hasLength(1));

    await _tap(tester, const ValueKey('customer-privacy-consent'));
    expect(repository.profile?.hasPrivacyConsent, isTrue);

    await _tap(tester, const ValueKey('customer-data-export'));
    expect(
      find.byKey(const ValueKey('customer-export-dialog')),
      findsOneWidget,
    );
    expect(find.textContaining('customer.v1'), findsOneWidget);
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    await _tap(tester, const ValueKey('customer-deletion-request'));
    await tester.tap(find.byKey(const ValueKey('customer-confirm-action')));
    await tester.pumpAndSettle();
    expect(repository.deletionRequest?.status, 'requested');
    await _tap(tester, const ValueKey('customer-deletion-cancel'));
    expect(repository.deletionRequest?.status, 'cancelled');

    expect(tester.takeException(), isNull);
    semantics.dispose();
    binding.reportData = <String, Object?>{
      'ownerSnapshot': 'PASS',
      'profileCreateUpdate': 'PASS',
      'addressCreateUpdateDelete': 'PASS',
      'localePreference': 'PASS',
      'privacyConsent': 'PASS',
      'dataExport': 'PASS',
      'accountDeletionRequestCancel': 'PASS',
      'semanticsTree': 'PASS',
      'processAlive': 'PASS',
    };
  });
}

Future<void> _tap(WidgetTester tester, Key key) async {
  final finder = find.byKey(key);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _buildApp(FakeCustomerAccountRepository repository) {
  final identity = AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: testCustomerSubject,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Cliente Integración'},
  );
  return ProviderScope(
    overrides: [
      customerAccountIdentityProvider.overrideWithValue(identity),
      customerAccountRepositoryProvider.overrideWithValue(repository),
      customerIdempotencyKeyFactoryProvider.overrideWithValue(
        () => '21000000-0000-4000-8000-000000000777',
      ),
    ],
    child: MaterialApp(
      locale: const Locale('es', 'CL'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: CustomerAccountPanel(authDisplayName: 'Cliente Integración'),
          ),
        ),
      ),
    ),
  );
}
