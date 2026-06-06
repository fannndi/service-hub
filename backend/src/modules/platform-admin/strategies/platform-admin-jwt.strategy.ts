import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class PlatformAdminJwtStrategy extends PassportStrategy(Strategy, 'platform-admin-jwt') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.get<string>('jwt.platformAdminSecret'),
    });
  }

  async validate(payload: any) {
    if (!payload.sub || payload.role !== 'platform_admin') {
      throw new UnauthorizedException();
    }
    return { id: payload.sub, role: payload.role, username: payload.username };
  }
}
