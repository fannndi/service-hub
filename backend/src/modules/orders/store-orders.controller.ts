import { Controller, Get, Post, Param, Patch, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { PaymentsService } from '../payments/payments.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { SubmitDiagnosisDto, UpdateOrderStatusDto } from './dto/order.dto';
import { ACTION_STATUS_MAP } from './utils/state-machine.util';

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
    @GetUser() user: AuthenticatedUser,
    @Query('status') status?: string,
  ) {
    return this.ordersService.findStoreOrders(user.storeId!, status);
  }

  @Get(':id')
  async findById(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.ordersService.findStoreOrderById(user.storeId!, orderId);
  }

  @Post(':id/actions/:action')
  async executeAction(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Param('action') action: string,
    @Body() dto: { note?: string },
  ) {
    const status = ACTION_STATUS_MAP[action] ?? action;
    return this.ordersService.updateStatus(orderId, user.id, user.storeId!, { status, note: dto.note });
  }

  @Patch(':id/status')
  async updateStatus(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: UpdateOrderStatusDto,
  ) {
    return this.ordersService.updateStatus(orderId, user.id, user.storeId!, dto);
  }

  @Post(':id/diagnosis')
  async submitDiagnosis(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: SubmitDiagnosisDto,
  ) {
    return this.ordersService.submitDiagnosis(orderId, user.id, user.storeId!, dto);
  }

  @Get(':id/tracking')
  async getTracking(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.ordersService.getStoreOrderTracking(user.storeId!, orderId);
  }

  @Post(':id/tracking')
  async addTracking(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: { title?: string; note?: string; status: string },
  ) {
    return this.ordersService.addStoreOrderTracking(orderId, user.id, user.storeId!, dto.status, dto.note ?? dto.title);
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
    return this.ordersService.markCredentialSent(orderId, user.storeId!);
  }
}
