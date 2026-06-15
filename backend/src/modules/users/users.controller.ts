import { Controller, Get, Patch, Delete, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { OrdersService } from '../orders/orders.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { UpdateProfileDto } from './dto/user.dto';

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
  async getProfile(@GetUser() user: AuthenticatedUser) {
    return this.usersService.getProfile(user.id);
  }

  @Patch()
  async updateProfile(@GetUser() user: AuthenticatedUser, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(user.id, dto);
  }

  @Get('summary')
  async getSummary(@GetUser() user: AuthenticatedUser) {
    return this.usersService.getSummary(user.id);
  }

  @Get('coupons')
  async getCoupons(@GetUser() user: AuthenticatedUser) {
    return this.usersService.getCoupons(user.id);
  }

  @Get('orders')
  async getMyOrders(@GetUser() user: AuthenticatedUser) {
    return this.ordersService.findMyOrders(user.id);
  }

  @Get('orders/:id/progress')
  async getOrderProgress(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.ordersService.getOrderProgress(user.id, orderId);
  }

  @Get('notifications')
  async getNotifications(@GetUser() user: AuthenticatedUser) {
    return this.usersService.getNotifications(user.id);
  }

  @Get('sessions')
  async getSessions(@GetUser() user: AuthenticatedUser) {
    return this.usersService.getSessions(user.id);
  }

  @Delete('sessions/:id')
  async revokeSession(@GetUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.usersService.revokeSession(user.id, id);
  }

  @Delete('sessions')
  async revokeAllSessions(@GetUser() user: AuthenticatedUser) {
    return this.usersService.revokeAllSessions(user.id);
  }
}
