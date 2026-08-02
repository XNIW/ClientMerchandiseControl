import 'package:client_merchandise_control/features/storefront/data/storefront_catalog_dto.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_failure.dart';
import 'package:client_merchandise_control/features/storefront/domain/storefront_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../storefront_test_fixture.dart';

void main() {
  test('decodifica categorie e pagina catalogo versionate', () {
    final categories = StorefrontCatalogDto.decodeCategories(
      validStorefrontCategoriesPayload(),
    );
    final catalog = StorefrontCatalogDto.decodeCatalog(
      validStorefrontCatalogPayload(),
    );

    expect(categories.catalogVersion, 7);
    expect(categories.categories.single.slug, 'bebidas');
    expect(categories.nextCursor, validStorefrontCursor);
    expect(catalog.catalogVersion, 7);
    expect(catalog.items, hasLength(2));
    expect(catalog.sort, StorefrontCatalogSort.catalog);
    expect(catalog.nextCursor, validStorefrontCursor);
  });

  test('decodifica ricerca versionata senza esporre relevanceScore', () {
    final search = StorefrontCatalogDto.decodeSearch(
      validStorefrontSearchPayload(),
    );

    expect(search.catalogVersion, 7);
    expect(search.query, 'cafe');
    expect(search.items, hasLength(2));
    expect(search.nextCursor, validStorefrontCursor);
  });

  test('rifiuta shape, query, score e duplicati invalidi nella ricerca', () {
    final extra = validStorefrontSearchPayload()..['inventory'] = true;
    final shortQuery = validStorefrontSearchPayload(query: 'x');
    final missingScore = validStorefrontSearchPayload();
    ((missingScore['items'] as List).first as Map).remove('relevanceScore');
    final invalidScore = validStorefrontSearchPayload();
    ((invalidScore['items'] as List).first as Map)['relevanceScore'] = -1;
    final duplicate = validStorefrontSearchPayload();
    final items = List<Object?>.from(duplicate['items'] as List);
    items.add(Map<String, Object?>.from(items.first as Map));
    duplicate['items'] = items;

    for (final payload in [
      extra,
      shortQuery,
      missingScore,
      invalidScore,
      duplicate,
    ]) {
      expect(
        () => StorefrontCatalogDto.decodeSearch(payload),
        throwsA(
          isA<StorefrontFailure>().having(
            (failure) => failure.kind,
            'kind',
            StorefrontFailureKind.invalidPayload,
          ),
        ),
      );
    }
  });

  test('rifiuta cursor, duplicati, campi extra e versione item incoerente', () {
    final invalidCursor = validStorefrontCatalogPayload()
      ..['nextCursor'] = 'not_base64';
    final duplicate = validStorefrontCatalogPayload();
    final items = duplicate['items'] as List;
    items.add(Map<String, Object?>.from(items.first as Map));
    final extra = validStorefrontCategoriesPayload()..['inventory'] = true;
    final versionMismatch = validStorefrontCatalogPayload();
    ((versionMismatch['items'] as List).first as Map)['catalogVersion'] = 8;

    for (final payload in [invalidCursor, duplicate, extra, versionMismatch]) {
      expect(
        () => payload.containsKey('categories')
            ? StorefrontCatalogDto.decodeCategories(payload)
            : StorefrontCatalogDto.decodeCatalog(payload),
        throwsA(
          isA<StorefrontFailure>().having(
            (failure) => failure.kind,
            'kind',
            StorefrontFailureKind.invalidPayload,
          ),
        ),
      );
    }
  });

  test(
    'classifica catalog_changed e unavailable senza accettazione parziale',
    () {
      for (final entry in const [
        ('catalog_changed', StorefrontFailureKind.catalogChanged),
        ('unavailable', StorefrontFailureKind.unavailable),
      ]) {
        expect(
          () => StorefrontCatalogDto.decodeCatalog({
            'status': entry.$1,
            'apiVersion': 'storefront.v1',
          }),
          throwsA(
            isA<StorefrontFailure>().having(
              (failure) => failure.kind,
              'kind',
              entry.$2,
            ),
          ),
        );
      }
    },
  );
}
