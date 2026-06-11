import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload, AuthenticatedUser } from '../../../common/types/jwt-payload.type';
import { AppConfig } from '../../../config/configuration';

@Injectable()
export class StoreJwtAccessStrategy extends PassportStrategy(Strategy, 'store-jwt-access') {
  constructor(config: ConfigService<AppConfig>) {
    const secret = config.get('jwt.storeAccessSecret', { infer: true });
    if (!secret) throw new Error('JWT_STORE_ACCESS_SECRET not configured');
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    if (!payload.storeId) throw new UnauthorizedException();
    return {
      id: payload.sub,
      role: payload.role,
      storeId: payload.storeId,
      isFirstLogin: payload.isFirstLogin,
    };
  }
}
