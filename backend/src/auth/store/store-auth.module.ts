import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { StoreAuthController } from './store-auth.controller';
import { StoreAuthService } from './store-auth.service';
import { StoreJwtStrategy } from './strategies/store-jwt.strategy';

@Module({
  imports: [
    PassportModule.register({ defaultStrategy: 'store-jwt' }),
    JwtModule.register({}),
  ],
  controllers: [StoreAuthController],
  providers: [StoreAuthService, StoreJwtStrategy],
  exports: [StoreAuthService],
})
export class StoreAuthModule {}
