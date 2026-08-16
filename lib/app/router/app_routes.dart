abstract final class AppRoutes {
  static const homeLocation = '/home';
  static const catalogLocation = '/catalog';
  static const cartLocation = '/cart';
  static const accountLocation = '/account';
  static const checkoutLocation = '/checkout';
  static const favoritesLocation = '/favorites';
  static const ordersLocation = '/orders';
  static const orderPattern = '/orders/:orderId';
  static const productPattern = '/product/:publicationId';

  static String productLocation(String publicationId) =>
      '/product/$publicationId';

  static String orderLocation(String orderId) => '/orders/$orderId';

  static String ordersLocationForFilter(String filter) {
    return Uri(
      path: ordersLocation,
      queryParameters: {'filter': filter},
    ).toString();
  }
}
