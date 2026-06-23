import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class NotFoundException extends AppException {
  constructor(message: string, userMessage: string) {
    super('NOT_FOUND', message, userMessage, HttpStatus.NOT_FOUND);
  }
}
