// Componenti produzione, repository sintetici: nessuna prova staging/OAuth live.
import 'customer_account_flow_test.dart' as account;
import 'customer_checkout_flow_test.dart' as checkout;
import 'customer_order_history_flow_test.dart' as orders;
import 'task054_commerce_surfaces_test.dart' as commerce;
import 'task054_storefront_surfaces_test.dart' as storefront;
import 'task054_next_integration_surfaces_test.dart' as next;

void main() {
  account.main();
  checkout.main();
  orders.main();
  commerce.main();
  storefront.main();
  next.main();
}
