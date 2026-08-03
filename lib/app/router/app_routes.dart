abstract final class AppRoutes {
  static const homeLocation = '/home';
  static const catalogLocation = '/catalog';
  static const cartLocation = '/cart';
  static const accountLocation = '/account';
  static const checkoutLocation = '/checkout';
  static const favoritesLocation = '/favorites';
  static const productPattern = '/product/:publicationId';

  static String productLocation(String publicationId) =>
      '/product/$publicationId';
}
