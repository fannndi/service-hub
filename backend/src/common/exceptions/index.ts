import { HttpException, HttpStatus } from '@nestjs/common';

export class AppException extends HttpException {
  constructor(
    public readonly code: string,
    message: string,
    public readonly userMessage: string,
    status: number,
    details?: Record<string, unknown>,
  ) {
    super(
      {
        success: false,
        error: { code, message, user_message: userMessage, details },
        timestamp: new Date().toISOString(),
      },
      status,
    );
  }
}

export class InvalidCredentialsException extends AppException {
  constructor() {
    super('INVALID_CREDENTIALS', 'Wrong credentials', 'Nomor HP atau password salah.', HttpStatus.UNAUTHORIZED);
  }
}

export class AccountLockedException extends AppException {
  constructor(lockedUntil: Date) {
    super('ACCOUNT_LOCKED', 'Account locked', 'Akun terkunci sementara.', 423, { locked_until: lockedUntil });
  }
}

export class AccountSuspendedException extends AppException {
  constructor() {
    super('ACCOUNT_SUSPENDED', 'Account suspended', 'Akun dinonaktifkan. Hubungi support.', HttpStatus.FORBIDDEN);
  }
}

export class FirstLoginRequiredException extends AppException {
  constructor() {
    super('FIRST_LOGIN_REQUIRED', 'Change password first', 'Harap ganti password sementaramu terlebih dahulu.', HttpStatus.FORBIDDEN);
  }
}

export class TokenInvalidException extends AppException {
  constructor() {
    super('TOKEN_INVALID', 'Token invalid or expired', 'Sesi tidak valid, silakan login kembali.', HttpStatus.UNAUTHORIZED);
  }
}

export class PasswordSameAsOldException extends AppException {
  constructor() {
    super('PASSWORD_SAME_AS_OLD', 'Same password', 'Password baru tidak boleh sama dengan password sebelumnya.', HttpStatus.BAD_REQUEST);
  }
}

export class OrderNotFoundException extends AppException {
  constructor() {
    super('ORDER_NOT_FOUND', 'Order not found', 'Pesanan tidak ditemukan.', HttpStatus.NOT_FOUND);
  }
}

export class InvalidStatusTransitionException extends AppException {
  constructor(from: string, to: string) {
    super('INVALID_STATUS_TRANSITION', `Cannot transition from ${from} to ${to}`, 'Perubahan status tidak valid.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}

export class StockUnavailableException extends AppException {
  constructor() {
    super('STOCK_UNAVAILABLE', 'Insufficient stock', 'Stok sparepart tidak tersedia.', HttpStatus.CONFLICT);
  }
}

export class StoreNotActiveException extends AppException {
  constructor() {
    super('STORE_NOT_ACTIVE', 'Store not active', 'Toko tidak aktif atau tidak ditemukan.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}

export class DeliveryAddressRequiredException extends AppException {
  constructor() {
    super('DELIVERY_ADDRESS_REQUIRED', 'Delivery address required', 'Alamat penjemputan wajib diisi untuk metode kurir.', HttpStatus.BAD_REQUEST);
  }
}

export class ProofRequiredException extends AppException {
  constructor() {
    super('PROOF_REQUIRED', 'Payment proof required', 'Bukti pembayaran wajib diunggah untuk transfer bank.', HttpStatus.BAD_REQUEST);
  }
}

export class CouponExpiredException extends AppException {
  constructor() {
    super('COUPON_EXPIRED', 'Coupon expired', 'Kupon sudah kadaluarsa.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}

export class CouponAlreadyUsedException extends AppException {
  constructor() {
    super('COUPON_ALREADY_USED', 'Coupon already used', 'Kupon sudah pernah digunakan.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}

export class CouponNotOwnedException extends AppException {
  constructor() {
    super('COUPON_NOT_OWNED', 'Coupon not owned', 'Kupon ini bukan milikmu.', HttpStatus.FORBIDDEN);
  }
}

export class DuplicateReviewException extends AppException {
  constructor() {
    super('DUPLICATE_REVIEW', 'Review already exists', 'Kamu sudah memberikan ulasan untuk pesanan ini.', HttpStatus.CONFLICT);
  }
}

export class WarrantyExpiredException extends AppException {
  constructor() {
    super('WARRANTY_EXPIRED', 'Warranty expired', 'Masa garansi sudah berakhir.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}

export class DisputeAlreadyActiveException extends AppException {
  constructor() {
    super('DISPUTE_ALREADY_ACTIVE', 'Dispute already exists', 'Sudah ada klaim aktif untuk pesanan ini.', HttpStatus.CONFLICT);
  }
}

export class ForbiddenException extends AppException {
  constructor(message: string, userMessage: string) {
    super('FORBIDDEN', message, userMessage, HttpStatus.FORBIDDEN);
  }
}

export class NotFoundException extends AppException {
  constructor(message: string, userMessage: string) {
    super('NOT_FOUND', message, userMessage, HttpStatus.NOT_FOUND);
  }
}

export class RateLimitExceededException extends AppException {
  constructor() {
    super('RATE_LIMIT_EXCEEDED', 'Too many requests', 'Terlalu banyak percobaan. Coba lagi nanti.', HttpStatus.TOO_MANY_REQUESTS);
  }
}

export class FileValidationException extends AppException {
  constructor(message: string, userMessage: string) {
    super('FILE_VALIDATION_ERROR', message, userMessage, HttpStatus.BAD_REQUEST);
  }
}
