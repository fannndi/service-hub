import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class ForbiddenException extends AppException {
  constructor(message: string, userMessage: string) {
    super('FORBIDDEN', message, userMessage, HttpStatus.FORBIDDEN);
  }
}
