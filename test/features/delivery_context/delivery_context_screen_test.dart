import 'dart:async';

import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/checkout/application/checkout_providers.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_controller.dart';
import 'package:client_merchandise_control/features/delivery_context/application/delivery_context_providers.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_address_ports.dart';
import 'package:client_merchandise_control/features/delivery_context/domain/delivery_context_models.dart';
import 'package:client_merchandise_control/features/delivery_context/presentation/delivery_context_screen.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../checkout/checkout_test_support.dart';

void main() {
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
