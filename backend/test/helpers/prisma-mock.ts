/**
 * PrismaMock — lightweight in-memory Prisma substitute for service-layer tests.
 * Supports the subset of PrismaClient used by ServisGadget modules.
 */

type Row = Record<string, unknown>;

export class PrismaMock {
  private _tables: Record<string, Record<string, Row>> = {
    users: {},
    stores: {},
    storeAdmins: {},
    serviceOrders: {},
    orderItems: {},
    spareParts: {},
    payments: {},
    reviews: {},
    coupons: {},
    disputes: {},
    serviceTracking: {},
    userSessions: {},
  };

  // ─── Table proxies ────────────────────────────────────────────────────────
  get store() { return this._proxy('stores'); }
  get user() { return this._proxy('users'); }
  get storeAdmin() { return this._proxy('storeAdmins'); }
  get serviceOrder() { return this._proxy('serviceOrders'); }
  get orderItem() { return this._proxy('orderItems'); }
  get sparePart() { return this._proxy('spareParts'); }
  get payment() { return this._proxy('payments'); }
  get review() { return this._proxy('reviews'); }
  get coupon() { return this._proxy('coupons'); }
  get dispute() { return this._proxy('disputes'); }
  get serviceTracking() { return this._proxy('serviceTracking'); }
  get userSession() { return this._proxy('userSessions'); }

  $transaction<T>(fn: (tx: PrismaMock) => Promise<T>): Promise<T> {
    return fn(this);
  }

  // ─── Direct access for seeding ─────────────────────────────────────────────
  seed(table: string, id: string, row: Row) {
    this._tables[table][id] = { ...row };
  }

  rows(table: string): Row[] {
    return Object.values(this._tables[table]);
  }

  // ─── Internal ──────────────────────────────────────────────────────────────
  private _proxy(table: string) {
    const rows = this._tables[table];
    const parent = this;

    return {
      findUnique:  (a: { where: Row }) => this._find(rows, a.where),
      findFirst:   (a: { where: Row; include?: unknown }) => this._findFirst(rows, a.where),
      findMany:    (a?: { where?: Row; orderBy?: unknown; include?: unknown }) =>
        a?.where ? this._filter(rows, a.where) : Object.values(rows),
      findUniqueOrThrow: (a: { where: Row }) => {
        const r = this._find(rows, a.where);
        if (!r) throw new Error(`Not found in ${table}`);
        return r;
      },
      create: (a: { data: Row }) => {
        const id = (a.data.id as string) || parent._id();
        const row = { ...a.data, id, createdAt: new Date(), updatedAt: new Date() };
        rows[id] = row;
        return row;
      },
      update: (a: { where: Row; data: Row }) => {
        const id = a.where.id as string;
        if (!rows[id]) throw new Error(`Not found in ${table}: ${id}`);
        Object.assign(rows[id], a.data);
        return rows[id];
      },
      updateMany: (a: { where: Row; data: Row }) => {
        let count = 0;
        for (const r of Object.values(rows)) {
          if (parent._match(r, a.where)) { Object.assign(r, a.data); count++; }
        }
        return { count };
      },
      upsert: (a: { where: Row; create: Row; update: Row }) => {
        const id = a.where.id as string;
        if (rows[id]) { Object.assign(rows[id], a.update); return rows[id]; }
        const nid = (a.create.id as string) || parent._id();
        rows[nid] = { ...a.create, id: nid, createdAt: new Date(), updatedAt: new Date() };
        return rows[nid];
      },
      delete: (a: { where: Row }) => {
        const id = a.where.id as string;
        if (!rows[id]) throw new Error(`Not found in ${table}: ${id}`);
        const r = rows[id]; delete rows[id]; return r;
      },
      count: (a?: { where?: Row }) =>
        a?.where ? this._filter(rows, a.where).length : Object.values(rows).length,
      aggregate: (a?: { _avg?: Record<string, boolean>; _count?: Record<string, boolean>; where?: Row }) => {
        const items = a?.where ? this._filter(rows, a.where) : Object.values(rows);
        const out: Record<string, unknown> = {};
        if (a?._avg) {
          for (const f of Object.keys(a._avg)) {
            const nums = items.map(r => Number(r[f])).filter(n => !isNaN(n));
            out._avg = { [f]: nums.length ? nums.reduce((a, b) => a + b, 0) / nums.length : 0 };
          }
        }
        if (a?._count) out._count = items.length;
        return out;
      },
    };
  }

  private _find(rows: Record<string, Row>, where: Row): Row | null {
    if (where.id) return rows[where.id as string] ?? null;
    for (const r of Object.values(rows)) if (this._match(r, where)) return r;
    return null;
  }

  private _findFirst(rows: Record<string, Row>, where: Row): Row | null {
    for (const r of Object.values(rows)) if (this._match(r, where)) return r;
    return null;
  }

  private _filter(rows: Record<string, Row>, where: Row): Row[] {
    return Object.values(rows).filter(r => this._match(r, where));
  }

  private _match(row: Row, where: Row): boolean {
    for (const [k, v] of Object.entries(where)) {
      if (v === undefined) continue;
      if (v === null && row[k] !== null && row[k] !== undefined) return false;
      if (v !== null && typeof v === 'object') {
        const op = v as Record<string, unknown>;
        if ('gt' in op && !(Number(row[k]) > Number(op.gt))) return false;
        if ('lt' in op && !(Number(row[k]) < Number(op.lt))) return false;
        if ('gte' in op && !(Number(row[k]) >= Number(op.gte))) return false;
        if ('lte' in op && !(Number(row[k]) <= Number(op.lte))) return false;
        if ('in' in op && !(op.in as unknown[]).includes(row[k])) return false;
        if ('notIn' in op && (op.notIn as unknown[]).includes(row[k])) return false;
        continue;
      }
      if (row[k] !== v) return false;
    }
    return true;
  }

  private _id(): string {
    return `t${Date.now()}${Math.random().toString(36).slice(2, 7)}`;
  }
}

export function createPrismaMock(): PrismaMock {
  return new PrismaMock();
}
