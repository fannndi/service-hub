import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

interface ResponseWrapper<T> {
  success: true;
  data: T | null;
  timestamp: string;
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, ResponseWrapper<T>> {
  intercept(_ctx: ExecutionContext, next: CallHandler<T>): Observable<ResponseWrapper<T>> {
    return next.handle().pipe(
      map((data) => ({
        success: true as const,
        data: data ?? null,
        timestamp: new Date().toISOString(),
      })),
    );
  }
}
