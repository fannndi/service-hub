import { Controller, Post, Body, UseGuards, HttpCode, HttpStatus, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import { StoreAuthService } from './store-auth.service';
import { StoreLoginDto, StoreChangePasswordDto } from './dto/store-auth.dto';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';

@ApiTags('Store Auth')
@Controller('store/auth')
export class StoreAuthController {
  constructor(private readonly storeAuthService: StoreAuthService) {}

  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: StoreLoginDto, @Req() req: Request) {
    const ip = (req.headers['x-forwarded-for'] as string) || req.socket.remoteAddress || 'unknown';
    return this.storeAuthService.login(dto.phoneNumber, dto.password, ip);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body('refresh_token') refreshToken: string, @Req() req: Request) {
    const ip = (req.headers['x-forwarded-for'] as string) || req.socket.remoteAddress || 'unknown';
    return this.storeAuthService.refresh(refreshToken, ip);
  }

  @Post('change-password')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async changePassword(@GetUser() user: AuthenticatedUser, @Body() dto: StoreChangePasswordDto) {
    return this.storeAuthService.changePassword(user.id, dto.oldPassword, dto.newPassword);
  }

  @Post('logout')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async logout(@GetUser() user: AuthenticatedUser, @Body('refresh_token') refreshToken: string) {
    return this.storeAuthService.logout(user.id, refreshToken);
  }
}
