import { Module } from '@nestjs/common';
import { DisputesService } from './disputes.service';
import { DisputesController, StoreDisputesController } from './disputes.controller';

@Module({
  controllers: [DisputesController, StoreDisputesController],
  providers: [DisputesService],
  exports: [DisputesService],
})
export class DisputesModule {}
