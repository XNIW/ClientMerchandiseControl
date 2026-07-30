import 'package:client_merchandise_control/app/branding/app_brand.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('usa il nome tecnico finché il public brand non è verificato', () {
    expect(AppBrand.verifiedPublicBrandName, isNull);
    expect(AppBrand.publicBrandStatus, AppBrandStatus.provisional);
    expect(AppBrand.effectiveDisplayName, AppBrand.technicalDisplayName);
  });

  test('mantiene separate identità tecnica, legale e del negozio', () {
    expect(AppBrand.projectName, isNot(AppBrand.dartPackageName));
    expect(AppBrand.legalEntity, isNull);
    expect(AppBrand.storeDisplayName, isNull);
    expect(AppBrand.tagline, isNull);
  });
}
