import 'package:flutter_test/flutter_test.dart';
import 'package:servisgadget_foundation/features/customer/data/customer_repositories.dart';
import 'package:servisgadget_foundation/features/customer/domain/customer_models.dart';

void main() {
  test('normalizes Indonesian phone numbers for auth requests', () {
    expect(normalizePhone('081234567890'), '+6281234567890');
    expect(normalizePhone('6281234567890'), '+6281234567890');
    expect(normalizePhone('+6281234567890'), '+6281234567890');
  });

  test('create order request matches public customer booking contract', () {
    final request = CreateOrderRequest(
      storeId: 'store-1',
      fullName: 'Budi Santoso',
      phoneNumber: '+6281234567890',
      deviceType: 'android',
      brand: 'Samsung',
      deviceModel: 'Galaxy S24',
      deliveryMethod: 'walk_in',
      items: const [CreateOrderItemInput(serviceType: 'screen_replacement', complaint: 'Layar retak cukup parah', sparepartId: 'part-1')],
    );

    expect(request.toJson(), containsPair('storeId', 'store-1'));
    expect(request.toJson(), containsPair('phoneNumber', '+6281234567890'));
    expect(request.toJson()['items'], isA<List<dynamic>>());
    expect((request.toJson()['items'] as List).first, containsPair('sparepartId', 'part-1'));
  });
}
