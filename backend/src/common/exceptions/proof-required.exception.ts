import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class ProofRequiredException extends AppException {
  constructor() {
    super('PROOF_REQUIRED', 'Payment proof required', 'Bukti pembayaran wajib diunggah untuk transfer bank.', HttpStatus.BAD_REQUEST);
  }
}
