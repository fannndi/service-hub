import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class CouponAlreadyUsedException extends AppException {
  constructor() {
    super('COUPON_ALREADY_USED', 'Coupon already used', 'Kupon sudah pernah digunakan.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}
