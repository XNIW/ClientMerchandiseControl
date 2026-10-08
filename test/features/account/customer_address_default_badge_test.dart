import 'dart:io';
import 'package:client_merchandise_control/app/theme/app_theme.dart';
import 'package:client_merchandise_control/features/account/application/customer_account_providers.dart';
import 'package:client_merchandise_control/features/account/presentation/customer_account_panel.dart';
import 'package:client_merchandise_control/features/auth/domain/authenticated_customer.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'customer_account_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    expect(flutterRoot, isNotNull);
    final loader = FontLoader('Roboto');
    for (final name in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']) {
      final bytes = File.fromUri(
        Directory(
          flutterRoot!,
        ).uri.resolve('bin/cache/artifacts/material_fonts/$name'),
      ).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });
  for (final locale in const [
    Locale('es', 'CL'),
    Locale('it'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'badge default resta leggibile compact200 ${locale.toLanguageTag()} ${brightness.name}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          final repository = FakeCustomerAccountRepository();
          repository.addressCreationJournal.readError = StateError(
            'temporarily_unreadable',
          );
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                customerAccountIdentityProvider.overrideWithValue(
                  AuthenticatedCustomer.fromUntrustedIdentity(
                    subjectId: testCustomerSubject,
                    email: 'customer@example.invalid',
                    metadata: const {'name': 'Cliente Uno'},
                  ),
                ),
                customerAccountRepositoryProvider.overrideWithValue(repository),
                customerAccountShopSlugProvider.overrideWithValue(null),
              ],
              child: MaterialApp(
                theme: brightness == Brightness.dark
                    ? AppTheme.dark()
                    : AppTheme.light(),
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => Center(
                  child: SizedBox(
                    width: 320,
                    height: 568,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: const Size(320, 568),
                        textScaler: TextScaler.linear(2),
                      ),
                      child: child!,
                    ),
                  ),
                ),
                home: const Scaffold(
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: CustomerAccountPanel(
                        authDisplayName: 'Cliente sintético',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('customer-account-ready')),
            findsOneWidget,
          );
          expect(
            tester
                .widget<IconButton>(
                  find.byKey(const ValueKey('customer-address-add')),
                )
                .onPressed,
            isNull,
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(CustomerAccountPanel)),
          );
          final badge = find.text(l10n.customerAddressDefault);
          await tester.ensureVisible(badge);
          await tester.pumpAndSettle();
          final paragraph = tester.renderObject<RenderParagraph>(badge);
          final natural = paragraph.getMaxIntrinsicWidth(double.infinity);
          final actual = paragraph.size.width;
          final node = tester.getSemantics(badge).getSemanticsData();
          semantics.dispose();
          expect(node.label, contains(l10n.customerAddressDefault));
          final fullyPainted =
              natural <= actual + 0.01 ||
              (paragraph.softWrap &&
                  paragraph.maxLines != 1 &&
                  !paragraph.didExceedMaxLines);
          expect(
            fullyPainted,
            isTrue,
            reason:
                'Il badge deve mostrare tutto lo stato default al200%, senza fade o taglio del testo',
          );
          final boxes = paragraph.getBoxesForSelection(
            TextSelection(
              baseOffset: 0,
              extentOffset: l10n.customerAddressDefault.length,
            ),
          );
          expect(boxes, isNotEmpty);
          expect(
            boxes.every(
              (box) =>
                  box.left >= -0.5 &&
                  box.right <= paragraph.size.width + 0.5 &&
                  box.top >= -0.5 &&
                  box.bottom <= paragraph.size.height + 0.5,
            ),
            isTrue,
            reason:
                'Ogni glifo del badge deve restare nel suo rettangolo visibile',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}
