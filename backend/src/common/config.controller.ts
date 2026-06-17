import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';

@ApiTags('config')
@Controller('config')
export class ConfigController {
  constructor(private readonly configService: ConfigService) {}

  @Get()
  getConfig() {
    const maintenanceMode = this.configService.get<string>('MAINTENANCE_MODE') === 'true';
    const maintenanceMessage = this.configService.get<string>('MAINTENANCE_MESSAGE') || 'Sedang Maintenance';
    const nodeEnv = this.configService.get<string>('NODE_ENV') || 'development';

    return {
      data: {
        environment: nodeEnv === 'production' ? 'production' : 'local',
        maintenanceMode,
        maintenanceMessage,
        version: '1.0.0',
        features: {
          booking: true,
          chat: false,
          payment: true,
        },
      },
    };
  }
}
