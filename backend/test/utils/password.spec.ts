import { generatePassword } from '../../src/common/utils/password.util';

describe('Password Generation', () => {
  it('should generate 12-character password', () => {
    const result = generatePassword();
    expect(result).toHaveLength(12);
    expect(result).toMatch(/^[A-Za-z0-9]+$/);
  });

  it('should produce different passwords each call', () => {
    const set = new Set(Array.from({ length: 10 }, () => generatePassword()));
    expect(set.size).toBeGreaterThanOrEqual(8);
  });
});
