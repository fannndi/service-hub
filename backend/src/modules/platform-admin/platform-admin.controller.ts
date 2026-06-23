import { Controller, Post, Get, Patch, Body, Param, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { PlatformAuthService } from './platform-auth.service';
import { PlatformStoreService } from './platform-store.service';
import { PlatformUserService } from './platform-user.service';
import { PlatformAdminMgmtService } from './platform-admin-mgmt.service';
import { AdminLoginDto, CreateStoreDto, ChangePasswordDto, UpdateUserDto, UpdateStoreDto } from './dto/platform-admin.dto';
import { PlatformAdminGuard } from './platform-admin.guard';

@ApiTags('Platform Admin')
@Controller('platform')
export class PlatformAdminController {
  constructor(
    private readonly platformAuthService: PlatformAuthService,
    private readonly platformStoreService: PlatformStoreService,
    private readonly platformUserService: PlatformUserService,
    private readonly platformAdminMgmtService: PlatformAdminMgmtService,
  ) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() dto: AdminLoginDto) {
    return this.platformAuthService.login(dto.username, dto.password);
  }

  @Post('stores')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.CREATED)
  async createStore(@Body() dto: CreateStoreDto) {
    return this.platformStoreService.createStore(dto);
  }

  @Get('stores')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async listStores() {
    return this.platformStoreService.listStores();
  }

  @Patch('stores/:id')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async updateStore(@Param('id') id: string, @Body() dto: UpdateStoreDto) {
    return this.platformStoreService.updateStore(id, dto);
  }

  @Get('users')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async listUsers() {
    return this.platformUserService.listUsers();
  }

  @Get('users/:id')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async getUser(@Param('id') id: string) {
    return this.platformUserService.getUser(id);
  }

  @Patch('users/:id')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async updateUser(@Param('id') id: string, @Body() dto: UpdateUserDto) {
    return this.platformUserService.updateUser(id, dto);
  }

  @Patch('users/:id/password')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async changeUserPassword(@Param('id') id: string, @Body() dto: ChangePasswordDto) {
    return this.platformUserService.changeUserPassword(id, dto.newPassword);
  }

  @Get('store-admins')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async listStoreAdmins() {
    return this.platformAdminMgmtService.listStoreAdmins();
  }

  @Patch('store-admins/:id/password')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  async changeStoreAdminPassword(@Param('id') id: string, @Body() dto: ChangePasswordDto) {
    return this.platformAdminMgmtService.changeStoreAdminPassword(id, dto.newPassword);
  }
}
