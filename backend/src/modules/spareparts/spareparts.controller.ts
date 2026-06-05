import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { SparepartsService } from './spareparts.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Store Spareparts')
@Controller('store/spareparts')
@UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
@ApiBearerAuth()
export class SparepartsController {
  constructor(private readonly sparepartsService: SparepartsService) {}

  @Get()
  async findByStore(@GetUser('storeId') storeId: string) {
    return this.sparepartsService.findByStore(storeId);
  }

  @Get('available')
  async findAvailable(
    @GetUser('storeId') storeId: string,
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
    @Query('partType') partType?: string,
  ) {
    return this.sparepartsService.findAvailable(storeId, brand, deviceModel, partType);
  }

  @Post()
  async create(
    @GetUser('storeId') storeId: string,
    @Body() dto: { brand: string; deviceModel: string; partType: string; partName: string; price: number; qty: number; status?: string },
  ) {
    return this.sparepartsService.create(storeId, dto);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @GetUser('storeId') storeId: string,
    @Body() dto: { price?: number; qty?: number; status?: string; partName?: string },
  ) {
    return this.sparepartsService.update(id, storeId, dto);
  }

  @Delete(':id')
  async delete(@Param('id') id: string, @GetUser('storeId') storeId: string) {
    return this.sparepartsService.delete(id, storeId);
  }
}
