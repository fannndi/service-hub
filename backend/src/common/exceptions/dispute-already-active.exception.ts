import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class DisputeAlreadyActiveException extends AppException {
  constructor() {
    super('DISPUTE_ALREADY_ACTIVE', 'Dispute already exists', 'Sudah ada klaim aktif untuk pesanan ini.', HttpStatus.CONFLICT);
  }
}
