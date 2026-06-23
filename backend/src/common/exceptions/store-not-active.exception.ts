import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class StoreNotActiveException extends AppException {
  constructor() {
    super('STORE_NOT_ACTIVE', 'Store not active', 'Toko tidak aktif atau tidak ditemukan.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}
