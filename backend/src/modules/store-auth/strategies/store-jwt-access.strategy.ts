import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload } from '../../../common/types/jwt-payload.type';

@Injectable()
export class StoreJwtAccessStrategy extends PassportStrategy(Strategy, 'store-jwt-access') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.get<string>('jwt.storeAccessSecret'),
    });
  }

  async validate(payload: JwtPayload) {
    if (!payload.storeId) throw new UnauthorizedException();
    return {
      id: payload.sub,
      role: payload.role,
      storeId: payload.storeId,
      isFirstLogin: payload.isFirstLogin,
    };
  }
}
