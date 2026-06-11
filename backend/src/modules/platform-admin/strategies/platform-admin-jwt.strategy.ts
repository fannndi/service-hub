import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload, AuthenticatedUser } from '../../../common/types/jwt-payload.type';
import { AppConfig } from '../../../config/configuration';

@Injectable()
export class PlatformAdminJwtStrategy extends PassportStrategy(Strategy, 'platform-admin-jwt') {
  constructor(config: ConfigService<AppConfig>) {
    const secret = config.get('jwt.platformAdminSecret', { infer: true });
    if (!secret) throw new Error('JWT_PLATFORM_ADMIN_SECRET not configured');
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    if (!payload.sub || payload.role !== 'platform_admin') {
      throw new UnauthorizedException();
    }
    return {
      id: payload.sub,
      role: payload.role,
      username: payload.username,
    };
  }
}
