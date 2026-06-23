import { Controller, Post, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';

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
