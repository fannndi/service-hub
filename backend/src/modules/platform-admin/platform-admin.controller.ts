import { Controller, Post, Get, Patch, Body, Param, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PlatformAdminService } from './platform-admin.service';
import { AdminLoginDto, CreateStoreDto, ChangePasswordDto } from './dto/platform-admin.dto';
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

  @Get('users')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async listUsers() {
    return this.platformAdminService.listUsers();
  }

  @Get('users/:id')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async getUser(@Param('id') id: string) {
    return this.platformAdminService.getUser(id);
  }

  @Patch('users/:id/password')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async changeUserPassword(@Param('id') id: string, @Body() dto: ChangePasswordDto) {
    return this.platformAdminService.changeUserPassword(id, dto.newPassword);
  }

  @Get('store-admins')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async listStoreAdmins() {
    return this.platformAdminService.listStoreAdmins();
  }

  @Patch('store-admins/:id/password')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async changeStoreAdminPassword(@Param('id') id: string, @Body() dto: ChangePasswordDto) {
    return this.platformAdminService.changeStoreAdminPassword(id, dto.newPassword);
  }
}
