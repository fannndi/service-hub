import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { PrismaService } from '../../common/prisma/prisma.service';

@Injectable()
export class CredentialCleanerJob {
  private readonly logger = new Logger(CredentialCleanerJob.name);

  constructor(private prisma: PrismaService) {}

  @Cron('0 */30 * * * *')
  async cleanCredentials() {
    try {
      const threshold = new Date(Date.now() - 24 * 60 * 60 * 1000);

      const result = await this.prisma.user.updateMany({
        where: {
          credentialPlainEnc: { not: null },
          passwordChangedAt: { lt: threshold },
        },
        data: { credentialPlainEnc: null },
      });

      if (result.count > 0) {
        this.logger.log(`Cleaned credentials for ${result.count} users`);
      }
    } catch (err) {
      this.logger.error('Credential cleaner error', err);
    }
  }
}
