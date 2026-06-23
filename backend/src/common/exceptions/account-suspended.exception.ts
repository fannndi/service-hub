import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class AccountSuspendedException extends AppException {
  constructor() {
    super('ACCOUNT_SUSPENDED', 'Account suspended', 'Akun dinonaktifkan. Hubungi support.', HttpStatus.FORBIDDEN);
  }
}
