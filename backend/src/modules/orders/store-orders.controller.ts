import { Controller, Get, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Store Orders')
@Controller('store/orders')
@UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
@ApiBearerAuth()
export class StoreOrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  async findStoreOrders(
    @GetUser('storeId') storeId: string,
    @Query('status') status?: string,
  ) {
    return this.ordersService.findStoreOrders(storeId, status);
  }

  @Get(':id')
  async findById(
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
  ) {
    return this.ordersService.findStoreOrderById(storeId, orderId);
  }

  @Patch(':id/status')
  async updateStatus(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
    @Body() dto: { status: string; note?: string },
  ) {
    return this.ordersService.updateStatus(orderId, adminId, storeId, dto);
  }

  @Patch(':id/diagnosis')
  async submitDiagnosis(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
    @Body() dto: any,
  ) {
    return this.ordersService.submitDiagnosis(orderId, adminId, storeId, dto);
  }
}
