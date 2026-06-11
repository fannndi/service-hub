import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class GlobalExceptionFilter implements ExceptionFilter {
  private logger = new Logger('GlobalExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    if (exception instanceof HttpException) {
      const body = exception.getResponse();
      if (typeof body === 'object' && body !== null && 'success' in body && (body as { success: boolean }).success === false) {
        return res.status(exception.getStatus()).json(body);
      }
      return res.status(exception.getStatus()).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          user_message: 'Data tidak valid.',
          details: typeof body === 'object' && body !== null && 'message' in body ? (body as { message: unknown }).message : undefined,
        },
        timestamp: new Date().toISOString(),
        path: req.url,
      });
    }

    this.logger.error(`Unhandled exception at ${req.method} ${req.url}`, exception instanceof Error ? exception.stack : String(exception));
    return res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Internal server error',
        user_message: 'Terjadi kesalahan. Coba lagi nanti.',
      },
      timestamp: new Date().toISOString(),
      path: req.url,
    });
  }
}
