import 'package:flutter_test/flutter_test.dart';
import 'package:servisgadget_foundation/features/customer/data/customer_repositories.dart';
import 'package:servisgadget_foundation/features/customer/domain/customer_models.dart';

void main() {
  test('normalizes Indonesian phone numbers to 0xxx format', () {
    expect(normalizePhone('081234567890'), '081234567890');
    expect(normalizePhone('6281234567890'), '081234567890');
    expect(normalizePhone('+6281234567890'), '081234567890');
    expect(normalizePhone('81234567890'), '081234567890');
  });

  test('create order request matches public customer booking contract', () {
    const request = CreateOrderRequest(
      storeId: 'store-1',
      fullName: 'Budi Santoso',
      phoneNumber: '081234567890',
      deviceType: 'android',
      brand: 'Samsung',
      deviceModel: 'Galaxy S24',
      deliveryMethod: 'walk_in',
      items: [
        CreateOrderItemInput(
            serviceType: 'screen_replacement',
            complaint: 'Layar retak cukup parah',
            sparepartId: 'part-1')
      ],
    );

    expect(request.toJson(), containsPair('storeId', 'store-1'));
    expect(request.toJson(), containsPair('phoneNumber', '081234567890'));
    expect(request.toJson()['items'], isA<List<dynamic>>());
    expect((request.toJson()['items'] as List).first,
        containsPair('sparepartId', 'part-1'));
  });

  group('OrderStatus', () {
    test('parses valid status values', () {
      expect(OrderStatus.parse('waiting_device'), OrderStatus.waitingDevice);
      expect(OrderStatus.parse('completed'), OrderStatus.completed);
      expect(OrderStatus.parse('cancelled'), OrderStatus.cancelled);
      expect(OrderStatus.parse('disputed'), OrderStatus.disputed);
    });

    test('returns waitingDevice for unknown values', () {
      expect(OrderStatus.parse('unknown'), OrderStatus.waitingDevice);
      expect(OrderStatus.parse(null), OrderStatus.waitingDevice);
    });

    test('isActive returns correct values', () {
      expect(OrderStatus.waitingDevice.isActive, true);
      expect(OrderStatus.repairing.isActive, true);
      expect(OrderStatus.completed.isActive, false);
      expect(OrderStatus.cancelled.isActive, false);
    });
  });

  group('CustomerUser', () {
    test('parses from JSON with snake_case keys', () {
      final user = CustomerUser.fromJson({
        'id': 'user-1',
        'full_name': 'Budi',
        'phone_number': '081234567890',
        'is_first_login': true,
      });
      expect(user.id, 'user-1');
      expect(user.fullName, 'Budi');
      expect(user.phoneNumber, '081234567890');
      expect(user.isFirstLogin, true);
    });

    test('parses from JSON with camelCase keys', () {
      final user = CustomerUser.fromJson({
        'id': 'user-1',
        'fullName': 'Budi',
        'phoneNumber': '081234567890',
        'isFirstLogin': false,
      });
      expect(user.fullName, 'Budi');
      expect(user.isFirstLogin, false);
    });

    test('copyWith creates modified copy', () {
      const user = CustomerUser(
        id: 'user-1',
        fullName: 'Budi',
        phoneNumber: '081234567890',
      );
      final updated = user.copyWith(fullName: 'Andi');
      expect(updated.fullName, 'Andi');
      expect(updated.id, 'user-1');
    });
  });

  group('CouponReward', () {
    test('parses from JSON', () {
      final coupon = CouponReward.fromJson({
        'code': 'RWD-ABC123',
        'amount': 10000,
        'expired_at': '2026-07-11T00:00:00Z',
      });
      expect(coupon.code, 'RWD-ABC123');
      expect(coupon.amount, 10000);
    });
  });
}
