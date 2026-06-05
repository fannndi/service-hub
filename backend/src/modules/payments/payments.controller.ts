import { Controller, Post, Get, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post(':orderId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createPayment(
    @GetUser('id') userId: string,
    @Param('orderId') orderId: string,
    @Body() dto: any,
  ) {
    return this.paymentsService.createPayment(orderId, userId, dto);
  }
}

@ApiTags('Store Payments')
@Controller('store/payments')
@UseGuards(StoreJwtAuthGuard)
@ApiBearerAuth()
export class StorePaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post(':orderId/:paymentId/confirm')
  async confirmPayment(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('orderId') orderId: string,
    @Param('paymentId') paymentId: string,
  ) {
    return this.paymentsService.confirmPayment(orderId, paymentId, adminId, storeId);
  }
}
