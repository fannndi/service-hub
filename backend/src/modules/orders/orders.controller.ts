import { Controller, Post, Get, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { OrderCreationService } from './order-creation.service';
import { OrderDiagnosisService } from './order-diagnosis.service';
import { OrderQueryService } from './order-query.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { PaymentsService } from '../payments/payments.service';
import { ReviewsService } from '../reviews/reviews.service';
import { DisputesService } from '../disputes/disputes.service';
import { CreateOrderDto } from './dto';
import { CreatePaymentDto } from '../payments/dto/payment.dto';
import { CreateReviewDto } from '../reviews/dto/review.dto';
import { CreateDisputeDto } from '../disputes/dto/dispute.dto';

@ApiTags('Orders')
@Controller('orders')
export class OrdersController {
  constructor(
    private readonly orderCreationService: OrderCreationService,
    private readonly orderDiagnosisService: OrderDiagnosisService,
    private readonly orderQueryService: OrderQueryService,
    private readonly paymentsService: PaymentsService,
    private readonly reviewsService: ReviewsService,
    private readonly disputesService: DisputesService,
  ) {}

  @Post()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async createOrder(@Body() dto: CreateOrderDto) {
    return this.orderCreationService.createOrder(dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async findMyOrders(@GetUser() user: AuthenticatedUser) {
    return this.orderQueryService.findMyOrders(user.id);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async findById(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.orderQueryService.findMyOrderById(user.id, orderId);
  }

  @Post(':id/approve')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async approve(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.orderDiagnosisService.approveOrder(orderId, user.id);
  }

  @Post(':id/reject')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async reject(@GetUser() user: AuthenticatedUser, @Param('id') orderId: string) {
    return this.orderDiagnosisService.rejectOrder(orderId, user.id);
  }

  @Post(':id/payments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createPayment(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: CreatePaymentDto,
  ) {
    return this.paymentsService.createPayment(orderId, user.id, dto);
  }

  @Post(':id/reviews')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createReview(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: CreateReviewDto,
  ) {
    return this.reviewsService.createReview(orderId, user.id, dto);
  }

  @Post(':id/disputes')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createDispute(
    @GetUser() user: AuthenticatedUser,
    @Param('id') orderId: string,
    @Body() dto: CreateDisputeDto,
  ) {
    return this.disputesService.createDispute(orderId, user.id, dto);
  }
}
