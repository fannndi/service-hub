import { Controller, Post, Param, Body, UseGuards, HttpCode } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { MidtransService } from './midtrans.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { CreatePaymentDto } from './dto/payment.dto';

@ApiTags('Payments')
@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
    private readonly midtrans: MidtransService,
  ) {}

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

  @Post('midtrans/snap-token')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(200)
  async getSnapToken(@GetUser() user: AuthenticatedUser, @Body('orderId') orderId: string) {
    return this.midtrans.createSnapToken(orderId, user.id);
  }

  @Post('midtrans/notification')
  @HttpCode(200)
  async notification(@Body() payload: Record<string, unknown>) {
    return this.midtrans.processNotification(payload);
  }
}
