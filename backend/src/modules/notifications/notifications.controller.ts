import { Controller, Get, Post, Patch, Param, Query, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { InAppNotificationsService } from './in-app-notifications.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { StoreJwtAuthGuard } from '../../common/guards/store-jwt-auth.guard';
import { PlatformAdminGuard } from '../platform-admin/platform-admin.guard';
import { GetUser } from '../../common/decorators/get-user.decorator';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';

@ApiTags('Notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notif: InAppNotificationsService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async list(@GetUser() user: AuthenticatedUser, @Query('page') page?: string) {
    return this.notif.findForUser(user.id, user.role, parseInt(page || '1'));
  }

  @Get('unread-count')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async unreadCount(@GetUser() user: AuthenticatedUser) {
    const count = await this.notif.unreadCount(user.id, user.role);
    return { count };
  }

  @Patch(':id/read')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async markRead(@GetUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.notif.markAsRead(id, user.id);
    return { message: 'ok' };
  }

  @Patch('read-all')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async markAllRead(@GetUser() user: AuthenticatedUser) {
    await this.notif.markAllRead(user.id, user.role);
    return { message: 'ok' };
  }

  @Post('test')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  async sendTest(@GetUser() user: AuthenticatedUser) {
    await this.notif.create({
      userId: user.id,
      role: user.role,
      title: 'Notifikasi Test',
      message: 'Ini adalah notifikasi percobaan. Jika kamu melihat ini, sistem notifikasi berjalan dengan baik.',
      type: 'test',
    });
    return { message: 'Notifikasi test terkirim.' };
  }

  @Post('broadcast')
  @UseGuards(PlatformAdminGuard)
  @ApiBearerAuth()
  async broadcast(@Body() dto: { role: string; title: string; message: string }) {
    await this.notif.broadcast(dto.role, dto.title, dto.message);
    return { message: 'Broadcast terkirim.' };
  }
}

@ApiTags('Store Notifications')
@Controller('store/notifications')
export class StoreNotificationsController {
  constructor(private readonly notif: InAppNotificationsService) {}

  @Get()
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async list(@GetUser() user: AuthenticatedUser, @Query('page') page?: string) {
    return this.notif.findForStore(user.storeId!, parseInt(page || '1'));
  }

  @Get('unread-count')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async unreadCount(@GetUser() user: AuthenticatedUser) {
    const count = await this.notif.unreadCountByStore(user.storeId!);
    return { count };
  }

  @Patch(':id/read')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async markRead(@GetUser() user: AuthenticatedUser, @Param('id') id: string) {
    await this.notif.markStoreNotificationAsRead(id, user.storeId!);
    return { message: 'ok' };
  }

  @Patch('read-all')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async markAllRead(@GetUser() user: AuthenticatedUser) {
    await this.notif.markAllStoreRead(user.storeId!);
    return { message: 'ok' };
  }

  @Post('test')
  @UseGuards(StoreJwtAuthGuard)
  @ApiBearerAuth()
  async sendTest(@GetUser() user: AuthenticatedUser) {
    await this.notif.create({
      storeId: user.storeId!,
      role: 'store_admin',
      title: 'Notifikasi Test',
      message: 'Ini adalah notifikasi percobaan untuk toko.',
      type: 'test',
    });
    return { message: 'Notifikasi test terkirim.' };
  }
}
