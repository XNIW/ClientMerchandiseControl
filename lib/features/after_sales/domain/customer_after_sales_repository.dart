import 'customer_after_sales_models.dart';

abstract interface class CustomerAfterSalesRepository {
  Future<List<CustomerAfterSalesCase>> list({required String shopSlug});

  Future<CustomerAfterSalesOrderLines> listOrderLines(String orderId);

  Future<CustomerAfterSalesCase> create({
    required CustomerAfterSalesDraft draft,
    required String idempotencyKey,
  });

  Future<CustomerAfterSalesCase> cancel({
    required String caseId,
    required int expectedVersion,
  });

  Future<String> uploadEvidence({
    required String caseId,
    required CustomerAfterSalesEvidenceInput input,
  });
}

final class CustomerAfterSalesException implements Exception {
  const CustomerAfterSalesException(this.code);

  final String code;
}
