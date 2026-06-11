import { Controller, Post, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { CreatePaymentDto } from './dto/payment.dto';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post(':orderId')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createPayment(
    @GetUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: CreatePaymentDto,
  ) {
    return this.paymentsService.createPayment(orderId, user.id, dto);
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
    @GetUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Param('paymentId') paymentId: string,
  ) {
    return this.paymentsService.confirmPayment(orderId, paymentId, user.id, user.storeId!);
  }
}
