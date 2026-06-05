import { Controller, Get, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { StoresService } from './stores.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Stores')
@Controller('stores')
export class StoresController {
  constructor(private readonly storesService: StoresService) {}

  @Get()
  async findAll(
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
  ) {
    return this.storesService.findAll(false);
  }

  @Get(':id')
  async findById(@Param('id') id: string) {
    return this.storesService.findById(id);
  }

  @Get(':id/spareparts')
  async findStoreSpareparts(
    @Param('id') storeId: string,
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
    @Query('partType') partType?: string,
  ) {
    return this.storesService.findSpareparts(storeId, brand, deviceModel, partType);
  }
}

@ApiTags('Store Dashboard')
@Controller('store')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class StoreDashboardController {
  constructor(private readonly storesService: StoresService) {}

  @Get('dashboard/summary')
  async getDashboard(@GetUser('storeId') storeId: string) {
    return this.storesService.getDashboard(storeId);
  }

  @Patch('settings')
  async updateConfig(
    @GetUser('storeId') storeId: string,
    @Body() config: Record<string, any>,
  ) {
    return this.storesService.updateConfig(storeId, config);
  }
}
