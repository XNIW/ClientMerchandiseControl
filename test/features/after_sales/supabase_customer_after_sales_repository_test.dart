import 'dart:typed_data';

import 'package:client_merchandise_control/features/after_sales/data/supabase_customer_after_sales_repository.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_models.dart';
import 'package:client_merchandise_control/features/after_sales/domain/customer_after_sales_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _owner = '10000000-0000-4000-8000-000000000001';
const _case = '81000000-0000-4000-8000-000000000001';
const _order = '84000000-0000-4000-8000-000000000001';
const _orderItem = '85000000-0000-4000-8000-000000000001';
const _ticket = '82000000-0000-4000-8000-000000000001';
const _evidence = '83000000-0000-4000-8000-000000000001';

void main() {
  test('post-vendita legge snapshot storico e quantità residua', () async {
    final port = _Port();
    final result = await SupabaseCustomerAfterSalesRepository(
      port: port,
    ).listOrderLines(_order);

    expect(port.functions, ['customer_after_sales_order_lines_v1']);
    expect(result.orderId, _order);
    expect(result.shopSlug, 'test-shop');
    expect(result.items, hasLength(1));
    expect(result.items.single.name, 'Prodotto storico nascosto');
    expect(result.items.single.orderedQuantity, 3);
    expect(result.items.single.existingOpenQuantity, 1);
    expect(result.items.single.maximumRequestQuantity, 2);
    expect(result.items.single.canRequest, isTrue);
  });

  test('quantità residua incoerente fallisce chiusa', () async {
    final port = _Port(
      orderLinesPayload: _orderLinesPayload(maximumRequestQuantity: 3),
    );

    await expectLater(
      SupabaseCustomerAfterSalesRepository(port: port).listOrderLines(_order),
      throwsA(
        isA<CustomerAfterSalesException>().having(
          (error) => error.code,
          'code',
          'unexpected',
        ),
      ),
    );
  });

  test('evidence usa ticket, bucket privato e resta pending scan', () async {
    final port = _Port();
    final id = await SupabaseCustomerAfterSalesRepository(port: port)
        .uploadEvidence(
          caseId: _case,
          input: CustomerAfterSalesEvidenceInput(
            bytes: Uint8List.fromList([1, 2, 3]),
            extension: 'jpg',
            mimeType: 'image/jpeg',
          ),
        );

    expect(id, _evidence);
    expect(port.functions, [
      'customer_after_sales_evidence_upload_ticket_v1',
      'customer_after_sales_evidence_register_v1',
    ]);
    expect(port.uploadedPath, '$_owner/$_case/$_ticket.jpg');
    expect(port.uploadedMimeType, 'image/jpeg');
  });

  test('MIME incoerente fallisce prima di ticket o upload', () async {
    final port = _Port();
    await expectLater(
      SupabaseCustomerAfterSalesRepository(port: port).uploadEvidence(
        caseId: _case,
        input: CustomerAfterSalesEvidenceInput(
          bytes: Uint8List.fromList([1]),
          extension: 'png',
          mimeType: 'image/jpeg',
        ),
      ),
      throwsA(
        isA<CustomerAfterSalesException>().having(
          (error) => error.code,
          'code',
          'invalid_evidence',
        ),
      ),
    );
    expect(port.functions, isEmpty);
    expect(port.uploadedPath, isNull);
  });
}

Map<String, Object?> _orderLinesPayload({int maximumRequestQuantity = 2}) => {
  'apiVersion': 'customer-after-sales-order-lines.v1',
  'status': 'ok',
  'orderId': _order,
  'shopSlug': 'test-shop',
  'items': [
    {
      'orderItemId': _orderItem,
      'name': 'Prodotto storico nascosto',
      'orderedQuantity': 3,
      'existingOpenQuantity': 1,
      'maximumRequestQuantity': maximumRequestQuantity,
    },
  ],
  'serverTime': '2026-08-23T12:00:00Z',
};

final class _Port implements CustomerAfterSalesPort {
  _Port({this.orderLinesPayload});

  final Map<String, Object?>? orderLinesPayload;
  final List<String> functions = [];
  String? uploadedPath;
  String? uploadedMimeType;

  @override
  Future<Object?> invoke(
    String function,
    Map<String, Object?> parameters,
  ) async {
    functions.add(function);
    return switch (function) {
      'customer_after_sales_order_lines_v1' =>
        orderLinesPayload ?? _orderLinesPayload(),
      'customer_after_sales_evidence_upload_ticket_v1' => {
        'apiVersion': 'customer-after-sales.v1',
        'status': 'ok',
        'ticketId': _ticket,
        'objectPath': '$_owner/$_case/$_ticket.jpg',
        'expiresAt': '2099-08-23T12:00:00Z',
      },
      'customer_after_sales_evidence_register_v1' => {
        'apiVersion': 'customer-after-sales.v1',
        'status': 'pending_scan',
        'evidenceId': _evidence,
      },
      _ => throw StateError(function),
    };
  }

  @override
  Future<void> uploadPrivate({
    required String objectPath,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    uploadedPath = objectPath;
    uploadedMimeType = mimeType;
  }
}
