import { AppException } from './app.exception';

export class AccountLockedException extends AppException {
  constructor(lockedUntil: Date) {
    super('ACCOUNT_LOCKED', 'Account locked', 'Akun terkunci sementara.', 423, { locked_until: lockedUntil });
  }
}
