import { Controller, Get, Post, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { OrderDiagnosisService } from './order-diagnosis.service';
import { OrderStatusService } from './order-status.service';
import { OrderQueryService } from './order-query.service';
import { OrderTrackingService } from './order-tracking.service';
import { PaymentsService } from '../payments/payments.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { SubmitDiagnosisDto, UpdateOrderStatusDto } from './dto';
import { ACTION_STATUS_MAP } from './utils/state-machine.util';

@ApiTags('Store Orders')
@Controller('store/orders')
@UseGuards(StoreJwtAuthGuard, FirstLoginGuard)
@ApiBearerAuth()
export class StoreOrdersController {
  constructor(
    private readonly orderDiagnosisService: OrderDiagnosisService,
    private readonly orderStatusService: OrderStatusService,
    private readonly orderQueryService: OrderQueryService,
    private readonly orderTrackingService: OrderTrackingService,
    private readonly paymentsService: PaymentsService,
  ) {}

  @Get()
  async findStoreOrders(
    @GetUser() user: AuthenticatedUser,
    @Query('status') status?: string,
  ) {
    return this.orderQueryService.findStoreOrders(user.storeId!, status);
  }

  @Get(':id')
  async findById(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.orderQueryService.findStoreOrderById(user.storeId!, orderId);
  }

  @Post(':id/actions/:action')
  async executeAction(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Param('action') action: string,
    @Body() dto: { note?: string },
  ) {
    const status = ACTION_STATUS_MAP[action] ?? action;
    return this.orderStatusService.updateStatus(orderId, user.id, user.storeId!, { status, note: dto.note });
  }

  @Patch(':id/status')
  async updateStatus(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.orderStatusService.updateStatus(orderId, user.id, user.storeId!, dto);
  }

  @Post(':id/diagnosis')
  async submitDiagnosis(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: SubmitDiagnosisDto,
  ) {
    return this.orderDiagnosisService.submitDiagnosis(orderId, user.id, user.storeId!, dto);
  }

  @Get(':id/tracking')
  async getTracking(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.orderQueryService.getStoreOrderTracking(user.storeId!, orderId);
  }

  @Post(':id/tracking')
  async addTracking(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: { title?: string; note?: string; status: string },
  ) {
    return this.orderTrackingService.addStoreOrderTracking(orderId, user.id, user.storeId!, dto.status, dto.note ?? dto.title);
  }

  @Post(':id/payments/:paymentId/confirm')
  async confirmPayment(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Param('paymentId') paymentId: string,
  ) {
    return this.paymentsService.confirmPayment(orderId, paymentId, user.id, user.storeId!);
  }

  @Post(':id/mark-credential-sent')
  async markCredentialSent(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.orderTrackingService.markCredentialSent(orderId, user.storeId!);
  }
}
