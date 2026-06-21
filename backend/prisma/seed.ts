import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  const platformAdminPassword = process.env.SEED_PLATFORM_ADMIN_PASSWORD || 'admin';
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

  console.log(`Platform admin seeded: ${platformAdmin.username}`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
    console.log('Seed done.');
  })
  .catch(async (e: unknown) => {
    console.error('Seed failed:', e instanceof Error ? e.message : String(e));
    await prisma.$disconnect();
    process.exit(1);
  });
