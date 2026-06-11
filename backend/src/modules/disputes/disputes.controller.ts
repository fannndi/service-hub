import { Controller, Post, Get, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { DisputesService } from './disputes.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { CreateDisputeDto, RespondDisputeDto } from './dto/dispute.dto';

@ApiTags('Disputes')
@Controller('disputes')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class DisputesController {
  constructor(private readonly disputesService: DisputesService) {}

  @Post(':orderId')
  async createDispute(
    @GetUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
    @Body() dto: CreateDisputeDto,
  ) {
    return this.disputesService.createDispute(orderId, user.id, dto);
  }

  @Get()
  async findMyDisputes(@GetUser() user: AuthenticatedUser) {
    return this.disputesService.findMyDisputes(user.id);
  }
}

@ApiTags('Store Disputes')
@Controller('store/disputes')
@UseGuards(StoreJwtAuthGuard)
@ApiBearerAuth()
export class StoreDisputesController {
  constructor(private readonly disputesService: DisputesService) {}

  @Get()
  async findStoreDisputes(@GetUser() user: AuthenticatedUser) {
    return this.disputesService.findStoreDisputes(user.storeId!);
  }

  @Post(':id/respond')
  async respondDispute(
    @GetUser() user: AuthenticatedUser,
    @Param('id') disputeId: string,
    @Body() dto: RespondDisputeDto,
  ) {
    return this.disputesService.respondDispute(disputeId, user.id, user.storeId!, dto);
  }
}
