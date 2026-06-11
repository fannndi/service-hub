import { customAlphabet } from 'nanoid';

export const nid = customAlphabet('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ', 6);

export function generateOrderNumber(): string {
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  return `SG-${dateStr}-${nid()}`;
}

export function generateCouponCode(): string {
  const ts = Date.now().toString(36).toUpperCase();
  const rand = nid().slice(0, 4);
  return `RWD-${ts}-${rand}`;
}
