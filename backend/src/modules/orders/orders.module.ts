import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { StoreOrdersController } from './store-orders.controller';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [OrdersController, StoreOrdersController],
  providers: [OrdersService],
  exports: [OrdersService],
})
export class OrdersModule {}
