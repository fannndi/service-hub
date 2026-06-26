import { Controller, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { GuestOrdersService } from './guest-orders.service';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';
import { GuestTrackDto, GuestCredentialsDto } from './dto';

@ApiTags('Guest Orders')
@Controller('orders/guest')
export class GuestOrdersController {
  constructor(private readonly guestOrdersService: GuestOrdersService) {}

  @Post('track')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async track(@Body() dto: GuestTrackDto) {
    return this.guestOrdersService.verifyAndTrack(dto.orderNumber, dto.phoneNumber);
  }

  @Post('credentials')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async credentials(@Body() dto: GuestCredentialsDto) {
    return this.guestOrdersService.getCredentials(dto.orderId, dto.phoneNumber);
  }

  @Post(':orderId/activate')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async activate(
    @GetUser() user: AuthenticatedUser,
    @Param('orderId') orderId: string,
  ) {
    return this.guestOrdersService.activateGuestAccount(orderId, user.storeId!);
  }
}
