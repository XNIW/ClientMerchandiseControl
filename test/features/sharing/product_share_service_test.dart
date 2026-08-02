import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/sharing/application/product_share_service.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

const _publicationId = '50000000-0000-4000-8000-000000000001';

void main() {
  test('adapter nativo inoltra subject, testo e anchor iPad bounded', () async {
    ShareParams? captured;
    final service = PlatformProductShareService(
      share: (params) async {
        captured = params;
        return const ShareResult('', ShareResultStatus.dismissed);
      },
    );
    const origin = Rect.fromLTWH(10, 20, 44, 44);

    await service.share(subject: 'Café', text: 'Payload', origin: origin);

    expect(captured?.subject, 'Café');
    expect(captured?.text, 'Payload');
    expect(captured?.sharePositionOrigin, origin);
  });

  testWidgets('share payload è localizzato, canonico e privo di dati interni', (
    tester,
  ) async {
    final service = _RecordingShareService();
    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('share-product-$_publicationId')),
    );
    await tester.pump();

    expect(service.calls, hasLength(1));
    final call = service.calls.single;
    expect(call.subject, 'Café público');
    expect(call.text, contains('Café público'));
    expect(
      call.text,
      contains(
        'com.xniw.clientmerchandisecontrol://storefront/'
        'storefront-test/product/$_publicationId',
      ),
    );
    expect(call.text, isNot(contains(r'$1.200')));
    expect(call.text, isNot(contains('supplier')));
    expect(call.text, isNot(contains('inventory')));
    expect(call.origin.width, greaterThan(0));
    expect(call.origin.height, greaterThan(0));
  });

  testWidgets('errore del dialogo nativo è recuperabile e sanitizzato', (
    tester,
  ) async {
    await tester.pumpWidget(_app(service: _RecordingShareService(fail: true)));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('share-product-$_publicationId')),
    );
    await tester.pump();

    expect(
      find.text('No pudimos abrir las opciones para compartir.'),
      findsOneWidget,
    );
    expect(find.textContaining('native failure'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget _app({required ProductShareService service}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(
      AppConfig.fromValues(
        appEnvironment: 'staging',
        supabaseUrl: 'https://staging.example.invalid',
        supabasePublishableKey: 'sb_publishable_staging',
        authRedirectUri: AppConfig.allowedAuthRedirectUri,
        googleAuthEnabled: 'false',
        storefrontShopSlug: 'storefront-test',
      ),
    ),
    productShareServiceProvider.overrideWithValue(service),
  ],
  child: MaterialApp(
    locale: const Locale('es', 'CL'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      appBar: AppBar(actions: [ProductShareButton(product: _product())]),
    ),
  ),
);

StorefrontProductSummary _product() => StorefrontProductSummary(
  id: _publicationId,
  category: const StorefrontCategory(
    id: '40000000-0000-4000-8000-000000000001',
    slug: 'bebidas',
    name: 'Bebidas',
    sortRank: 1,
  ),
  name: 'Café público',
  description: 'Dato pubblico',
  brand: 'Marca pública',
  priceClp: 1200,
  featured: false,
  sortRank: 1,
  availability: StorefrontAvailability.available,
  fulfillment: const StorefrontFulfillment(
    pickup: true,
    delivery: true,
    reservation: false,
  ),
  catalogVersion: 7,
  publishedAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 1),
);

typedef _ShareCall = ({String subject, String text, Rect origin});

final class _RecordingShareService implements ProductShareService {
  _RecordingShareService({this.fail = false});

  final bool fail;
  final List<_ShareCall> calls = [];

  @override
  Future<void> share({
    required String subject,
    required String text,
    required Rect origin,
  }) async {
    if (fail) throw StateError('native failure with private implementation');
    calls.add((subject: subject, text: text, origin: origin));
  }
}
