import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class TokenInvalidException extends AppException {
  constructor() {
    super('TOKEN_INVALID', 'Token invalid or expired', 'Sesi tidak valid, silakan login kembali.', HttpStatus.UNAUTHORIZED);
  }
}
