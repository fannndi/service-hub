import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class CouponExpiredException extends AppException {
  constructor() {
    super('COUPON_EXPIRED', 'Coupon expired', 'Kupon sudah kadaluarsa.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}
