abstract final class AppRoutes {
  static const homeLocation = '/home';
  static const catalogLocation = '/catalog';
  static const cartLocation = '/cart';
  static const accountLocation = '/account';
  static const checkoutLocation = '/checkout';
  static const checkoutPaymentLocation = '/checkout/payment';
  static const deliveryContextLocation = '/delivery-context';
  static const notificationsLocation = '/notifications';
  static const afterSalesPattern = '/after-sales/:caseId';
  static const afterSalesBaseLocation = '/after-sales';
  static const reviewsLocation = '/reviews';
  static const favoritesLocation = '/favorites';
  static const ordersLocation = '/orders';
  static const orderPattern = '/orders/:orderId';
  static const productPattern = '/product/:publicationId';

  static String productLocation(String publicationId) =>
      '/product/$publicationId';

  static String orderLocation(String orderId) => '/orders/$orderId';

  static String afterSalesLocation(String? caseId) => caseId == null
      ? afterSalesBaseLocation
      : '$afterSalesBaseLocation/$caseId';

  static String afterSalesCreateLocation(String orderId) => Uri(
    path: afterSalesBaseLocation,
    queryParameters: {'orderId': orderId},
  ).toString();

  static String ordersLocationForFilter(String filter) {
    return Uri(
      path: ordersLocation,
      queryParameters: {'filter': filter},
    ).toString();
  }
}
