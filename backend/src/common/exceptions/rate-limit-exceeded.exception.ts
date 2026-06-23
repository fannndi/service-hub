import { HttpStatus } from '@nestjs/common';
import { AppException } from './app.exception';

export class RateLimitExceededException extends AppException {
  constructor() {
    super('RATE_LIMIT_EXCEEDED', 'Too many requests', 'Terlalu banyak percobaan. Coba lagi nanti.', HttpStatus.TOO_MANY_REQUESTS);
  }
}
