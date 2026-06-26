import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class GuestAccountNotActivatedException extends AppException {
  constructor() {
    super('GUEST_NOT_ACTIVATED', 'Guest account not activated', 'Akun tamu belum aktif. Tunggu konfirmasi toko.', HttpStatus.FORBIDDEN);
  }
}
