# Backend Authentication System

> Sistem autentikasi ServisGadget menggunakan **3 sistem JWT terpisah** untuk 3 role berbeda.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Customer Auth](#2-customer-auth)
3. [Store Admin Auth](#3-store-admin-auth)
4. [Platform Admin Auth](#4-platform-admin-auth)
5. [Password Generation](#5-password-generation)
6. [Credential Encryption](#6-credential-encryption)
7. [Security Features](#7-security-features)
8. [Guards & Decorators](#8-guards--decorators)

---

## 1. Overview

| Role | Strategy Name | Access Secret | Refresh Secret | Token Type |
|------|---------------|---------------|----------------|------------|
| Customer | `jwt-access` | `JWT_ACCESS_SECRET` | `JWT_REFRESH_SECRET` | Access + Refresh |
| Store Admin | `store-jwt-access` | `JWT_STORE_ACCESS_SECRET` | `JWT_STORE_REFRESH_SECRET` | Access + Refresh |
| Platform Admin | `platform-admin-jwt` | `JWT_PLATFORM_ADMIN_SECRET` | - | Access only |

**Format JWT Payload:**
```typescript
interface JwtPayload {
  sub: string;          // User ID
  role: 'customer' | 'store_admin';
  storeId?: string;     // Hanya untuk store admin
  isFirstLogin?: boolean; // Hanya untuk customer
  iat?: number;
  exp?: number;
}
```

**Token Configuration:**
- Access Token TTL: `JWT_ACCESS_EXPIRES_IN` (default: `1h`)
- Refresh Token TTL: `JWT_REFRESH_EXPIRES_IN` (default: `30d`)

---

## 2. Customer Auth

### Flow Login

```
Customer → POST /auth/login { phoneNumber, password }
  ↓
AuthService.login()
  ↓
1. Normalize phone (0xxx format)
2. Find user by phoneNumber
3. Check accountStatus ≠ 'suspended'
4. Check lockedUntil belum expired
5. bcrypt.compare(password, hash)
  ↓
  [If wrong] → increment loginAttemptCount
  [If >= 5 attempts] → lock akun 30 menit
  [If correct] → reset counter, set lastLoginAt
  ↓
6. Generate accessToken + refreshToken
7. Create UserSession (tokenHash = SHA-256 refresh token)
8. Return { accessToken, refreshToken, isFirstLogin, user }
```

### Flow Refresh Token

```
Client → POST /auth/refresh { refreshToken }
  ↓
1. jwt.verify(refreshToken, refreshSecret)
2. Find UserSession by tokenHash + isActive + expiresAt
3. Invalidate session lama (isActive = false)
4. Generate token baru
5. Create session baru
6. Return { accessToken, refreshToken }
```

### Flow Change Password

```
Client → POST /auth/change-password { oldPassword, newPassword }
  ↓
Auth Guard → JwtAuthGuard → FirstLoginGuard
  ↓
1. Verify old password
2. Check new ≠ old (bcrypt compare)
3. Hash new password (bcrypt, 12 rounds)
4. Transaction:
   - Update user: passwordHash, isFirstLogin=false, credentialPlainEnc=null
   - Invalidate semua session lain
5. Return { message: "Password berhasil diubah." }
```

### Stealth Account System

ServisGadget menggunakan sistem **"stealth account"** — customer tidak perlu register manual.

```
Customer membuat order pertama
  ↓
OrdersService.createOrder()
  ↓
1. Cari user by phoneNumber
2. Jika tidak ada → autoCreateAccount():
   - Generate password: {firstName}{last4phone}
     Contoh: "Budi" + "08123456789" → "08266789"
   - Hash password (bcrypt 12 rounds)
   - Enkripsi plain password (AES-256-GCM) → simpan di credentialPlainEnc
   - Set isFirstLogin = true
3. Kirim credential via WhatsApp
4. Create order
```

**Credential Cleanup:**
- `credentialPlainEnc` dihapus otomatis setelah 24 jam
- Background job: `credential-cleaner.job.ts`

---

## 3. Store Admin Auth

### Flow Login

```
Store Admin → POST /store/auth/login { phoneNumber, password }
  ↓
StoreAuthService.login()
  ↓
1. Find StoreAdmin by phoneNumber (unique per store)
2. bcrypt.compare(password, hash)
3. Check isActive
4. Generate tokens
5. Return { accessToken, refreshToken, admin: { id, fullName, storeId } }
```

### Key Differences from Customer Auth
- Tidak ada account lockout (brute-force protection belum diimplementasi)
- Tidak ada stealth account
- Payload JWT termasuk `storeId`
- Refresh token rotation tersedia

### Store Registration

```
Platform Admin → POST /platform/stores
  ↓
1. Create Store (isActive = false, perlu verifikasi)
2. Create StoreAdmin:
   - Generate password jika tidak diisi
   - Hash dengan bcrypt
   - isFirstLogin = false (bisa langsung login)
3. Return store + admin info
```

---

## 4. Platform Admin Auth

### Flow Login

```
Platform Admin → POST /platform/login { username, password }
  ↓
PlatformAdminService.login()
  ↓
1. Find PlatformAdmin by username
2. bcrypt.compare(password, hash)
3. Generate token (hanya access token, no refresh)
4. Return { accessToken, admin: { id, username, fullName } }
```

### Key Differences
- Hanya 1 token (access only, no refresh)
- Payload JWT: `{ sub: id, role: 'platform_admin', username: 'admin' }`
- Menggunakan secret: `JWT_PLATFORM_ADMIN_SECRET` (tanpa fallback ke store secret)

---

## 5. Password Generation

### Customer (Auto-generated)

```typescript
function generatePassword(fullName: string, phoneNumber: string): string {
  // 1. Ambil nama pertama, uppercase
  const firstName = fullName.trim().split(/\s+/)[0].toUpperCase();
  // 2. Ambil huruf (non-angka), pad dengan underscore
  const letters = firstName.replace(/[^A-Z]/g, '');
  const padded = letters.padEnd(4, '_').substring(0, 4);
  // 3. Konversi ke angka: A=01, B=02, ..., _=00
  const part1 = padded.split('').map(c =>
    c === '_' ? '00' : String(c.charCodeAt(0) - 64).padStart(2, '0')
  ).join('');
  // 4. Ambil 4 digit terakhir phone
  const part2 = phoneNumber.replace(/\D/g, '').slice(-4);
  return part1 + part2;
}
```

**Contoh:**
| Name | Phone | Generated Password |
|------|-------|--------------------|
| Budi Santoso | 08123456789 | `02186789` |
| Andi | 08567890123 | `01017123` |
| Siti Rahayu | 08111222333 | `19012333` |

### Store Admin (Custom)
- Bisa diisi manual saat create store oleh platform admin
- Jika tidak diisi, di-generate otomatis (format sama dengan customer)

---

## 6. Credential Encryption

### Encryption (AES-256-GCM)

```typescript
function encryptCredential(plaintext: string): string {
  const key = Buffer.from(process.env.CREDENTIAL_ENCRYPTION_KEY, 'hex'); // 64 hex chars = 32 bytes
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  const enc = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return `${iv}:${tag}:${enc}`; // Format: hex:hex:hex
}
```

### Decryption

```typescript
function decryptCredential(ciphertext: string): string {
  const parts = ciphertext.split(':');
  const [ivHex, tagHex, encHex] = parts;
  const decipher = createDecipheriv('aes-256-gcm', key, Buffer.from(ivHex, 'hex'));
  decipher.setAuthTag(Buffer.from(tagHex, 'hex'));
  return decipher.update(Buffer.from(encHex, 'hex')).toString('utf8') + decipher.final('utf8');
}
```

### Key Requirements
- `CREDENTIAL_ENCRYPTION_KEY`: 64 hex characters (32 bytes)
- IV: 12 bytes random
- Auth Tag: 16 bytes (GCM)

---

## 7. Security Features

### Brute-Force Protection
- 5 percobaan gagal → akun terkunci 30 menit
- Counter di-reset setelah login berhasil
- `lockedUntil` dicek sebelum verifikasi password

### Session Management
- Refresh token di-hash dengan SHA-256 sebelum disimpan
- Setiap refresh membuat session baru, invalidate yang lama
- `changePassword` invalidate semua session
- `logout` invalidate 1 session
- `logoutAll` invalidate semua session

### First Login Guard
- `isFirstLogin = true` → wajib ganti password dulu
- Guard dicek di semua endpoint `/me/*`

### Token Rotation
- Refresh token hanya bisa dipakai 1 kali
- Setelah dipakai → invalidate + buat baru
- Prevents token reuse attacks

### Password Hashing
- bcrypt dengan 12 rounds
- Salt di-generate otomatis oleh bcrypt

---

## 8. Guards & Decorators

### Guards

| Guard | Fungsi | Digunakan di |
|-------|--------|--------------|
| `JwtAuthGuard` | Verifikasi customer access token | `/me/*`, `/orders/*`, `/payments/*` |
| `StoreJwtAuthGuard` | Verifikasi store admin access token | `/store/*` |
| `RolesGuard` | Cek role dari `@Roles()` decorator | Endpoint dengan multi-role |
| `FirstLoginGuard` | Cek `isFirstLogin` harus `false` | Semua `/me/*` endpoint |

### Decorators

| Decorator | Fungsi | Contoh |
|-----------|--------|--------|
| `@GetUser()` | Ambil user dari request | `@GetUser('id') userId: string` |
| `@GetUser('role')` | Ambil field tertentu | `@GetUser('role') role: string` |
| `@Roles('store_admin')` | Set required role | `@Roles('store_admin') @UseGuards(RolesGuard)` |

### Response Format
Semua auth error dikembalikan dalam format:
```json
{
  "success": false,
  "error": {
    "code": "TOKEN_INVALID",
    "message": "Token invalid or expired",
    "user_message": "Sesi tidak valid, silakan login kembali."
  }
}
```
