import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  const storeAdminPassword = process.env.SEED_STORE_ADMIN_PASSWORD || 'admin123';
  const customerPassword = process.env.SEED_CUSTOMER_PASSWORD || 'customer123';
  const platformAdminPassword = process.env.SEED_PLATFORM_ADMIN_PASSWORD || 'admin';

  const store = await prisma.store.upsert({
    where: { id: 'store-01' },
    update: {},
    create: {
      id: 'store-01',
      storeName: 'ServisGadget Pusat',
      address: 'Jl. Teknologi No. 42, Jakarta Selatan',
      phoneNumber: '081234567890',
      isActive: true,
      config: {
        service_fee: {
          screen_replacement: 50000,
          battery_replacement: 30000,
          charging_port: 25000,
          camera: 40000,
          other: 20000,
        },
        warranty_days: 30,
        diagnosis_fee: 20000,
        low_stock_threshold: 2,
        deposit_required: false,
      },
      operationalHours: {
        mon: '08:00-20:00',
        tue: '08:00-20:00',
        wed: '08:00-20:00',
        thu: '08:00-20:00',
        fri: '08:00-20:00',
        sat: '09:00-17:00',
        sun: 'closed',
      },
    },
  });
  console.log(`Store created: ${store.storeName}`);

  const adminPasswordHash = await bcrypt.hash(storeAdminPassword, 12);
  const admin = await prisma.storeAdmin.upsert({
    where: { id: 'admin-01' },
    update: {},
    create: {
      id: 'admin-01',
      storeId: store.id,
      fullName: 'Admin Toko Pusat',
      phoneNumber: '081234567890',
      passwordHash: adminPasswordHash,
      isActive: true,
      isFirstLogin: false,
    },
  });
  console.log(`Store admin created: ${admin.fullName}`);

  const customerPasswordHash = await bcrypt.hash(customerPassword, 12);
  const customer1 = await prisma.user.upsert({
    where: { id: 'user-01' },
    update: {},
    create: {
      id: 'user-01',
      fullName: 'Budi Santoso',
      phoneNumber: '081212345678',
      passwordHash: customerPasswordHash,
      isFirstLogin: false,
      address: 'Jl. Merdeka No. 10, Jakarta Pusat',
    },
  });
  console.log(`Customer created: ${customer1.fullName}`);

  const spareparts = [
    // ── Samsung ──
    { id: 'sp-01', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S24', partType: 'screen_replacement', partName: 'Samsung S24 LCD Assembly', price: 2500000, qty: 10 },
    { id: 'sp-03', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S24', partType: 'battery_replacement', partName: 'Samsung S24 Battery', price: 450000, qty: 15 },
    { id: 'sp-06', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S24', partType: 'charging_port', partName: 'Samsung S24 Charging Port Flex', price: 280000, qty: 8 },
    { id: 'sp-07', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S24', partType: 'camera', partName: 'Samsung S24 Main Camera Module', price: 1200000, qty: 6 },
    { id: 'sp-08', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S23', partType: 'screen_replacement', partName: 'Samsung S23 LCD Assembly', price: 2200000, qty: 5 },
    { id: 'sp-09', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S23', partType: 'battery_replacement', partName: 'Samsung S23 Battery', price: 400000, qty: 10 },
    { id: 'sp-10', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy A55', partType: 'screen_replacement', partName: 'Samsung A55 LCD', price: 1500000, qty: 7 },
    { id: 'sp-11', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy A55', partType: 'battery_replacement', partName: 'Samsung A55 Battery', price: 350000, qty: 12 },
    // ── iPhone ──
    { id: 'sp-02', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 15', partType: 'screen_replacement', partName: 'iPhone 15 OLED Display', price: 3500000, qty: 5 },
    { id: 'sp-05', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 15', partType: 'charging_port', partName: 'iPhone 15 Charging Port Flex', price: 350000, qty: 12 },
    { id: 'sp-12', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 15', partType: 'battery_replacement', partName: 'iPhone 15 Battery', price: 650000, qty: 8 },
    { id: 'sp-13', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 15', partType: 'camera', partName: 'iPhone 15 Main Camera', price: 2200000, qty: 4 },
    { id: 'sp-14', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 14', partType: 'screen_replacement', partName: 'iPhone 14 OLED Display', price: 2800000, qty: 6 },
    { id: 'sp-15', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 13', partType: 'screen_replacement', partName: 'iPhone 13 LCD', price: 1800000, qty: 4 },
    { id: 'sp-16', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 13', partType: 'battery_replacement', partName: 'iPhone 13 Battery', price: 500000, qty: 10 },
    // ── Xiaomi ──
    { id: 'sp-04', storeId: store.id, brand: 'Xiaomi', deviceModel: 'Redmi Note 13', partType: 'screen_replacement', partName: 'Redmi Note 13 LCD', price: 800000, qty: 8 },
    { id: 'sp-17', storeId: store.id, brand: 'Xiaomi', deviceModel: 'Redmi Note 13', partType: 'battery_replacement', partName: 'Redmi Note 13 Battery', price: 250000, qty: 12 },
    { id: 'sp-18', storeId: store.id, brand: 'Xiaomi', deviceModel: 'Redmi Note 13', partType: 'charging_port', partName: 'Redmi Note 13 Charging Port', price: 150000, qty: 10 },
    { id: 'sp-19', storeId: store.id, brand: 'Xiaomi', deviceModel: 'Poco X6 Pro', partType: 'screen_replacement', partName: 'Poco X6 Pro LCD', price: 950000, qty: 6 },
    { id: 'sp-20', storeId: store.id, brand: 'Xiaomi', deviceModel: 'Poco X6 Pro', partType: 'battery_replacement', partName: 'Poco X6 Pro Battery', price: 300000, qty: 8 },
    { id: 'sp-21', storeId: store.id, brand: 'Xiaomi', deviceModel: 'Xiaomi 14T', partType: 'screen_replacement', partName: 'Xiaomi 14T AMOLED', price: 1600000, qty: 5 },
    // ── Oppo ──
    { id: 'sp-22', storeId: store.id, brand: 'Oppo', deviceModel: 'Reno 11', partType: 'screen_replacement', partName: 'Oppo Reno 11 LCD', price: 900000, qty: 7 },
    { id: 'sp-23', storeId: store.id, brand: 'Oppo', deviceModel: 'Reno 11', partType: 'battery_replacement', partName: 'Oppo Reno 11 Battery', price: 300000, qty: 10 },
    { id: 'sp-24', storeId: store.id, brand: 'Oppo', deviceModel: 'Find X7', partType: 'screen_replacement', partName: 'Oppo Find X7 AMOLED', price: 2000000, qty: 4 },
    { id: 'sp-25', storeId: store.id, brand: 'Oppo', deviceModel: 'A79', partType: 'screen_replacement', partName: 'Oppo A79 LCD', price: 600000, qty: 9 },
    { id: 'sp-26', storeId: store.id, brand: 'Oppo', deviceModel: 'A79', partType: 'charging_port', partName: 'Oppo A79 Charging Port Flex', price: 120000, qty: 12 },
    // ── Vivo ──
    { id: 'sp-27', storeId: store.id, brand: 'Vivo', deviceModel: 'V30', partType: 'screen_replacement', partName: 'Vivo V30 AMOLED', price: 1100000, qty: 6 },
    { id: 'sp-28', storeId: store.id, brand: 'Vivo', deviceModel: 'V30', partType: 'battery_replacement', partName: 'Vivo V30 Battery', price: 320000, qty: 8 },
    { id: 'sp-29', storeId: store.id, brand: 'Vivo', deviceModel: 'Y100', partType: 'screen_replacement', partName: 'Vivo Y100 LCD', price: 550000, qty: 10 },
    { id: 'sp-30', storeId: store.id, brand: 'Vivo', deviceModel: 'Y100', partType: 'charging_port', partName: 'Vivo Y100 Charging Port', price: 100000, qty: 14 },
    // ── Google Pixel ──
    { id: 'sp-31', storeId: store.id, brand: 'Google', deviceModel: 'Pixel 8', partType: 'screen_replacement', partName: 'Pixel 8 OLED Display', price: 2800000, qty: 3 },
    { id: 'sp-32', storeId: store.id, brand: 'Google', deviceModel: 'Pixel 8', partType: 'battery_replacement', partName: 'Pixel 8 Battery', price: 500000, qty: 6 },
    { id: 'sp-33', storeId: store.id, brand: 'Google', deviceModel: 'Pixel 7A', partType: 'screen_replacement', partName: 'Pixel 7A LCD', price: 1200000, qty: 4 },
    // ── OnePlus ──
    { id: 'sp-34', storeId: store.id, brand: 'OnePlus', deviceModel: 'OnePlus 12', partType: 'screen_replacement', partName: 'OnePlus 12 AMOLED', price: 2300000, qty: 4 },
    { id: 'sp-35', storeId: store.id, brand: 'OnePlus', deviceModel: 'OnePlus 12', partType: 'battery_replacement', partName: 'OnePlus 12 Battery', price: 420000, qty: 7 },
    { id: 'sp-36', storeId: store.id, brand: 'OnePlus', deviceModel: 'Nord 4', partType: 'screen_replacement', partName: 'OnePlus Nord 4 LCD', price: 1000000, qty: 5 },
    // ── Realme ──
    { id: 'sp-37', storeId: store.id, brand: 'Realme', deviceModel: 'Realme 13 Pro', partType: 'screen_replacement', partName: 'Realme 13 Pro AMOLED', price: 850000, qty: 6 },
    { id: 'sp-38', storeId: store.id, brand: 'Realme', deviceModel: 'Realme 13 Pro', partType: 'battery_replacement', partName: 'Realme 13 Pro Battery', price: 280000, qty: 9 },
    // ── Asus ──
    { id: 'sp-39', storeId: store.id, brand: 'Asus', deviceModel: 'Zenfone 10', partType: 'screen_replacement', partName: 'Asus Zenfone 10 AMOLED', price: 1700000, qty: 3 },
    { id: 'sp-40', storeId: store.id, brand: 'Asus', deviceModel: 'Zenfone 10', partType: 'battery_replacement', partName: 'Asus Zenfone 10 Battery', price: 380000, qty: 5 },
    // ── Huawei ──
    { id: 'sp-41', storeId: store.id, brand: 'Huawei', deviceModel: 'Pura 70', partType: 'screen_replacement', partName: 'Huawei Pura 70 OLED', price: 2500000, qty: 4 },
    { id: 'sp-42', storeId: store.id, brand: 'Huawei', deviceModel: 'Pura 70', partType: 'battery_replacement', partName: 'Huawei Pura 70 Battery', price: 550000, qty: 6 },
    { id: 'sp-43', storeId: store.id, brand: 'Huawei', deviceModel: 'Nova 12', partType: 'screen_replacement', partName: 'Huawei Nova 12 LCD', price: 750000, qty: 7 },
    // ── Other spareparts (back panel, speaker, etc) ──
    { id: 'sp-44', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S24', partType: 'other', partName: 'Samsung S24 Back Cover Glass', price: 350000, qty: 6 },
    { id: 'sp-45', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 15', partType: 'other', partName: 'iPhone 15 Back Glass', price: 550000, qty: 4 },
    { id: 'sp-46', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy S24', partType: 'other', partName: 'Samsung S24 Earpiece Speaker', price: 180000, qty: 8 },
    { id: 'sp-47', storeId: store.id, brand: 'iPhone', deviceModel: 'iPhone 15', partType: 'other', partName: 'iPhone 15 Taptic Engine', price: 250000, qty: 5 },
    { id: 'sp-48', storeId: store.id, brand: 'Xiaomi', deviceModel: 'Redmi Note 13', partType: 'camera', partName: 'Redmi Note 13 Main Camera', price: 400000, qty: 6 },
    { id: 'sp-49', storeId: store.id, brand: 'Oppo', deviceModel: 'Reno 11', partType: 'camera', partName: 'Oppo Reno 11 Main Camera', price: 500000, qty: 5 },
    { id: 'sp-50', storeId: store.id, brand: 'Samsung', deviceModel: 'Galaxy A55', partType: 'charging_port', partName: 'Samsung A55 Charging Port', price: 200000, qty: 10 },
  ];

  for (const sp of spareparts) {
    await prisma.sparePart.upsert({
      where: { id: sp.id },
      update: {},
      create: sp,
    });
  }
  console.log(`${spareparts.length} spareparts created`);

  const platformAdminPasswordHash = await bcrypt.hash(platformAdminPassword, 12);
  const platformAdmin = await prisma.platformAdmin.upsert({
    where: { username: 'admin' },
    update: {},
    create: {
      username: 'admin',
      fullName: 'Platform Admin',
      passwordHash: platformAdminPasswordHash,
      isActive: true,
    },
  });
  console.log(`Platform admin created: ${platformAdmin.username}`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
    console.log('Seed completed successfully!');
  })
  .catch(async (e: unknown) => {
    console.error('Seed failed:', e instanceof Error ? e.message : String(e));
    await prisma.$disconnect();
    process.exit(1);
  });
