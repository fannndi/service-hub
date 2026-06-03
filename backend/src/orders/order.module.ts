import { Module } from '@nestjs/common';
import { OrderService } from './order.service';
import { InventoryModule } from '../spareparts/inventory.module';

@Module({
  imports: [InventoryModule],
  providers: [OrderService],
  exports: [OrderService],
})
export class OrderModule {}
