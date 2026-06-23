import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { StoreDiscoveryService } from './store-discovery.service';

@ApiTags('Stores')
@Controller('stores')
export class StoresController {
  constructor(private readonly storeDiscoveryService: StoreDiscoveryService) {}

  @Get()
  async findAll(
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
  ) {
    return this.storeDiscoveryService.findAll(false, brand, deviceModel);
  }

  @Get('match')
  async matchStores(
    @Query('brand') brand: string,
    @Query('deviceModel') deviceModel: string,
    @Query('partType') partType?: string,
  ) {
    return this.storeDiscoveryService.matchStores(brand, deviceModel, partType);
  }

  @Get('device-models')
  async getDeviceModels() {
    return this.storeDiscoveryService.getDeviceModels();
  }

  @Get(':id')
  async findById(@Param('id') id: string) {
    return this.storeDiscoveryService.findById(id);
  }

  @Get(':id/spareparts')
  async findStoreSpareparts(
    @Param('id') storeId: string,
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
    @Query('partType') partType?: string,
  ) {
    return this.storeDiscoveryService.findSpareparts(storeId, brand, deviceModel, partType);
  }
}

