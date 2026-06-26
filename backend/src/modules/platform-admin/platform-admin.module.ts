import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { PlatformAuthService } from './platform-auth.service';
import { PlatformStoreService } from './platform-store.service';
import { PlatformUserService } from './platform-user.service';
import { PlatformAdminMgmtService } from './platform-admin-mgmt.service';
import { PlatformAdminController } from './platform-admin.controller';
import { PlatformAdminJwtStrategy } from './strategies/platform-admin-jwt.strategy';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('jwt.platformAdminSecret'),
        signOptions: { expiresIn: '12h' },
      }),
    }),
  ],
  controllers: [PlatformAdminController],
  providers: [
    PlatformAuthService,
    PlatformStoreService,
    PlatformUserService,
    PlatformAdminMgmtService,
    PlatformAdminJwtStrategy,
  ],
})
export class PlatformAdminModule {}
