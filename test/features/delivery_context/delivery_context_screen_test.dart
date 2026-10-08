import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_failure.dart';
import 'package:client_merchandise_control/features/account/domain/customer_account_models.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_providers.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_address_ports.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_repository.dart';
import 'package:client_merchandise_control/features/delivery_context/presentation/delivery_context_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout/checkout_test_support.dart';
import '../account/customer_account_test_support.dart';
import '../../support/commerce_surface_fixtures.dart';

void main() {
  for (final entrypoint in ['create', 'edit', 'resolved']) {
    testWidgets(
      'delivery $entrypoint conserva bozza dopo errore e salva prima di chiudere',
      (tester) async {
        final fixture = Task054VisualFixtures();
        await _pumpAddressApp(tester, fixture);
        await _openDeliveryAddress(tester, entrypoint);
        await _fillDeliveryDraft(tester, entrypoint);
        fixture.account.mutationError =
            const CustomerAccountRepositoryException(
              CustomerAccountFailureKind.unavailable,
            );
        await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('customer-address-field-label')),
              )
              .controller!
              .text,
          'Bozza sintetica conservata',
        );
        expect(
          find.byKey(const ValueKey('customer-address-save-failure')),
          findsOneWidget,
        );
        expect(fixture.delivery.selected, isNull);
        fixture.account.mutationError = null;
        await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsNothing,
        );
        if (entrypoint == 'edit') {
          expect(fixture.account.addressUpdates, hasLength(2));
          expect(
            fixture.account.addressUpdates.every(
              (input) =>
                  input.addressId == testAddressId &&
                  input.expectedVersion == 1,
            ),
            isTrue,
          );
          expect(fixture.delivery.selected, isNull);
        } else {
          expect(fixture.account.createAddressCalls, 1);
          expect(fixture.account.addressCreates, hasLength(2));
          expect(
            fixture.delivery.selected?.addressId,
            fixture.account.addresses.last.id,
          );
          if (entrypoint == 'resolved') {
            expect(
              fixture.account.addressCreates.every(
                (draft) =>
                    draft.latitude == -33.45 &&
                    draft.longitude == -70.66 &&
                    draft.locationSource ==
                        CustomerAddressLocationSource.search &&
                    draft.locationAccuracyMeters == 12,
              ),
              isTrue,
            );
          }
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final entrypoint in ['create', 'resolved']) {
    testWidgets(
      'delivery $entrypoint ACK e reload fallito chiude senza duplicare create',
      (tester) async {
        final fixture = Task054VisualFixtures();
        final delivery = _RecordedDelivery(fixture.delivery);
        await _pumpAddressApp(
          tester,
          fixture,
          overrides: [
            deliveryContextRepositoryProvider.overrideWithValue(delivery),
          ],
        );
        await _openDeliveryAddress(tester, entrypoint);
        await _fillDeliveryDraft(tester, entrypoint);
        fixture.account.loadError = const CustomerAccountRepositoryException(
          CustomerAccountFailureKind.unavailable,
        );
        await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsNothing,
        );
        expect(fixture.account.addressCreates, hasLength(1));
        expect(delivery.selectCalls, 1);
        expect(
          fixture.delivery.selected?.addressId,
          fixture.account.addresses.last.id,
        );
        await tester.drag(find.byType(ListView), const Offset(0, 600));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('delivery-account-failure')),
          findsOneWidget,
        );
        expect(
          find.text(
            AppLocalizations.of(
              tester.element(find.byType(DeliveryContextScreen)),
            ).customerAccountUnavailable,
          ),
          findsOneWidget,
        );
        await tester.pump(const Duration(seconds: 1));
        expect(fixture.account.addressCreates, hasLength(1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'delivery selected edit ACK7 a8 e reload fallito chiude e rilegge contesto una volta',
    (tester) async {
      final fixture = Task054VisualFixtures();
      fixture.account.addresses = [testCustomerAddress(version: 7)];
      final delivery = _RecordedDelivery(fixture.delivery);
      await _pumpAddressApp(
        tester,
        fixture,
        overrides: [
          deliveryContextRepositoryProvider.overrideWithValue(delivery),
        ],
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DeliveryContextScreen)),
      );
      expect(
        await container
            .read(deliveryContextControllerProvider.notifier)
            .selectAddress(addressId: testAddressId),
        isTrue,
      );
      await tester.pumpAndSettle();
      await _openDeliveryAddress(tester, 'edit');
      await _fillDeliveryDraft(tester, 'edit');
      fixture.account.loadError = const CustomerAccountRepositoryException(
        CustomerAccountFailureKind.unavailable,
      );
      final reads = delivery.readCalls;
      await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsNothing,
      );
      expect(fixture.account.addressUpdates, hasLength(1));
      expect(fixture.account.addressUpdates.single.expectedVersion, 7);
      expect(fixture.account.addresses.single.version, 8);
      expect(delivery.readCalls, reads + 1);
      expect(delivery.selectCalls, 1);
      await tester.drag(find.byType(ListView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('delivery-account-failure')),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(fixture.account.addressUpdates, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'delivery create ACK con select fallita non riapre il retry della create',
    (tester) async {
      final fixture = Task054VisualFixtures();
      final delivery = _RecordedDelivery(fixture.delivery)..failSelect = true;
      await _pumpAddressApp(
        tester,
        fixture,
        overrides: [
          deliveryContextRepositoryProvider.overrideWithValue(delivery),
        ],
      );
      await _openDeliveryAddress(tester, 'create');
      await _fillDeliveryDraft(tester, 'create');
      await tester.tap(find.byKey(const ValueKey('customer-address-submit')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('customer-address-dialog')),
        findsNothing,
      );
      expect(fixture.account.addressCreates, hasLength(1));
      expect(delivery.selectCalls, 1);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DeliveryContextScreen)),
      );
      expect(
        container.read(deliveryContextControllerProvider).failure,
        DeliveryContextFailureKind.unavailable,
      );
      expect(fixture.delivery.selected, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final change in ['shop', 'owner', 'cancel', 'dispose']) {
    testWidgets(
      'delivery pending create dopo $change non seleziona o rilegge nello scope successivo',
      (tester) async {
        final identity = StateProvider<AuthenticatedCustomer?>(
          (ref) => _addressIdentity(),
        );
        final shop = StateProvider<String?>((ref) => 'storefront-test');
        final fixture = Task054VisualFixtures();
        final delivery = _RecordedDelivery(fixture.delivery);
        await _pumpAddressApp(
          tester,
          fixture,
          overrides: [
            customerAccountIdentityProvider.overrideWith(
              (ref) => ref.watch(identity),
            ),
            deliveryContextShopSlugProvider.overrideWith(
              (ref) => ref.watch(shop),
            ),
            deliveryContextRepositoryProvider.overrideWithValue(delivery),
          ],
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(DeliveryContextScreen)),
        );
        await _openDeliveryAddress(tester, 'create');
        await _fillDeliveryDraft(tester, 'create');
        final barrier = Completer<void>();
        fixture.account.addressMutationBarrier = barrier;
        final save = find.byKey(const ValueKey('customer-address-submit'));
        await tester.tap(save);
        await tester.pump();
        expect(tester.widget<FilledButton>(save).onPressed, isNull);
        await tester.tap(save);
        await tester.pump();
        expect(fixture.account.addressCreates, hasLength(1));
        if (change == 'shop') {
          container.read(shop.notifier).state = 'other-test';
          await tester.pump();
          container.read(shop.notifier).state = 'storefront-test';
          await tester.pump();
        } else if (change == 'owner') {
          container.read(identity.notifier).state = _addressIdentity(
            subjectId: '10000000-0000-4000-8000-000000000999',
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            find.byKey(const ValueKey('customer-address-dialog')),
            findsNothing,
          );
          container.read(identity.notifier).state = _addressIdentity();
          await tester.pump();
        } else if (change == 'cancel') {
          await tester.tap(
            find.byKey(const ValueKey('customer-address-cancel')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        } else {
          await tester.pumpWidget(const SizedBox.shrink());
        }
        final reads = delivery.readCalls;
        barrier.complete();
        await tester.pumpAndSettle();
        expect(delivery.selectCalls, 0);
        if (change != 'owner') expect(delivery.readCalls, reads);
        expect(fixture.delivery.selected, isNull);
        expect(
          find.byKey(const ValueKey('customer-address-dialog')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  Future<void> pump(WidgetTester tester, {_Search? search}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerAccountIdentityProvider.overrideWithValue(null),
          deliveryContextShopSlugProvider.overrideWithValue('storefront-test'),
          deliveryContextControllerProvider.overrideWith(_Delivery.new),
          checkoutRepositoryProvider.overrideWithValue(
            FakeCheckoutRepository(),
          ),
          if (search != null)
            addressSearchPortProvider.overrideWithValue(search),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeliveryContextScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('contesto delivery salvato non annulla la scelta pickup', (
    tester,
  ) async {
    await pump(tester);
    final selector = find.byType(SegmentedButton<CustomerDeliveryMode>);
    tester
        .widget<SegmentedButton<CustomerDeliveryMode>>(selector)
        .onSelectionChanged!({CustomerDeliveryMode.pickup});
    await tester.pumpAndSettle();
    expect(
      tester.widget<SegmentedButton<CustomerDeliveryMode>>(selector).selected,
      {CustomerDeliveryMode.pickup},
    );
  });

  testWidgets('cancellare una query pendente arresta il feedback di ricerca', (
    tester,
  ) async {
    final search = _Search();
    final pending = Completer<List<AddressSearchSuggestion>>();
    search.responses.add(pending.future);
    await pump(tester, search: search);
    final field = find.byKey(const ValueKey('delivery-address-search'));
    await tester.enterText(field, 'calle');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.enterText(field, '');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    pending.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('errore vecchio non elimina suggerimenti della query nuova', (
    tester,
  ) async {
    final search = _Search();
    final old = Completer<List<AddressSearchSuggestion>>();
    search.responses.addAll([
      old.future,
      Future.value(const [
        AddressSearchSuggestion(
          providerPlaceId: 'fixture-new',
          displayText: 'Risultato sintetico corrente',
        ),
      ]),
    ]);
    await pump(tester, search: search);
    final field = find.byKey(const ValueKey('delivery-address-search'));
    await tester.enterText(field, 'prima');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.enterText(field, 'seconda');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pump();
    expect(find.text('Risultato sintetico corrente'), findsOneWidget);
    old.completeError(StateError('provider unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Risultato sintetico corrente'), findsOneWidget);
  });
}

Future<void> _pumpAddressApp(
  WidgetTester tester,
  Task054VisualFixtures fixture, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    fixture.wrap(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DeliveryContextScreen(),
      ),
      additionalOverrides: [
        addressSearchPortProvider.overrideWithValue(const _ResolvedSearch()),
        ...overrides,
      ],
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openDeliveryAddress(
  WidgetTester tester,
  String entrypoint,
) async {
  final Finder action;
  if (entrypoint == 'resolved') {
    final field = find.byKey(const ValueKey('delivery-address-search'));
    await tester.ensureVisible(field);
    await tester.enterText(field, 'calle');
    await tester.pump(const Duration(milliseconds: 301));
    await tester.pumpAndSettle();
    action = find.text('Dirección resuelta sintética');
  } else {
    action = entrypoint == 'edit'
        ? find.widgetWithIcon(IconButton, Icons.edit_outlined)
        : find.byKey(const ValueKey('delivery-address-add'));
  }
  await tester.ensureVisible(action);
  await Scrollable.ensureVisible(tester.element(action), alignment: 0.5);
  await tester.pumpAndSettle();
  expect(action.hitTestable(), findsOneWidget);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<void> _fillDeliveryDraft(WidgetTester tester, String entrypoint) async {
  final fields = {
    'label': 'Bozza sintetica conservata',
    'recipient': 'Cliente Sintético',
    if (entrypoint == 'create') ...{
      'line1': 'Calle manual sintética 456',
      'commune': 'Santiago',
      'region': 'Metropolitana',
    },
  };
  for (final entry in fields.entries) {
    final field = find.byKey(ValueKey('customer-address-field-${entry.key}'));
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
  }
}

class _ResolvedSearch implements AddressSearchPort {
  const _ResolvedSearch();
  @override
  bool get configured => true;
  @override
  Future<List<AddressSearchSuggestion>> search(String query) async => const [
    AddressSearchSuggestion(
      displayText: 'Dirección resuelta sintética',
      providerPlaceId: 'fixture-place',
    ),
  ];
  @override
  Future<ReverseGeocodedAddress?> resolve(
    AddressSearchSuggestion suggestion,
  ) async => const ReverseGeocodedAddress(
    addressLine1: 'Calle resuelta sintética 789',
    commune: 'Santiago',
    region: 'Metropolitana',
    postalCode: '8320000',
    countryCode: 'CL',
    coordinate: DeliveryCoordinate(
      latitude: -33.45,
      longitude: -70.66,
      accuracyMeters: 12,
    ),
  );
}

AuthenticatedCustomer _addressIdentity({
  String subjectId = testCustomerSubject,
}) => AuthenticatedCustomer.fromUntrustedIdentity(
  subjectId: subjectId,
  email: null,
  metadata: const {},
);

class _RecordedDelivery implements DeliveryContextRepository {
  _RecordedDelivery(this.delegate);
  final Task054DeliveryRepository delegate;
  int readCalls = 0;
  int selectCalls = 0;
  bool failSelect = false;
  @override
  Future<CustomerDeliveryContext?> read({required String shopSlug}) {
    readCalls++;
    return delegate.read(shopSlug: shopSlug);
  }

  @override
  Future<CustomerDeliveryContext> preview({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    String? addressId,
    String? pickupPointId,
    String? commune,
  }) => delegate.preview(
    shopSlug: shopSlug,
    mode: mode,
    addressId: addressId,
    pickupPointId: pickupPointId,
    commune: commune,
  );
  @override
  Future<CustomerDeliveryContext> select({
    required String shopSlug,
    required CustomerDeliveryMode mode,
    required int expectedVersion,
    String? addressId,
    String? pickupPointId,
  }) async {
    selectCalls++;
    if (failSelect) {
      throw const DeliveryContextRepositoryException(
        DeliveryContextFailureKind.unavailable,
      );
    }
    return delegate.select(
      shopSlug: shopSlug,
      mode: mode,
      expectedVersion: expectedVersion,
      addressId: addressId,
      pickupPointId: pickupPointId,
    );
  }
}

class _Search implements AddressSearchPort {
  final responses = <Future<List<AddressSearchSuggestion>>>[];
  @override
  bool get configured => true;
  @override
  Future<List<AddressSearchSuggestion>> search(String query) =>
      responses.removeAt(0);
  @override
  Future<ReverseGeocodedAddress?> resolve(
    AddressSearchSuggestion suggestion,
  ) async => null;
}

class _Delivery extends DeliveryContextController {
  @override
  DeliveryContextState build() => DeliveryContextState(
    status: DeliveryContextViewStatus.ready,
    authenticated: true,
    context: checkoutTestDeliveryContext(),
  );
}
