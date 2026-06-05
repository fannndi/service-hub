import { Module } from '@nestjs/common';
import { StoresService } from './stores.service';
import { StoresController, StoreDashboardController } from './stores.controller';

@Module({
  controllers: [StoresController, StoreDashboardController],
  providers: [StoresService],
  exports: [StoresService],
})
export class StoresModule {}
