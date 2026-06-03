import { Controller, Post, Body, HttpCode, HttpStatus, UnauthorizedException, ForbiddenException } from '@nestjs/common';
import { CustomerAuthService } from './customer-auth.service';
import { LoginDto, ChangePasswordDto } from './dto/auth.dto';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('auth')
@Controller('auth')
export class CustomerAuthController {
  constructor(private authService: CustomerAuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto.phoneNumber, dto.password);
  }

  @Post('change-password')
  @HttpCode(HttpStatus.OK)
  changePassword(@Body() dto: ChangePasswordDto) {
    return this.authService.changePassword(dto.phoneNumber, dto.oldPassword, dto.newPassword);
  }
}
