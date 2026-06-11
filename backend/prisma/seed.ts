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
    {
      id: 'sp-01',
      storeId: store.id,
      brand: 'Samsung',
      deviceModel: 'Galaxy S24',
      partType: 'screen_replacement',
      partName: 'Samsung S24 LCD Assembly',
      price: 2500000,
      qty: 10,
    },
    {
      id: 'sp-02',
      storeId: store.id,
      brand: 'iPhone',
      deviceModel: 'iPhone 15',
      partType: 'screen_replacement',
      partName: 'iPhone 15 OLED Display',
      price: 3500000,
      qty: 5,
    },
    {
      id: 'sp-03',
      storeId: store.id,
      brand: 'Samsung',
      deviceModel: 'Galaxy S24',
      partType: 'battery_replacement',
      partName: 'Samsung S24 Battery',
      price: 450000,
      qty: 15,
    },
    {
      id: 'sp-04',
      storeId: store.id,
      brand: 'Xiaomi',
      deviceModel: 'Redmi Note 13',
      partType: 'screen_replacement',
      partName: 'Redmi Note 13 LCD',
      price: 800000,
      qty: 8,
    },
    {
      id: 'sp-05',
      storeId: store.id,
      brand: 'iPhone',
      deviceModel: 'iPhone 15',
      partType: 'charging_port',
      partName: 'iPhone 15 Charging Port Flex',
      price: 350000,
      qty: 12,
    },
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
