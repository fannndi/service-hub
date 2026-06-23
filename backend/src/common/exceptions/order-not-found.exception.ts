import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class OrderNotFoundException extends AppException {
  constructor() {
    super('ORDER_NOT_FOUND', 'Order not found', 'Pesanan tidak ditemukan.', HttpStatus.NOT_FOUND);
  }
}
