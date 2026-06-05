import { Controller, Post, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { StoreAuthService } from './store-auth.service';
import { StoreLoginDto, StoreChangePasswordDto } from './dto/store-auth.dto';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Store Auth')
@Controller('store/auth')
export class StoreAuthController {
  constructor(private readonly storeAuthService: StoreAuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: StoreLoginDto) {
    return this.storeAuthService.login(dto.phoneNumber, dto.password);
  }

  @Post('change-password')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async changePassword(@GetUser('id') adminId: string, @Body() dto: StoreChangePasswordDto) {
    return this.storeAuthService.changePassword(adminId, dto.oldPassword, dto.newPassword);
  }
}
