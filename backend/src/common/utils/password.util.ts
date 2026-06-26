import { randomBytes } from 'crypto';

export function generatePassword(): string {
  return randomBytes(9).toString('base64').replace(/[^a-zA-Z0-9]/g, '').slice(0, 12);
}
