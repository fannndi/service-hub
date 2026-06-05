import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { StoreAuthService } from './store-auth.service';
import { StoreAuthController } from './store-auth.controller';
import { StoreJwtAccessStrategy } from './strategies/store-jwt-access.strategy';
import { StoreJwtRefreshStrategy } from './strategies/store-jwt-refresh.strategy';

@Module({
  imports: [
    PassportModule,
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('jwt.storeAccessSecret'),
        signOptions: { expiresIn: '1h' },
      }),
    }),
  ],
  controllers: [StoreAuthController],
  providers: [StoreAuthService, StoreJwtAccessStrategy, StoreJwtRefreshStrategy],
  exports: [StoreAuthService],
})
export class StoreAuthModule {}
