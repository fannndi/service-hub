import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { StoreOrdersController } from './store-orders.controller';
import { AuthModule } from '../auth/auth.module';
import { PaymentsModule } from '../payments/payments.module';
import { ReviewsModule } from '../reviews/reviews.module';
import { DisputesModule } from '../disputes/disputes.module';

@Module({
  imports: [AuthModule, PaymentsModule, ReviewsModule, DisputesModule],
  controllers: [OrdersController, StoreOrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
