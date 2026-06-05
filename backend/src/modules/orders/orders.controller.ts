import { Controller, Post, Get, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Orders')
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  async createOrder(@Body() dto: any) {
    return this.ordersService.createOrder(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async findMyOrders(@GetUser('id') userId: string) {
    return this.ordersService.findMyOrders(userId);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async findById(@GetUser('id') userId: string, @Param('id') orderId: string) {
    return this.ordersService.findMyOrderById(userId, orderId);
  }

  @Post(':id/approve')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async approve(@GetUser('id') userId: string, @Param('id') orderId: string) {
    return this.ordersService.approveOrder(orderId, userId);
  }

  @Post(':id/reject')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async reject(@GetUser('id') userId: string, @Param('id') orderId: string) {
    return this.ordersService.rejectOrder(orderId, userId);
  }
}
