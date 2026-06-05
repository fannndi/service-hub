import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

export function encryptCredential(plaintext: string): string {
  const key = Buffer.from(process.env.CREDENTIAL_ENCRYPTION_KEY!, 'hex');
  if (key.length !== 32) throw new Error('CREDENTIAL_ENCRYPTION_KEY harus 32 bytes (64 hex chars)');
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const enc = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${tag.toString('hex')}:${enc.toString('hex')}`;
}

export function decryptCredential(ciphertext: string): string {
  const key = Buffer.from(process.env.CREDENTIAL_ENCRYPTION_KEY!, 'hex');
  const parts = ciphertext.split(':');
  if (parts.length !== 3) throw new Error('Invalid ciphertext format');
  const [ivHex, tagHex, encHex] = parts;
  const dec = createDecipheriv('aes-256-gcm', key, Buffer.from(ivHex, 'hex'));
  dec.setAuthTag(Buffer.from(tagHex, 'hex'));
  return dec.update(Buffer.from(encHex, 'hex')).toString('utf8') + dec.final('utf8');
}
