import { Injectable, NestMiddleware } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class MaintenanceMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  use(req: Request, res: Response, next: NextFunction) {
    const maintenanceMode = this.configService.get<string>('MAINTENANCE_MODE') === 'true';
    
    // Skip maintenance check for health, config, and metrics endpoints
    const skipPaths = ['/v1/health', '/v1/config', '/v1/metrics', '/docs', '/swagger-json'];
    const shouldSkip = skipPaths.some(path => req.path.startsWith(path));

    if (maintenanceMode && !shouldSkip) {
      return res.status(503).json({
        statusCode: 503,
        message: this.configService.get<string>('MAINTENANCE_MESSAGE') || 'Sedang Maintenance',
        error: 'Service Unavailable',
      });
    }

    next();
  }
}
