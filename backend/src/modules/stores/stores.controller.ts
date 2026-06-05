import { Controller, Get, Post, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { StoresService } from './stores.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

// Public endpoints
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

// Store admin authenticated endpoints
@ApiTags('Store Dashboard')
@Controller('store')
@UseGuards(StoreJwtAuthGuard)
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

  @Get('customers')
  async getCustomers(
    @GetUser('storeId') storeId: string,
    @Query('q') q?: string,
    @Query('page') page?: string,
  ) {
    return this.storesService.getCustomers(storeId, q);
  }

  @Get('payments')
  async getPayments(
    @GetUser('storeId') storeId: string,
    @Query('status') status?: string,
  ) {
    return this.storesService.getPayments(storeId, status);
  }

  @Get('reviews')
  async getReviews(
    @GetUser('storeId') storeId: string,
  ) {
    return this.storesService.getReviews(storeId);
  }

  @Post('reviews/:reviewId/response')
  async respondToReview(
    @Param('reviewId') reviewId: string,
    @Body() dto: { response: string },
  ) {
    return { message: 'Response recorded' };
  }

  @Get('notifications')
  async getNotifications(
    @GetUser('storeId') storeId: string,
  ) {
    return this.storesService.getStoreNotifications(storeId);
  }

  @Get('profile')
  async getProfile(@GetUser('id') adminId: string) {
    return this.storesService.getStoreProfile(adminId);
  }

  @Patch('profile')
  async updateProfile(
    @GetUser('id') adminId: string,
    @Body() dto: Record<string, any>,
  ) {
    return this.storesService.updateStoreProfile(adminId, dto);
  }

  @Get('analytics')
  async getAnalytics(@GetUser('storeId') storeId: string) {
    return this.storesService.getAnalytics(storeId);
  }
}
