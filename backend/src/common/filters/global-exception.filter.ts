import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private logger = new Logger('GlobalExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();

    if (exception instanceof HttpException) {
      const body = exception.getResponse();
      if (typeof body === 'object' && (body as any).success === false) {
        return res.status(exception.getStatus()).json(body);
      }
      return res.status(exception.getStatus()).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          user_message: 'Data tidak valid.',
          details: (body as any).message,
        },
        timestamp: new Date().toISOString(),
      });
    }

    this.logger.error('Unhandled exception', exception);
    return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Internal server error',
        user_message: 'Terjadi kesalahan. Coba lagi nanti.',
      },
      timestamp: new Date().toISOString(),
    });
  }
}
