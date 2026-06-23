import { Module } from '@nestjs/common';
import { OrderCreationService } from './order-creation.service';
import { OrderDiagnosisService } from './order-diagnosis.service';
import { OrderStatusService } from './order-status.service';
import { OrderQueryService } from './order-query.service';
import { OrderTrackingService } from './order-tracking.service';
import { OrdersController } from './orders.controller';
import { StoreOrdersController } from './store-orders.controller';
import { AuthModule } from '../auth/auth.module';
import { PaymentsModule } from '../payments/payments.module';
import { ReviewsModule } from '../reviews/reviews.module';
import { DisputesModule } from '../disputes/disputes.module';

@Module({
  imports: [AuthModule, PaymentsModule, ReviewsModule, DisputesModule],
  controllers: [OrdersController, StoreOrdersController],
  providers: [
    OrderCreationService,
    OrderDiagnosisService,
    OrderStatusService,
    OrderQueryService,
    OrderTrackingService,
  ],
  exports: [
    OrderCreationService,
    OrderDiagnosisService,
    OrderStatusService,
    OrderQueryService,
    OrderTrackingService,
  ],
})
export class OrdersModule {}
