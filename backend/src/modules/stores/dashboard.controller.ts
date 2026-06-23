import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { StoreDashboardService } from './store-dashboard.service';
import { StoreProfileService } from './store-profile.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';

@ApiTags('Store Dashboard')
@Controller('store')
@UseGuards(StoreJwtAuthGuard)
@ApiBearerAuth()
export class StoreDashboardController {
  constructor(
    private readonly storeDashboardService: StoreDashboardService,
    private readonly storeProfileService: StoreProfileService,
  ) {}

  @Get('dashboard/summary')
  async getDashboard(@GetUser() user: AuthenticatedUser) {
    return this.storeDashboardService.getDashboard(user.storeId!);
  }

  @Patch('settings')
  async updateConfig(@GetUser() user: AuthenticatedUser, @Body() config: Record<string, unknown>) {
    return this.storeDashboardService.updateConfig(user.storeId!, config);
  }

  @Get('customers')
  async getCustomers(
    @GetUser() user: AuthenticatedUser,
    @Query('q') q?: string,
  ) {
    return this.storeDashboardService.getCustomers(user.storeId!, q);
  }

  @Get('payments')
  async getPayments(@GetUser() user: AuthenticatedUser, @Query('status') status?: string) {
    return this.storeDashboardService.getPayments(user.storeId!, status);
  }

  @Get('reviews')
  async getReviews(@GetUser() user: AuthenticatedUser) {
    return this.storeDashboardService.getReviews(user.storeId!);
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
    return this.storeDashboardService.getStoreNotifications(user.storeId!);
  }

  @Get('profile')
  async getProfile(@GetUser() user: AuthenticatedUser) {
    return this.storeProfileService.getStoreProfile(user.id);
  }

  @Patch('profile')
  async updateProfile(@GetUser() user: AuthenticatedUser, @Body() dto: Record<string, unknown>) {
    return this.storeProfileService.updateStoreProfile(user.id, user.storeId!, dto);
  }

  @Get('analytics')
  async getAnalytics(@GetUser() user: AuthenticatedUser) {
    return this.storeDashboardService.getAnalytics(user.storeId!);
  }
}
