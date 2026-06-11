import { encryptCredential, decryptCredential } from '../../src/common/utils/encryption.util';

describe('Encryption', () => {
  const validKey = 'a'.repeat(64);

  it('should encrypt and decrypt a string', () => {
    const plaintext = 'Hello, World!';
    const encrypted = encryptCredential(plaintext, validKey);
    const decrypted = decryptCredential(encrypted, validKey);
    expect(decrypted).toBe(plaintext);
  });

  it('should produce different ciphertexts for same plaintext', () => {
    const plaintext = 'test123';
    const enc1 = encryptCredential(plaintext, validKey);
    const enc2 = encryptCredential(plaintext, validKey);
    expect(enc1).not.toBe(enc2);
  });

  it('should produce ciphertext in iv:tag:enc format', () => {
    const encrypted = encryptCredential('test', validKey);
    const parts = encrypted.split(':');
    expect(parts).toHaveLength(3);
  });

  it('should throw on invalid key length', () => {
    expect(() => encryptCredential('test', 'short')).toThrow('CREDENTIAL_ENCRYPTION_KEY must be 32 bytes');
  });

  it('should throw on invalid ciphertext format', () => {
    expect(() => decryptCredential('invalid', validKey)).toThrow('Invalid ciphertext format');
  });

  it('should handle empty string', () => {
    const encrypted = encryptCredential('', validKey);
    const decrypted = decryptCredential(encrypted, validKey);
    expect(decrypted).toBe('');
  });

  it('should handle unicode characters', () => {
    const plaintext = 'Halo! 🎉';
    const encrypted = encryptCredential(plaintext, validKey);
    const decrypted = decryptCredential(encrypted, validKey);
    expect(decrypted).toBe(plaintext);
  });
});
