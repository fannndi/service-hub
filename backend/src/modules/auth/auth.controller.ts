import {
  Controller,
  Post,
  Body,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { LoginDto, ChangePasswordDto } from './dto/auth.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: LoginDto, @Req() req: Request) {
    const ip =
      (req.headers['x-forwarded-for'] as string) || req.ip || 'unknown';
    return this.authService.login(dto.phoneNumber, dto.password, ip);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(
    @Body('refreshToken') refreshToken: string | undefined,
    @Body('refresh_token') refreshTokenSnake: string | undefined,
    @Req() req: Request,
  ) {
    const ip =
      (req.headers['x-forwarded-for'] as string) || req.ip || 'unknown';
    return this.authService.refresh(
      refreshToken ?? refreshTokenSnake ?? '',
      ip,
    );
  }

  @Post('change-password')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async changePassword(
    @GetUser() user: AuthenticatedUser,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(
      user.id,
      dto.oldPassword,
      dto.newPassword,
    );
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async logout(
    @GetUser() user: AuthenticatedUser,
    @Body('refreshToken') refreshToken: string | undefined,
    @Body('refresh_token') refreshTokenSnake: string | undefined,
  ) {
    await this.authService.logout(
      user.id,
      refreshToken ?? refreshTokenSnake ?? '',
    );
    return { message: 'Logout berhasil.' };
  }

  @Post('logout-all')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async logoutAll(@GetUser() user: AuthenticatedUser) {
    await this.authService.logoutAll(user.id);
    return { message: 'Semua sesi telah diakhiri.' };
  }
}
