const SECURE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
const ORDER_CHARS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const COUPON_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export function secureRandom(chars: string, length: number): string {
  const array = new Uint8Array(length);
  crypto.getRandomValues(array);
  return Array.from(array, (b) => chars[b % chars.length]).join('');
}

export function generatePassword(length = 12): string {
  return secureRandom(SECURE_CHARS, length);
}

export function generateOrderNumber(): string {
  const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const rand = secureRandom(ORDER_CHARS, 6);
  return `SG-${date}-${rand}`;
}

export function generateCouponCode(): string {
  return 'RWD-' + secureRandom(COUPON_CHARS, 8);
}

export function normalizePhone(raw: string): string {
  return raw.replace(/\D/g, '').replace(/^62/, '08').replace(/^8/, '08');
}
