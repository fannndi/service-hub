import { Controller, Post, Body, HttpCode, HttpStatus, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { StoreAuthService } from './store-auth.service';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('store-auth')
@Controller('store/auth')
export class StoreAuthController {
  constructor(private authService: StoreAuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: { phoneNumber: string; password: string }) {
    return this.authService.login(dto.phoneNumber, dto.password);
  }
}
