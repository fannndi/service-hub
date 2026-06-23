import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class FirstLoginRequiredException extends AppException {
  constructor() {
    super('FIRST_LOGIN_REQUIRED', 'Change password first', 'Harap ganti password sementaramu terlebih dahulu.', HttpStatus.FORBIDDEN);
  }
}
