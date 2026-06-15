import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { ThrottlerModule } from '@nestjs/throttler';
import configuration from './config/configuration';
import { PrismaModule } from './common/prisma/prisma.module';
import { LoggerModule } from './common/logger/logger.module';
import { HealthController } from './common/health.controller';
import { AuthModule } from './modules/auth/auth.module';
import { StoreAuthModule } from './modules/store-auth/store-auth.module';
import { StoreRegisterModule } from './modules/store-register/store-register.module';
import { PlatformAdminModule } from './modules/platform-admin/platform-admin.module';
import { UsersModule } from './modules/users/users.module';
import { StoresModule } from './modules/stores/stores.module';
import { SparepartsModule } from './modules/spareparts/spareparts.module';
import { OrdersModule } from './modules/orders/orders.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { DisputesModule } from './modules/disputes/disputes.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { UploadsModule } from './modules/uploads/uploads.module';
import { JobsModule } from './modules/jobs/jobs.module';

import { RedisModule } from './modules/redis/redis.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),
    ScheduleModule.forRoot(),
    ThrottlerModule.forRoot([
      {
        ttl: parseInt(process.env.THROTTLE_TTL_SECONDS || '60', 10) * 1000,
        limit: parseInt(process.env.THROTTLE_LIMIT || '100', 10),
      },
    ]),
    LoggerModule,
    PrismaModule,
    RedisModule,
    NotificationsModule,
    AuthModule,
    StoreAuthModule,
    StoreRegisterModule,
    PlatformAdminModule,
    UsersModule,
    StoresModule,
    SparepartsModule,
    OrdersModule,
    PaymentsModule,
    ReviewsModule,
    DisputesModule,
    UploadsModule,
    JobsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
