import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class StockUnavailableException extends AppException {
  constructor() {
    super('STOCK_UNAVAILABLE', 'Insufficient stock', 'Stok sparepart tidak tersedia.', HttpStatus.CONFLICT);
  }
}
