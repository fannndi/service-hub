import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class InvalidStatusTransitionException extends AppException {
  constructor(from: string, to: string) {
    super('INVALID_STATUS_TRANSITION', `Cannot transition from ${from} to ${to}`, 'Perubahan status tidak valid.', HttpStatus.UNPROCESSABLE_ENTITY);
  }
}
