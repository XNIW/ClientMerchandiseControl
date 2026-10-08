import 'dart:async';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/presentation/customer_account_panel.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'review: Navigator disposal before address dialog mount terminates monitor',
    (tester) async {
      var completed = false;
      var monitorClosed = false;
      final container = ProviderContainer(
        overrides: [
          customerAccountIdentityProvider.overrideWith((ref) {
            ref.onCancel(() => monitorClosed = true);
            return AuthenticatedCustomer.fromUntrustedIdentity(
              subjectId: '00000000-0000-4000-8000-000000021001',
              email: 'review@example.invalid',
              metadata: const {},
            );
          }),
        ],
      );
      addTearDown(container.dispose);
      late BuildContext openingContext;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                openingContext = context;
                return const Scaffold(body: Text('Host'));
              },
            ),
          ),
        ),
      );
      unawaited(
        showCustomerAddressEditor(openingContext).then((_) => completed = true),
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(completed, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(
        completed,
        isTrue,
        reason:
            'Navigator disposal must conclude the pending address intent before first mount',
      );
      expect(monitorClosed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
