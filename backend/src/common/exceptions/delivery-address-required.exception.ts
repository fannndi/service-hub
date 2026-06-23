import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class DeliveryAddressRequiredException extends AppException {
  constructor() {
    super('DELIVERY_ADDRESS_REQUIRED', 'Delivery address required', 'Alamat penjemputan wajib diisi untuk metode kurir.', HttpStatus.BAD_REQUEST);
  }
}
