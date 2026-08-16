import 'package:client_merchandise_control/app/router/app_router.dart';
import 'package:client_merchandise_control/core/observability/observability_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('screen mapping non include identificatori o query', () {
    expect(appScreenForPath('/home'), AppScreen.home);
    expect(appScreenForPath('/catalog'), AppScreen.catalog);
    expect(appScreenForPath('/orders'), AppScreen.orders);
    expect(
      appScreenForPath('/orders/123e4567-e89b-12d3-a456-426614174000'),
      AppScreen.orderDetail,
    );
    expect(
      appScreenForPath('/product/123e4567-e89b-12d3-a456-426614174000'),
      AppScreen.productDetail,
    );
    expect(appScreenForPath('/unknown/private'), AppScreen.unknown);
  });
}
