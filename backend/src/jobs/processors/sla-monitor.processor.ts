import { Processor, WorkerHost } from '@nestjs/bullmq';
import { Job } from 'bullmq';
import { PrismaService } from '../../prisma/prisma.service';

@Processor('sla-monitor')
export class SlaMonitorProcessor extends WorkerHost {
  constructor(private prisma: PrismaService) {
    super();
  }

  async process(job: Job<any, any, string>): Promise<any> {
    console.log(`Checking SLA for order: ${job.data.orderId}`);
    // Check if SLA deadline has passed and auto-cancel
  }
}
