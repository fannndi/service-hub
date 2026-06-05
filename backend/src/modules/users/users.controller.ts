import { Controller, Get, Patch, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { FirstLoginGuard } from '../../common/guards/first-login.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';

@ApiTags('Users')
@Controller('me')
@UseGuards(JwtAuthGuard, FirstLoginGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  async getProfile(@GetUser('id') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @Patch()
  async updateProfile(
    @GetUser('id') userId: string,
    @Body() dto: { fullName?: string; address?: string; avatarUrl?: string },
  ) {
    return this.usersService.updateProfile(userId, dto);
  }

  @Get('coupons')
  async getCoupons(@GetUser('id') userId: string) {
    return this.usersService.getCoupons(userId);
  }
}
