import 'dart:async';

import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
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
  for (final editing in [false, true]) {
    testWidgets(
      '${editing ? 'edit' : 'create'} address conserva bozza dopo errore e ritenta',
      (tester) async {
        final repository =
            FakeCustomerAccountRepository(
                addresses: editing ? [testCustomerAddress(version: 7)] : null,
              )
              ..mutationError = const CustomerAccountRepositoryException(
                CustomerAccountFailureKind.unavailable,
              );
        await tester.pumpWidget(_buildApp(repository));
        await tester.pumpAndSettle();
        await _openAddress(tester, editing: editing);
        await _fillAddress(tester, line1: 'Calle borrador conservado 456');
        await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsOneWidget,
        );
        expect(_addressText(tester, 'line1'), 'Calle borrador conservado 456');
        final l10n = AppLocalizations.of(
          tester.element(find.byKey(const ValueKey('customer-address-dialog'))),
        );
        expect(find.text(l10n.customerAccountUnavailable), findsWidgets);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('customer-address-submit')),
              )
              .onPressed,
          isNotNull,
        );

        repository.mutationError = null;
        await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsNothing,
        );
        expect(
          repository.addresses.last.addressLine1,
          'Calle borrador conservado 456',
        );
        if (editing) {
          expect(repository.addressUpdates, hasLength(2));
          expect(
            repository.addressUpdates.every(
              (attempt) =>
                  attempt.addressId == testAddressId &&
                  attempt.expectedVersion == 7 &&
                  attempt.draft.addressLine1 == 'Calle borrador conservado 456',
            ),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final editing in [false, true]) {
    testWidgets(
      '${editing ? 'edit' : 'create'} address busy blocca doppio submit',
      (tester) async {
        final barrier = Completer<void>();
        final repository = FakeCustomerAccountRepository(
          addresses: editing ? [testCustomerAddress(version: 7)] : null,
        );
        await tester.pumpWidget(_buildApp(repository));
        await tester.pumpAndSettle();
        repository.addressMutationBarrier = barrier;
        await _openAddress(tester, editing: editing);
        await _fillAddress(tester, line1: 'Calle guardado pendiente 789');
        final save = find.byKey(const ValueKey('customer-address-submit'));
        await tester.tap(save);
        await tester.pump();
        expect(
          find.byKey(const ValueKey('customer-address-saving')),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('customer-address-field-line1')),
              )
              .enabled,
          isFalse,
        );
        await tester.tap(save);
        await tester.pump();
        expect(
          editing
              ? repository.addressUpdates.length
              : repository.createAddressAttempts,
          1,
        );
        barrier.complete();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsNothing,
        );
        expect(
          repository.addresses.last.addressLine1,
          'Calle guardado pendiente 789',
        );
        if (editing) {
          expect(repository.addressUpdates.single.addressId, testAddressId);
          expect(repository.addressUpdates.single.expectedVersion, 7);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'create accettata con refresh fallito non offre una seconda create',
    (tester) async {
      final repository = FakeCustomerAccountRepository();
      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();
      await _openAddress(tester, editing: false);
      await _fillAddress(tester, line1: 'Calle guardada sin refresh 101');
      repository.loadError = const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.unavailable,
      );
      await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
      await tester.pumpAndSettle();
      expect(repository.createAddressCalls, 1);
      expect(
        repository.addresses.last.addressLine1,
        'Calle guardada sin refresh 101',
      );
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsNothing,
      );
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(CustomerAccountPanel)),
          ).customerAccountUnavailable,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancel durante write pendente non chiude il dialog successivo', (
    tester,
  ) async {
    final barrier = Completer<void>();
    final repository = FakeCustomerAccountRepository();
    await tester.pumpWidget(_buildApp(repository));
    await tester.pumpAndSettle();
    repository.addressMutationBarrier = barrier;
    await _openAddress(tester, editing: true);
    await _fillAddress(tester, line1: 'Calle write poi cancel 202');
    await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('customer-address-cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('customer-address-dialog')), findsNothing);
    unawaited(
      showDialog<void>(
        context: tester.element(find.byType(CustomerAccountPanel)),
        builder: (_) => const AlertDialog(
          key: ValueKey('later-dialog'),
          title: Text('Successivo'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    barrier.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('later-dialog')), findsOneWidget);
    expect(repository.addressUpdates, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cambio owner A-B-A durante write elimina bozza e ignora risposta tardiva',
    (tester) async {
      final identity = StateProvider<AuthenticatedCustomer?>(
        (ref) => _identity(),
      );
      final barrier = Completer<void>();
      final repository = FakeCustomerAccountRepository();
      await tester.pumpWidget(
        _buildApp(repository, identityProvider: identity),
      );
      await tester.pumpAndSettle();
      repository.addressMutationBarrier = barrier;
      await _openAddress(tester, editing: true);
      await _fillAddress(tester, line1: 'Bozza privata owner A');
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CustomerAccountPanel)),
      );
      await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
      await tester.pump();
      container.read(identity.notifier).state = _identity(
        subjectId: '10000000-0000-4000-8000-000000000999',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsNothing,
      );
      container.read(identity.notifier).state = _identity();
      await tester.pump();
      repository.mutationError = const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.unavailable,
      );
      barrier.complete();
      await tester.pumpAndSettle();
      expect(find.text('Bozza privata owner A'), findsNothing);
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsNothing,
      );
      expect(
        find.text(
          AppLocalizations.of(
            tester.element(find.byType(CustomerAccountPanel)),
          ).customerAccountUnavailable,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dispose durante write pendente non usa context o controller testo eliminati',
    (tester) async {
      final barrier = Completer<void>();
      final repository = FakeCustomerAccountRepository();
      await tester.pumpWidget(_buildApp(repository));
      await tester.pumpAndSettle();
      repository.addressMutationBarrier = barrier;
      await _openAddress(tester, editing: true);
      await _fillAddress(tester, line1: 'Bozza prima del dispose');
      await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      barrier.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('modifica testo geografico invalida il pin precedente', (
    tester,
  ) async {
    CustomerAddressDraft? saved;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerAccountIdentityProvider.overrideWithValue(_identity()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await showCustomerAddressEditor(
                    context,
                    initial: const CustomerAddressEditorInitial(
                      label: 'Casa',
                      recipientName: 'Cliente Test',
                      addressLine1: 'Via Test 1',
                      commune: 'Comune Test',
                      region: 'Regione Test',
                      latitude: -33,
                      longitude: -70,
                      locationSource: CustomerAddressLocationSource.search,
                    ),
                  );
                },
                child: const Text('apri'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('customer-address-field-line1')),
      'Via Nuova 2',
    );
    await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);
    expect(saved?.addressLine1, 'Via Nuova 2');
    expect(saved?.latitude, isNull);
    expect(saved?.longitude, isNull);
    expect(saved?.locationAccuracyMeters, isNull);
    expect(saved?.locationSource, CustomerAddressLocationSource.manual);
  });

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

  testWidgets('logout e cambio account chiudono dialog con dati customer', (
    tester,
  ) async {
    final identity = StateProvider<AuthenticatedCustomer?>(
      (ref) => _identity(),
    );
    await tester.pumpWidget(
      _buildApp(FakeCustomerAccountRepository(), identityProvider: identity),
    );
    await tester.pumpAndSettle();

    final addAddress = find.byKey(const ValueKey('customer-address-add'));
    await tester.ensureVisible(addAddress);
    await tester.tap(addAddress);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('customer-address-dialog')),
      findsOneWidget,
    );

    final context = ProviderScope.containerOf(tester.element(addAddress));
    context.read(identity.notifier).state = null;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('customer-address-dialog')), findsNothing);

    context.read(identity.notifier).state = _identity();
    await tester.pumpAndSettle();
    final export = find.byKey(const ValueKey('customer-data-export'));
    await tester.ensureVisible(export);
    await tester.tap(export);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('customer-export-dialog')),
      findsOneWidget,
    );

    context.read(identity.notifier).state = _identity(
      subjectId: '10000000-0000-4000-8000-000000000999',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('customer-export-dialog')), findsNothing);
  });
}

