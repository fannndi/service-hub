export function normalizePhone(phone: string): string {
  const d = phone.replace(/\D/g, '');
  if (d.startsWith('62')) return `0${d.slice(2)}`;
  if (d.startsWith('0')) return d;
  return `0${d}`;
}
