import { Module } from '@nestjs/common';
import { StoresService } from './stores.service';
import { StoreDiscoveryService } from './store-discovery.service';
import { StoreDashboardService } from './store-dashboard.service';
import { StoreProfileService } from './store-profile.service';
import { StoresController } from './stores.controller';
import { StoreDashboardController } from './dashboard.controller';

@Module({
  controllers: [StoresController, StoreDashboardController],
  providers: [StoresService, StoreDiscoveryService, StoreDashboardService, StoreProfileService],
  exports: [StoresService, StoreDiscoveryService, StoreDashboardService, StoreProfileService],
})
export class StoresModule {}
