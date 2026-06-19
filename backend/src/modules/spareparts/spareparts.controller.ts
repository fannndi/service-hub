import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { SparepartsService } from './spareparts.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { CreateSparepartDto, UpdateSparepartDto, AdjustStockDto } from './dto/sparepart.dto';

@ApiTags('Store Spareparts')
@Controller('store/spareparts')
export class SparepartsController {
  constructor(private readonly sparepartsService: SparepartsService) {}

  @Get()
  async findAvailable(
    @Query('storeId') storeId: string,
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
    @Query('partType') partType?: string,
  ) {
    return this.sparepartsService.findAvailable(storeId, brand, deviceModel, partType);
  }

  @Get('brands')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async getBrands(@GetUser() user: AuthenticatedUser) {
    return this.sparepartsService.getBrands(user.storeId!);
  }

  @Get('device-models')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async getDeviceModels(@GetUser() user: AuthenticatedUser, @Query('brand') brand?: string) {
    return this.sparepartsService.getDeviceModels(user.storeId!, brand ?? '');
  }

  @Post()
  @UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
  @ApiBearerAuth()
  async create(@GetUser() user: AuthenticatedUser, @Body() dto: CreateSparepartDto) {
    return this.sparepartsService.create(user.storeId!, dto);
  }

  @Patch(':id')
  @UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
  @ApiBearerAuth()
  async update(
    @Param('id') id: string,
    @GetUser() user: AuthenticatedUser,
    @Body() dto: UpdateSparepartDto,
  ) {
    return this.sparepartsService.update(id, user.storeId!, dto);
  }

  @Patch(':id/stock')
  @UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
  @ApiBearerAuth()
  async adjustStock(
    @Param('id') id: string,
    @GetUser() user: AuthenticatedUser,
    @Body() dto: AdjustStockDto,
  ) {
    return this.sparepartsService.adjustStock(id, user.storeId!, dto);
  }

  @Delete(':id')
  @UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
  @ApiBearerAuth()
  async delete(@Param('id') id: string, @GetUser() user: AuthenticatedUser) {
    return this.sparepartsService.delete(id, user.storeId!);
  }
}
