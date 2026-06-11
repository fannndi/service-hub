import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { PrismaService } from './prisma/prisma.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async check(): Promise<{ status: string; service: string; database: string; uptime: number; memory: NodeJS.MemoryUsage }> {
    let dbStatus = 'ok';
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      dbStatus = 'error';
    }

    return {
      status: 'ok',
      service: 'servisgadget-foundation',
      database: dbStatus,
      uptime: process.uptime(),
      memory: process.memoryUsage(),
    };
  }
}
