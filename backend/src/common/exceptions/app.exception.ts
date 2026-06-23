import { HttpException } from '@nestjs/common';

export class AppException extends HttpException {
  constructor(
    public readonly code: string,
    message: string,
    public readonly userMessage: string,
    status: number,
    details?: Record<string, unknown>,
  ) {
    super(
      {
        success: false,
        error: { code, message, user_message: userMessage, details },
        timestamp: new Date().toISOString(),
      },
      status,
    );
  }
}
