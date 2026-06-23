import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class CouponNotOwnedException extends AppException {
  constructor() {
    super('COUPON_NOT_OWNED', 'Coupon not owned', 'Kupon ini bukan milikmu.', HttpStatus.FORBIDDEN);
  }
}
