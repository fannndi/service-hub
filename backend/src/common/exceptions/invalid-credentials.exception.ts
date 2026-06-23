import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class InvalidCredentialsException extends AppException {
  constructor() {
    super('INVALID_CREDENTIALS', 'Wrong credentials', 'Nomor HP atau password salah.', HttpStatus.UNAUTHORIZED);
  }
}
