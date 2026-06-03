import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { RedisModule } from './redis/redis.module';
import { CustomerAuthModule } from './auth/customer/customer-auth.module';
import { StoreAuthModule } from './auth/store/store-auth.module';
import { InventoryModule } from './spareparts/inventory.module';
import { OrderModule } from './orders/order.module';
import { PaymentService } from './payments/payment.service';
import { ReviewService } from './reviews/review.service';
import { DisputeService } from './disputes/dispute.service';
import { NotificationService } from './notifications/notification.service';
import { UploadService } from './upload/upload.service';
import { UploadController } from './upload/upload.controller';
import { HealthController } from './common/health.controller';
import { BullModule } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    RedisModule,
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        connection: {
          host: config.get<string>('app.redis.host', 'redis'),
          port: config.get<number>('app.redis.port', 6379),
        },
      }),
    }),
    CustomerAuthModule,
    StoreAuthModule,
    InventoryModule,
    OrderModule,
  ],
  controllers: [HealthController, UploadController],
  providers: [PaymentService, ReviewService, DisputeService, NotificationService, UploadService],
})
export class AppModule {}
