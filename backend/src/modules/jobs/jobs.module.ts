import { Module } from '@nestjs/common';
import { SlaMonitorJob } from './sla-monitor.job';
import { CredentialCleanerJob } from './credential-cleaner.job';

@Module({
  providers: [SlaMonitorJob, CredentialCleanerJob],
})
export class JobsModule {}