Future<void> _openAddress(WidgetTester tester, {required bool editing}) async {
  final action = find.byKey(
    ValueKey(
      editing ? 'customer-address-edit-$testAddressId' : 'customer-address-add',
    ),
  );
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _fillAddress(WidgetTester tester, {required String line1}) async {
  for (final entry in {
    'label': 'Casa borrador',
    'recipient': 'Cliente Sintético',
    'line1': line1,
    'commune': 'Santiago',
    'region': 'Metropolitana',
  }.entries) {
    final field = find.byKey(ValueKey('customer-address-field-${entry.key}'));
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
  }
}

String _addressText(WidgetTester tester, String field) => tester
    .widget<TextFormField>(
      find.byKey(ValueKey('customer-address-field-$field')),
    )
    .controller!
    .text;

Widget _buildApp(
  FakeCustomerAccountRepository repository, {
  Locale locale = const Locale('es', 'CL'),
  ThemeMode themeMode = ThemeMode.light,
  StateProvider<AuthenticatedCustomer?>? identityProvider,
}) {
  return ProviderScope(
    overrides: [
      customerAccountIdentityProvider.overrideWith((ref) {
        final provider = identityProvider;
        return provider == null ? _identity() : ref.watch(provider);
      }),
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

AuthenticatedCustomer _identity({String subjectId = testCustomerSubject}) {
  return AuthenticatedCustomer.fromUntrustedIdentity(
    subjectId: subjectId,
    email: 'customer@example.invalid',
    metadata: const {'name': 'Cliente Uno'},
  );
}
