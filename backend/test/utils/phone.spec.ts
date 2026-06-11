import { normalizePhone } from '../../src/common/utils/phone.util';

describe('normalizePhone', () => {
  it('should convert 62xxx to 0xxx', () => {
    expect(normalizePhone('628123456789')).toBe('08123456789');
  });

  it('should keep 0xxx format', () => {
    expect(normalizePhone('08123456789')).toBe('08123456789');
  });

  it('should prepend 0 to bare numbers', () => {
    expect(normalizePhone('8123456789')).toBe('08123456789');
  });

  it('should strip non-digit characters', () => {
    expect(normalizePhone('+62-812-345-6789')).toBe('08123456789');
  });

  it('should handle spaces', () => {
    expect(normalizePhone('0812 3456 789')).toBe('08123456789');
  });

  it('should handle empty string', () => {
    expect(normalizePhone('')).toBe('0');
  });
});
