/**
 * Test Factory for Creating Test Data
 *
 * Provides helper functions to create test data for integration tests.
 */

import { PrismaMock } from './prisma-mock';

export interface TestStore {
  id: string;
  storeName: string;
  address: string;
  phoneNumber: string;
  isActive: boolean;
  ratingAvg: number;
  totalCompleted: number;
  config: Record<string, unknown>;
}

export interface TestUser {
  id: string;
  fullName: string;
  phoneNumber: string;
  passwordHash: string;
  isFirstLogin: boolean;
  isCredentialSent: boolean;
  credentialPlainEnc: string | null;
}

export interface TestStoreAdmin {
  id: string;
  storeId: string;
  fullName: string;
  phoneNumber: string;
  passwordHash: string;
  isActive: boolean;
  isFirstLogin: boolean;
}

export interface TestSparePart {
  id: string;
  storeId: string;
  brand: string;
  deviceModel: string;
  partType: string;
  partName: string;
  price: number;
  qty: number;
  qtyReserved: number;
  status: string;
}

export interface TestOrder {
  id: string;
  userId: string;
  storeId: string;
  orderNumber: string;
  deviceType: string;
  brand: string;
  deviceModel: string;
  deliveryMethod: string;
  status: string;
  paymentStatus: string;
  totalEstimasi: number;
  finalPrice: number | null;
  serviceFee: number | null;
  slaDeadline: Date | null;
  warrantyDays: number | null;
  warrantyExpiredAt: Date | null;
  isWarrantyOrder: boolean;
  parentOrderId: string | null;
}

export function createTestStore(overrides?: Partial<TestStore>): TestStore {
  return {
    id: 'store-001',
    storeName: 'Toko Servis ABC',
    address: 'Jl. Contoh No. 123, Yogyakarta',
    phoneNumber: '081234567890',
    isActive: true,
    ratingAvg: 4.5,
    totalCompleted: 10,
    config: {
      warranty_days: 30,
      diagnosis_fee: 20000,
      service_fee: { screen_replacement: 50000 },
      low_stock_threshold: 2,
    },
    ...overrides,
  };
}

export function createTestUser(overrides?: Partial<TestUser>): TestUser {
  return {
    id: 'user-001',
    fullName: 'Budi Santoso',
    phoneNumber: '081234567890',
    passwordHash: '$2b$12$LJ3m4ys3Lg.MkH6oQXwEY.YgZtL8dK6pY7vN2qR5sT8uI1oP3kL9',
    isFirstLogin: false,
    isCredentialSent: true,
    credentialPlainEnc: null,
    ...overrides,
  };
}

export function createTestStoreAdmin(overrides?: Partial<TestStoreAdmin>): TestStoreAdmin {
  return {
    id: 'admin-001',
    storeId: 'store-001',
    fullName: 'Admin Toko',
    phoneNumber: '081112223333',
    passwordHash: '$2b$12$LJ3m4ys3Lg.MkH6oQXwEY.YgZtL8dK6pY7vN2qR5sT8uI1oP3kL9',
    isActive: true,
    isFirstLogin: false,
    ...overrides,
  };
}

export function createTestSparePart(overrides?: Partial<TestSparePart>): TestSparePart {
  return {
    id: 'sparepart-001',
    storeId: 'store-001',
    brand: 'Samsung',
    deviceModel: 'Galaxy S24',
    partType: 'screen_replacement',
    partName: 'Layar Samsung Galaxy S24',
    price: 800000,
    qty: 10,
    qtyReserved: 2,
    status: 'available',
    ...overrides,
  };
}

export function createTestOrder(overrides?: Partial<TestOrder>): TestOrder {
  return {
    id: 'order-001',
    userId: 'user-001',
    storeId: 'store-001',
    orderNumber: 'SG-20260617-ABC123',
    deviceType: 'android',
    brand: 'Samsung',
    deviceModel: 'Galaxy S24',
    deliveryMethod: 'walk_in',
    status: 'waiting_device',
    paymentStatus: 'unpaid',
    totalEstimasi: 800000,
    finalPrice: null,
    serviceFee: null,
    slaDeadline: new Date(Date.now() + 24 * 60 * 60 * 1000),
    warrantyDays: null,
    warrantyExpiredAt: null,
    isWarrantyOrder: false,
    parentOrderId: null,
    ...overrides,
  };
}

export function seedTestData(db: PrismaMock) {
  const store = createTestStore();
  const user = createTestUser();
  const storeAdmin = createTestStoreAdmin();
  const sparepart = createTestSparePart();

  db.seed('stores', store.id, store as unknown as Record<string, unknown>);
  db.seed('users', user.id, user as unknown as Record<string, unknown>);
  db.seed('storeAdmins', storeAdmin.id, storeAdmin as unknown as Record<string, unknown>);
  db.seed('spareParts', sparepart.id, sparepart as unknown as Record<string, unknown>);

  return { store, user, storeAdmin, sparepart };
}
