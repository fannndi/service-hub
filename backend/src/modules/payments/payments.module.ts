import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { PaymentsController, StorePaymentsController } from './payments.controller';

@Module({
  controllers: [PaymentsController, StorePaymentsController],
  providers: [PaymentsService],
  exports: [PaymentsService],
})
export class PaymentsModule {}
