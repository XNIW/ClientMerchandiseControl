enum AppBrandStatus { provisional, approved }

abstract final class AppBrand {
  static const projectName = 'ClientMerchandiseControl';
  static const dartPackageName = 'client_merchandise_control';
  static const technicalDisplayName = 'Client Merchandise Control';

  static const String? verifiedPublicBrandName = null;
  static const publicBrandStatus = AppBrandStatus.provisional;
  static const String? legalEntity = null;
  static const String? storeDisplayName = null;
  static const String? tagline = null;

  static String get effectiveDisplayName =>
      verifiedPublicBrandName ?? technicalDisplayName;
}
