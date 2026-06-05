import { Controller, Get, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { OrdersService } from '../orders/orders.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Users')
@Controller('me')
@UseGuards(JwtAuthGuard, FirstLoginGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly ordersService: OrdersService,
  ) {}

  @Get()
  async getProfile(@GetUser('id') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @Patch()
  async updateProfile(
    @GetUser('id') userId: string,
    @Body() dto: { fullName?: string; address?: string; avatarUrl?: string },
  ) {
    return this.usersService.updateProfile(userId, dto);
  }

  @Get('summary')
  async getSummary(@GetUser('id') userId: string) {
    return this.usersService.getSummary(userId);
  }

  @Get('coupons')
  async getCoupons(@GetUser('id') userId: string) {
    return this.usersService.getCoupons(userId);
  }

  @Get('orders')
  async getMyOrders(
    @GetUser('id') userId: string,
  ) {
    return this.ordersService.findMyOrders(userId);
  }

  @Get('orders/:id/progress')
  async getOrderProgress(
    @GetUser('id') userId: string,
    @Param('id') orderId: string,
  ) {
    return this.ordersService.getOrderProgress(userId, orderId);
  }

  @Get('notifications')
  async getNotifications(@GetUser('id') userId: string) {
    return this.usersService.getNotifications(userId);
  }
}
