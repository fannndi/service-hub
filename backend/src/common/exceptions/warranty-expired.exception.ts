import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class WarrantyExpiredException extends AppException {
  constructor() {
    super('WARRANTY_EXPIRED', 'Warranty expired', 'Masa garansi sudah berakhir.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}
