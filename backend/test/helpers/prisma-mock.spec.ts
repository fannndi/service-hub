import { createPrismaMock } from './prisma-mock';

describe('PrismaMock', () => {
  it('should create and find records', async () => {
    const db = createPrismaMock();
    const created = await db.store.create({ data: { id: 's1', storeName: 'Test', isActive: true } });
    expect(created.id).toBe('s1');

    const found = await db.store.findUnique({ where: { id: 's1' } });
    expect(found).toBeDefined();
    expect(found!.storeName).toBe('Test');
  });

  it('should support transactions', async () => {
    const db = createPrismaMock();
    const result = await db.$transaction(async (tx) => {
      return tx.store.create({ data: { id: 't1', storeName: 'In Tx' } });
    });
    expect(result.id).toBe('t1');
  });

  it('should filter records', async () => {
    const db = createPrismaMock();
    await db.store.create({ data: { id: 'a', isActive: true } });
    await db.store.create({ data: { id: 'b', isActive: false } });
    const active = await db.store.findMany({ where: { isActive: true } });
    expect(active).toHaveLength(1);
  });

  it('should update records', async () => {
    const db = createPrismaMock();
    await db.store.create({ data: { id: 'u1', isActive: false } });
    await db.store.update({ where: { id: 'u1' }, data: { isActive: true } });
    const row = await db.store.findUnique({ where: { id: 'u1' } });
    expect(row!.isActive).toBe(true);
  });

  it('should seed and find seeded data', async () => {
    const db = createPrismaMock();
    db.seed('stores', 'seed-1', { id: 'seed-1', storeName: 'Seeded', isActive: true });
    const found = await db.store.findUnique({ where: { id: 'seed-1' } });
    expect(found).toBeDefined();
    expect(found!.storeName).toBe('Seeded');
  });

  it('should aggregate averages', async () => {
    const db = createPrismaMock();
    db.seed('reviews', 'r1', { rating: 5 });
    db.seed('reviews', 'r2', { rating: 3 });
    db.seed('reviews', 'r3', { rating: 4 });
    const agg = await db.review.aggregate({ _avg: { rating: true } });
    expect((agg._avg as Record<string, number>).rating).toBe(4);
  });
});
