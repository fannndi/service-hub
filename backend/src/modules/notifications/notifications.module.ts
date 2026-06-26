import { Global, Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { InAppNotificationsService } from './in-app-notifications.service';
import { EmailService } from './email.service';
import { NotificationsController, StoreNotificationsController } from './notifications.controller';

@Global()
@Module({
  controllers: [NotificationsController, StoreNotificationsController],
  providers: [NotificationsService, InAppNotificationsService, EmailService],
  exports: [NotificationsService, InAppNotificationsService, EmailService],
})
export class NotificationsModule {}
