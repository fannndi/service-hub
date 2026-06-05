import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload } from '../../../common/types/jwt-payload.type';

@Injectable()
export class StoreJwtRefreshStrategy extends PassportStrategy(Strategy, 'store-jwt-refresh') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.get<string>('jwt.storeRefreshSecret'),
    });
  }

  async validate(payload: JwtPayload) {
    return { id: payload.sub, role: payload.role, storeId: payload.storeId };
  }
}
