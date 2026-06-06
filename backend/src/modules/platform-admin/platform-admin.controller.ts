import { Controller, Post, Get, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PlatformAdminService } from './platform-admin.service';
import { AdminLoginDto, CreateStoreDto } from './dto/platform-admin.dto';
import { PlatformAdminGuard } from './platform-admin.guard';

@ApiTags('Platform Admin')
@Controller('platform')
export class PlatformAdminController {
  constructor(private readonly platformAdminService: PlatformAdminService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: AdminLoginDto) {
    return this.platformAdminService.login(dto.username, dto.password);
  }

  @Post('stores')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.CREATED)
  async createStore(@Body() dto: CreateStoreDto) {
    return this.platformAdminService.createStore(dto);
  }

  @Get('stores')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async listStores() {
    return this.platformAdminService.listStores();
  }
}
