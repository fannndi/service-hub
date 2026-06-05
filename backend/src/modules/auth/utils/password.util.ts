export function generatePassword(fullName: string, phoneNumber: string): string {
  const firstName = fullName.trim().split(/\s+/)[0].toUpperCase();
  const letters = firstName.replace(/[^A-Z]/g, '');
  const padded = letters.padEnd(4, '_').substring(0, 4);
  const part1 = padded
    .split('')
    .map((c) => (c === '_' ? '00' : String(c.charCodeAt(0) - 64).padStart(2, '0')))
    .join('');
  const digits = phoneNumber.replace(/\D/g, '');
  return part1 + digits.slice(-4);
}

export function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (d.startsWith('62')) return `+${d}`;
  if (d.startsWith('0')) return `+62${d.slice(1)}`;
  return `+62${d}`;
}
