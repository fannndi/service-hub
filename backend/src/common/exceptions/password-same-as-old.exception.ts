import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class PasswordSameAsOldException extends AppException {
  constructor() {
    super('PASSWORD_SAME_AS_OLD', 'Same password', 'Password baru tidak boleh sama dengan password sebelumnya.', HttpStatus.BAD_REQUEST);
  }
}
