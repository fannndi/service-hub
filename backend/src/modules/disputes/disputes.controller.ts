import { Controller, Post, Get, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { DisputesService } from './disputes.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Disputes')
@Controller('disputes')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class DisputesController {
  constructor(private readonly disputesService: DisputesService) {}

  @Post(':orderId')
  async createDispute(
    @GetUser('id') userId: string,
    @Param('orderId') orderId: string,
    @Body() dto: any,
  ) {
    return this.disputesService.createDispute(orderId, userId, dto);
  }

  @Get()
  async findMyDisputes(@GetUser('id') userId: string) {
    return this.disputesService.findMyDisputes(userId);
  }
}

@ApiTags('Store Disputes')
@Controller('store/disputes')
@UseGuards(StoreJwtAuthGuard)
@ApiBearerAuth()
export class StoreDisputesController {
  constructor(private readonly disputesService: DisputesService) {}

  @Get()
  async findStoreDisputes(@GetUser('storeId') storeId: string) {
    return this.disputesService.findStoreDisputes(storeId);
  }

  @Post(':id/respond')
  async respondDispute(
    @GetUser('id') adminId: string,
    @GetUser('storeId') storeId: string,
    @Param('id') disputeId: string,
    @Body() dto: any,
  ) {
    return this.disputesService.respondDispute(disputeId, adminId, storeId, dto);
  }
}
