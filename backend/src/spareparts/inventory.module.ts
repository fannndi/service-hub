import { Module } from '@nestjs/common';
import { StoreService } from './store.service';
import { SparepartService } from './sparepart.service';

@Module({
  providers: [StoreService, SparepartService],
  exports: [StoreService, SparepartService],
})
export class InventoryModule {}
