import 'package:flutter_test/flutter_test.dart';
import 'package:servisgadget_foundation/features/store_admin/domain/store_admin_models.dart';

void main() {
  test('parses order workflow actions from backend response', () {
    final order = StoreOrder.fromJson({
      'id': 'order-1',
      'orderNumber': 'SG-1',
      'status': 'diagnosing',
      'allowedActions': ['submit_diagnosis'],
      'items': [],
      'payments': [],
      'trackingEvents': [],
    });

    expect(order.status, StoreOrderStatus.diagnosing);
    expect(order.allowedActions, ['submit_diagnosis']);
  });

  test('detects low available sparepart stock', () {
    final item = Sparepart.fromJson({'id': 'sp-1', 'name': 'LCD', 'qty': 3, 'qtyReserved': 2, 'price': 450000});

    expect(item.availableStock, 1);
    expect(item.isLowStock, isTrue);
  });
}
