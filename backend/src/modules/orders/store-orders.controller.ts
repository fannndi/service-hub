import { Controller, Get, Post, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { PaymentsService } from '../payments/payments.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

const ACTION_STATUS_MAP: Record<string, string> = {
  receive_device: 'device_received',
  start_diagnosis: 'diagnosing',
  sparepart_arrived: 'repairing',
  start_repair: 'repairing',
  complete_repair: 'quality_check',
  start_qc: 'quality_check',
  qc_ok: 'waiting_payment',
  request_payment: 'waiting_payment',
};

@ApiTags('Store Orders')
@Controller('store/orders')
@UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
@ApiBearerAuth()
export class StoreOrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly paymentsService: PaymentsService,
  ) {}

  @Get()
  async findStoreOrders(
    @GetUser('storeId') storeId: string,
    @Query('status') status?: string,
    @Query('actionGroup') actionGroup?: string,
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

  @Post(':id/actions/:action')
  async executeAction(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
    @Param('action') action: string,
    @Body() dto: { note?: string },
  ) {
    const status = ACTION_STATUS_MAP[action] ?? action;
    return this.ordersService.updateStatus(orderId, adminId, storeId, { status, note: dto.note });
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

  @Post(':id/diagnosis')
  async submitDiagnosis(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
    @Body() dto: any,
  ) {
    return this.ordersService.submitDiagnosis(orderId, adminId, storeId, dto);
  }

  @Patch(':id/diagnosis')
  async submitDiagnosisPatch(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
    @Body() dto: any,
  ) {
    return this.ordersService.submitDiagnosis(orderId, adminId, storeId, dto);
  }

  @Get(':id/tracking')
  async getTracking(
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
  ) {
    return this.ordersService.getStoreOrderTracking(storeId, orderId);
  }

  @Post(':id/tracking')
  async addTracking(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
    @Body() dto: { title?: string; note?: string; status: string },
  ) {
    return this.ordersService.addStoreOrderTracking(orderId, adminId, storeId, dto.status, dto.note ?? dto.title);
  }

  @Post(':id/payments/:paymentId/confirm')
  async confirmPayment(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') orderId: string,
    @Param('paymentId') paymentId: string,
  ) {
    return this.paymentsService.confirmPayment(orderId, paymentId, adminId, storeId);
  }
}
