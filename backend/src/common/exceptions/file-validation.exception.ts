import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class FileValidationException extends AppException {
  constructor(message: string, userMessage: string) {
    super('FILE_VALIDATION_ERROR', message, userMessage, HttpStatus.BAD_REQUEST);
  }
}
