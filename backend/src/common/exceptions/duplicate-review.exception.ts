import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class DuplicateReviewException extends AppException {
  constructor() {
    super('DUPLICATE_REVIEW', 'Review already exists', 'Kamu sudah memberikan ulasan untuk pesanan ini.', HttpStatus.CONFLICT);
  }
}
