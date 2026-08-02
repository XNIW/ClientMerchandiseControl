import 'dart:async';

import 'package:client_merchandise_control/core/config/app_config.dart';
import 'package:client_merchandise_control/features/deep_links/application/storefront_deep_link.dart';
import 'package:client_merchandise_control/features/sharing/application/product_public_link_builder.dart';
import 'package:client_merchandise_control/features/sharing/application/product_share_service.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:client_merchandise_control/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart' as platform;

const _publicationId = '50000000-0000-4000-8000-000000000001';
const _publicUrl =
    'com.xniw.clientmerchandisecontrol://storefront/'
    'storefront-test/product/$_publicationId';

void main() {
  test('adapter nativo inoltra payload, anchor e mappa i tre esiti', () async {
    platform.ShareParams? captured;
    var next = const platform.ShareResult(
      'copy',
      platform.ShareResultStatus.success,
    );
    final service = PlatformProductShareService(
      share: (params) async {
        captured = params;
        return next;
      },
    );
    const origin = Rect.fromLTWH(10, 20, 48, 48);
    final request = ShareRequest(
      subject: 'Café',
      text: 'Guarda Café:\n$_publicUrl',
      publicUrl: Uri.parse(_publicUrl),
      origin: origin,
    );

    var result = await service.share(request);
    expect(result.status, ShareResultStatus.completed);
    expect(result.activity, 'copy');
    expect(captured?.subject, 'Café');
    expect(captured?.title, 'Café');
    expect(captured?.text, request.text);
    expect(captured?.sharePositionOrigin, origin);
    expect(captured?.uri, isNull);

    next = const platform.ShareResult('', platform.ShareResultStatus.dismissed);
    result = await service.share(request);
    expect(result.status, ShareResultStatus.dismissed);
    expect(result.activity, isNull);

    next = platform.ShareResult.unavailable;
    result = await service.share(request);
    expect(result.status, ShareResultStatus.unavailable);
  });

  test('ShareRequest e ProductPublicLinkBuilder falliscono chiusi', () {
    final builder = ProductPublicLinkBuilder(const StorefrontDeepLinkCodec());
    expect(
      builder
          .product(shopSlug: 'storefront-test', publicationId: _publicationId)
          .toString(),
      _publicUrl,
    );
    expect(
      () => builder.product(
        shopSlug: 'storefront-test',
        publicationId: '../inventory',
      ),
      throwsArgumentError,
    );
    expect(
      () => ShareRequest(
        subject: 'Café',
        text: 'Testo senza URL',
        publicUrl: Uri.parse(_publicUrl),
        origin: const Rect.fromLTWH(0, 0, 48, 48),
      ),
      throwsArgumentError,
    );
    expect(
      () => ShareRequest(
        subject: 'Café',
        text: _publicUrl,
        publicUrl: Uri.parse(_publicUrl),
        origin: Rect.zero,
      ),
      throwsArgumentError,
    );
  });

  for (final testCase in const [
    (
      locale: Locale('es', 'CL'),
      expected: 'Mira Café público en Merchandise Control:',
    ),
    (
      locale: Locale('it'),
      expected: 'Guarda Café público su Merchandise Control:',
    ),
    (
      locale: Locale('en'),
      expected: 'See Café público in Merchandise Control:',
    ),
    (
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      expected: '在 Merchandise Control 查看Café público：',
    ),
  ]) {
    testWidgets(
      'share button usa payload esatto e pubblico ${testCase.locale.toLanguageTag()}',
      (tester) async {
        final service = _RecordingShareService();
        await tester.pumpWidget(
          _app(service: service, locale: testCase.locale),
        );
        await tester.pumpAndSettle();

        final button = find.byKey(
          const ValueKey('share-product-$_publicationId'),
        );
        expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        final semantics = tester.getSemantics(button).getSemanticsData();
        expect(semantics.label, isNotEmpty);
        expect(semantics.flagsCollection.isButton, isTrue);

        await tester.tap(button);
        await tester.pump();

        expect(service.calls, hasLength(1));
        final request = service.calls.single;
        expect(request.subject, 'Café público');
        expect(request.text, '${testCase.expected}\n$_publicUrl');
        expect(request.publicUrl.toString(), _publicUrl);
        expect(request.text, isNot(contains(r'$1.200')));
        expect(
          request.text,
          isNot(contains(_publicationId.replaceFirst('5', '9'))),
        );
        expect(request.text, isNot(contains('source_product_id')));
        expect(request.text, isNot(contains('owner_user_id')));
        expect(request.text, isNot(contains('supplier')));
        expect(request.text, isNot(contains('inventory')));
        expect(request.text, isNot(contains('token')));
        expect(request.origin.width, greaterThan(0));
        expect(request.origin.height, greaterThan(0));
      },
    );
  }

  testWidgets('cancel resta recuperabile senza errore e senza crash', (
    tester,
  ) async {
    final service = _RecordingShareService(
      result: const ShareResult(status: ShareResultStatus.dismissed),
    );
    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('share-product-$_publicationId')),
    );
    await tester.pump();

    expect(service.calls, hasLength(1));
    expect(
      find.text('No pudimos abrir las opciones para compartir.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('doppio tap apre una sola presentazione', (tester) async {
    final completer = Completer<ShareResult>();
    final service = _RecordingShareService(completer: completer);
    await tester.pumpWidget(_app(service: service));
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('share-product-$_publicationId'));
    await tester.tap(button);
    await tester.tap(button);

    expect(service.calls, hasLength(1));
    completer.complete(const ShareResult(status: ShareResultStatus.dismissed));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('errore nativo e URL invalido non espongono dettagli', (
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

    final invalidService = _RecordingShareService();
    await tester.pumpWidget(
      _app(
        service: invalidService,
        product: _product(id: '../inventory'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share-product-../inventory')));
    await tester.pump();
    expect(invalidService.calls, isEmpty);
    expect(
      find.text('No pudimos abrir las opciones para compartir.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'offline non altera payload e shop non configurato fallisce chiuso',
    (tester) async {
      final service = _RecordingShareService();
      await tester.pumpWidget(_app(service: service));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('share-product-$_publicationId')),
      );
      await tester.pump();
      expect(service.calls.single.publicUrl.toString(), _publicUrl);

      final missingShopService = _RecordingShareService();
      await tester.pumpWidget(
        _app(service: missingShopService, storefrontShopSlug: null),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('share-product-$_publicationId')),
      );
      await tester.pump();
      expect(missingShopService.calls, isEmpty);
      expect(
        find.text('No pudimos abrir las opciones para compartir.'),
        findsOneWidget,
      );
    },
  );
}

Widget _app({
  required ProductShareService service,
  Locale locale = const Locale('es', 'CL'),
  StorefrontProductSummary? product,
  String? storefrontShopSlug = 'storefront-test',
}) => ProviderScope(
  overrides: [
    appConfigProvider.overrideWithValue(
      storefrontShopSlug == null
          ? AppConfig.fromValues()
          : AppConfig.fromValues(
              appEnvironment: 'staging',
              supabaseUrl: 'https://staging.example.invalid',
              supabasePublishableKey: 'sb_publishable_staging',
              authRedirectUri: AppConfig.allowedAuthRedirectUri,
              googleAuthEnabled: 'false',
              storefrontShopSlug: storefrontShopSlug,
            ),
    ),
    productShareServiceProvider.overrideWithValue(service),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      appBar: AppBar(
        actions: [ProductShareButton(product: product ?? _product())],
      ),
    ),
  ),
);

StorefrontProductSummary _product({String id = _publicationId}) =>
    StorefrontProductSummary(
      id: id,
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

final class _RecordingShareService implements ProductShareService {
  _RecordingShareService({
    this.fail = false,
    this.result = const ShareResult(status: ShareResultStatus.completed),
    this.completer,
  });

  final bool fail;
  final ShareResult result;
  final Completer<ShareResult>? completer;
  final List<ShareRequest> calls = [];

  @override
  Future<ShareResult> share(ShareRequest request) async {
    if (fail) throw StateError('native failure with private implementation');
    calls.add(request);
    return completer?.future ?? result;
  }
}
