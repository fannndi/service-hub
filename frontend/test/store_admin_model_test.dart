import 'package:flutter_test/flutter_test.dart';
import 'package:servisgadget_foundation/features/store_admin/domain/store_admin_models.dart';

void main() {
  group('StoreOrderStatus', () {
    test('parses valid status values', () {
      expect(StoreOrderStatus.fromJson('waiting_device'), StoreOrderStatus.waitingDevice);
      expect(StoreOrderStatus.fromJson('completed'), StoreOrderStatus.completed);
      expect(StoreOrderStatus.fromJson('cancelled'), StoreOrderStatus.cancelled);
    });

    test('returns waitingDevice for unknown values', () {
      expect(StoreOrderStatus.fromJson('unknown'), StoreOrderStatus.waitingDevice);
      expect(StoreOrderStatus.fromJson(null), StoreOrderStatus.waitingDevice);
    });
  });

  group('Sparepart', () {
    test('calculates availableStock correctly', () {
      const sp = Sparepart(
        id: 'sp-1',
        brand: 'Samsung',
        deviceModel: 'Galaxy S24',
        partType: 'screen_replacement',
        partName: 'LCD Samsung',
        price: 500000,
        qty: 10,
        qtyReserved: 3,
        status: 'available',
      );
      expect(sp.availableStock, 7);
    });

    test('isLowStock returns true when availableStock <= 2', () {
      const sp = Sparepart(
        id: 'sp-1',
        brand: 'Samsung',
        deviceModel: 'Galaxy S24',
        partType: 'screen_replacement',
        partName: 'LCD Samsung',
        price: 500000,
        qty: 5,
        qtyReserved: 4,
        status: 'available',
      );
      expect(sp.isLowStock, true);
    });

    test('isLowStock returns false when availableStock > 2', () {
      const sp = Sparepart(
        id: 'sp-1',
        brand: 'Samsung',
        deviceModel: 'Galaxy S24',
        partType: 'screen_replacement',
        partName: 'LCD Samsung',
        price: 500000,
        qty: 10,
        qtyReserved: 3,
        status: 'available',
      );
      expect(sp.isLowStock, false);
    });
  });

  group('StoreAdminSession', () {
    test('serializes to and from storage', () {
      const session = StoreAdminSession(
        adminId: 'admin-1',
        adminName: 'Admin Toko',
        phoneNumber: '081234567890',
        storeId: 'store-1',
        storeName: 'Toko Servis',
        isFirstLogin: false,
      );

      final storage = session.toStorage();
      final restored = StoreAdminSession.fromStorage(storage);

      expect(restored.adminId, 'admin-1');
      expect(restored.adminName, 'Admin Toko');
      expect(restored.storeId, 'store-1');
      expect(restored.isFirstLogin, false);
    });

    test('copyWith creates modified copy', () {
      const session = StoreAdminSession(
        adminId: 'admin-1',
        adminName: 'Admin',
        phoneNumber: '081234567890',
        storeId: 'store-1',
        storeName: 'Toko',
        isFirstLogin: true,
      );

      final updated = session.copyWith(isFirstLogin: false);
      expect(updated.isFirstLogin, false);
      expect(updated.adminId, 'admin-1');
    });
  });

  group('DisputeStatus', () {
    test('parses valid status values', () {
      expect(DisputeStatus.fromJson('open'), DisputeStatus.open);
      expect(DisputeStatus.fromJson('store_accepted'), DisputeStatus.storeAccepted);
      expect(DisputeStatus.fromJson('store_rejected'), DisputeStatus.storeRejected);
    });
  });
}
