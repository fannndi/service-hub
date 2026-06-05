import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { SparepartsService } from './spareparts.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Store Spareparts')
@Controller('store/spareparts')
export class SparepartsController {
  constructor(private readonly sparepartsService: SparepartsService) {}

  // Public: customer store detail screen (uses JWT but no StoreJwt required)
  // Also used by store admin for their own inventory (passes storeId from JWT)
  @Get()
  async findAvailable(
    @Query('storeId') storeId: string,
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
    @Query('partType') partType?: string,
  ) {
    return this.sparepartsService.findAvailable(storeId, brand, deviceModel, partType);
  }

  @Post()
  @UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
  @ApiBearerAuth()
  async create(
    @GetUser('storeId') storeId: string,
    @Body() dto: { brand: string; deviceModel: string; partType: string; partName: string; price: number; qty: number; status?: string },
  ) {
    return this.sparepartsService.create(storeId, dto);
  }

  @Patch(':id')
  @UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
  @ApiBearerAuth()
  async update(
    @Param('id') id: string,
    @GetUser('storeId') storeId: string,
    @Body() dto: { price?: number; qty?: number; status?: string; partName?: string },
  ) {
    return this.sparepartsService.update(id, storeId, dto);
  }

  @Delete(':id')
  @UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
  @ApiBearerAuth()
  async delete(@Param('id') id: string, @GetUser('storeId') storeId: string) {
    return this.sparepartsService.delete(id, storeId);
  }
}
