enum StorefrontAvailability {
  available,
  lowStock,
  unavailable,
  reservationOnly,
  pickupOnly,
  deliveryOnly,
}

enum StorefrontCatalogSort { catalog, name, priceAscending, priceDescending }

class StorefrontFulfillment {
  const StorefrontFulfillment({
    required this.pickup,
    required this.delivery,
    required this.reservation,
  });

  final bool pickup;
  final bool delivery;
  final bool reservation;
}

class StorefrontSettings {
  const StorefrontSettings({
    required this.shopSlug,
    required this.currency,
    required this.locale,
    required this.timeZone,
    required this.defaultPageSize,
    required this.maximumPageSize,
    required this.fulfillment,
  });

  final String shopSlug;
  final String currency;
  final String locale;
  final String timeZone;
  final int defaultPageSize;
  final int maximumPageSize;
  final StorefrontFulfillment fulfillment;
}

class StorefrontCategory {
  const StorefrontCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.sortRank,
  });

  final String id;
  final String slug;
  final String name;
  final int sortRank;
}

class StorefrontImageSet {
  const StorefrontImageSet({
    required this.version,
    required this.thumb,
    required this.card,
    required this.detail,
    required this.sha256,
  });

  final String version;
  final Uri thumb;
  final Uri card;
  final Uri detail;
  final String sha256;
}

class StorefrontPromotion {
  const StorefrontPromotion({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
}

class StorefrontProductSummary {
  const StorefrontProductSummary({
    required this.id,
    required this.category,
    required this.name,
    required this.priceClp,
    required this.featured,
    required this.sortRank,
    required this.availability,
    required this.fulfillment,
    required this.catalogVersion,
    required this.publishedAt,
    required this.updatedAt,
    this.description,
    this.brand,
    this.compareAtPriceClp,
    this.discountBps,
    this.promotion,
    this.images,
  });

  final String id;
  final StorefrontCategory category;
  final String name;
  final String? description;
  final String? brand;
  final int priceClp;
  final int? compareAtPriceClp;
  final int? discountBps;
  final StorefrontPromotion? promotion;
  final bool featured;
  final int sortRank;
  final StorefrontAvailability availability;
  final StorefrontFulfillment fulfillment;
  final StorefrontImageSet? images;
  final int catalogVersion;
  final DateTime publishedAt;
  final DateTime updatedAt;

  bool get hasDiscount =>
      compareAtPriceClp != null && compareAtPriceClp! > priceClp;
}

class StorefrontHomeData {
  StorefrontHomeData({
    required this.catalogVersion,
    required this.settings,
    required List<StorefrontCategory> categories,
    required List<StorefrontProductSummary> featured,
    required List<StorefrontProductSummary> offers,
  }) : categories = List.unmodifiable(categories),
       featured = List.unmodifiable(featured),
       offers = List.unmodifiable(offers);

  final int catalogVersion;
  final StorefrontSettings settings;
  final List<StorefrontCategory> categories;
  final List<StorefrontProductSummary> featured;
  final List<StorefrontProductSummary> offers;

  bool get isEmpty => categories.isEmpty && featured.isEmpty && offers.isEmpty;
}

class StorefrontCategoriesPage {
  StorefrontCategoriesPage({
    required this.catalogVersion,
    required List<StorefrontCategory> categories,
    required this.nextCursor,
  }) : categories = List.unmodifiable(categories);

  final int catalogVersion;
  final List<StorefrontCategory> categories;
  final String? nextCursor;
}

class StorefrontCatalogPage {
  StorefrontCatalogPage({
    required this.catalogVersion,
    required List<StorefrontProductSummary> items,
    required this.nextCursor,
    required this.sort,
  }) : items = List.unmodifiable(items);

  final int catalogVersion;
  final List<StorefrontProductSummary> items;
  final String? nextCursor;
  final StorefrontCatalogSort sort;
}

class StorefrontSearchPage {
  StorefrontSearchPage({
    required this.catalogVersion,
    required this.query,
    required List<StorefrontProductSummary> items,
    required this.nextCursor,
  }) : items = List.unmodifiable(items);

  final int catalogVersion;
  final String query;
  final List<StorefrontProductSummary> items;
  final String? nextCursor;
}
