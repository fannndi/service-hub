import { Controller, Post, Get, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { PaymentsService } from '../payments/payments.service';
import { ReviewsService } from '../reviews/reviews.service';
import { DisputesService } from '../disputes/disputes.service';

@ApiTags('Orders')
@Controller('orders')
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
    private readonly paymentsService: PaymentsService,
    private readonly reviewsService: ReviewsService,
    private readonly disputesService: DisputesService,
  ) {}

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

  // Payment sub-route: POST /orders/:id/payments
  @Post(':id/payments')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createPayment(
    @GetUser('id') userId: string,
    @Param('id') orderId: string,
    @Body() dto: any,
  ) {
    return this.paymentsService.createPayment(orderId, userId, dto);
  }

  // Review sub-route: POST /orders/:id/reviews
  @Post(':id/reviews')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createReview(
    @GetUser('id') userId: string,
    @Param('id') orderId: string,
    @Body() dto: any,
  ) {
    return this.reviewsService.createReview(orderId, userId, dto);
  }

  // Dispute sub-route: POST /orders/:id/disputes
  @Post(':id/disputes')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async createDispute(
    @GetUser('id') userId: string,
    @Param('id') orderId: string,
    @Body() dto: any,
  ) {
    return this.disputesService.createDispute(orderId, userId, dto);
  }
}
