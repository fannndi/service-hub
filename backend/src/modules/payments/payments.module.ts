import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PaymentsService } from './payments.service';
import { MidtransService } from './midtrans.service';
import { PaymentsController } from './payments.controller';
import { StorePaymentsController } from './store-payments.controller';

@Module({
  imports: [ConfigModule],
  controllers: [PaymentsController, StorePaymentsController],
  providers: [PaymentsService, MidtransService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
