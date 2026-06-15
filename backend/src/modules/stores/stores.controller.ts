import { Controller, Get, Post, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { StoresService } from './stores.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';

@ApiTags('Stores')
@Controller('stores')
export class StoresController {
  constructor(private readonly storesService: StoresService) {}

  @Get()
  async findAll(
    @Query('brand') brand?: string,
    @Query('deviceModel') deviceModel?: string,
  ) {
    return this.storesService.findAll(false, brand, deviceModel);
  }

  @Get('match')
  async matchStores(
    @Query('brand') brand: string,
    @Query('deviceModel') deviceModel: string,
    @Query('partType') partType?: string,
  ) {
    return this.storesService.matchStores(brand, deviceModel, partType);
  }

  @Get('device-models')
  async getDeviceModels() {
    return this.storesService.getDeviceModels();
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
@UseGuards(StoreJwtAuthGuard)
@ApiBearerAuth()
export class StoreDashboardController {
  constructor(private readonly storesService: StoresService) {}

  @Get('dashboard/summary')
  async getDashboard(@GetUser() user: AuthenticatedUser) {
    return this.storesService.getDashboard(user.storeId!);
  }

  @Patch('settings')
  async updateConfig(@GetUser() user: AuthenticatedUser, @Body() config: Record<string, unknown>) {
    return this.storesService.updateConfig(user.storeId!, config);
  }

  @Get('customers')
  async getCustomers(
    @GetUser() user: AuthenticatedUser,
    @Query('q') q?: string,
  ) {
    return this.storesService.getCustomers(user.storeId!, q);
  }

  @Get('payments')
  async getPayments(@GetUser() user: AuthenticatedUser, @Query('status') status?: string) {
    return this.storesService.getPayments(user.storeId!, status);
  }

  @Get('reviews')
  async getReviews(@GetUser() user: AuthenticatedUser) {
    return this.storesService.getReviews(user.storeId!);
  }

  @Post('reviews/:reviewId/response')
  async respondToReview(
    @Param('reviewId') reviewId: string,
    @Body() dto: { response: string },
  ) {
    return { message: 'Response recorded', reviewId, response: dto.response };
  }

  @Get('notifications')
  async getNotifications(@GetUser() user: AuthenticatedUser) {
    return this.storesService.getStoreNotifications(user.storeId!);
  }

  @Get('profile')
  async getProfile(@GetUser() user: AuthenticatedUser) {
    return this.storesService.getStoreProfile(user.id);
  }

  @Patch('profile')
  async updateProfile(@GetUser() user: AuthenticatedUser, @Body() dto: Record<string, unknown>) {
    return this.storesService.updateStoreProfile(user.id, user.storeId!, dto);
  }

  @Get('analytics')
  async getAnalytics(@GetUser() user: AuthenticatedUser) {
    return this.storesService.getAnalytics(user.storeId!);
  }
}
