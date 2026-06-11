import { generatePassword } from '../../src/common/utils/password.util';

describe('Password Generation', () => {
  it('should generate password from name and phone', () => {
    const result = generatePassword('Budi', '08123456789');
    expect(result).toBe('022104096789');
  });

  it('should pad short names with zeros', () => {
    const result = generatePassword('Al', '08123456789');
    expect(result).toBe('011200006789');
  });

  it('should use last 4 digits of phone', () => {
    const result = generatePassword('Budi', '08123450001');
    expect(result).toBe('022104090001');
  });

  it('should handle names with numbers', () => {
    const result = generatePassword('Budi123', '08123456789');
    expect(result).toBe('022104096789');
  });

  it('should handle full names (use first name only)', () => {
    const result = generatePassword('Budi Santoso', '08123456789');
    expect(result).toBe('022104096789');
  });

  it('should handle single character name', () => {
    const result = generatePassword('A', '08123456789');
    expect(result).toBe('010000006789');
  });
});
