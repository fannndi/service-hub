import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload, Role } from '../../../common/types/auth.types';

@Injectable()
export class StoreJwtStrategy extends PassportStrategy(Strategy, 'store-jwt') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('app.jwt.storeSecret'),
    });
  }

  validate(payload: JwtPayload) {
    if (payload.role !== Role.STORE_ADMIN) {
      throw new UnauthorizedException('Not a store admin');
    }
    return { id: payload.sub, role: payload.role, storeId: payload.storeId };
  }
}
