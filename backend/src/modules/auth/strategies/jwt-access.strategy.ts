import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { JwtPayload, AuthenticatedUser } from '../../../common/types/jwt-payload.type';
import { AppConfig } from '../../../config/configuration';

@Injectable()
export class JwtAccessStrategy extends PassportStrategy(Strategy, 'jwt-access') {
  constructor(config: ConfigService<AppConfig>) {
    const secret = config.get('jwt.accessSecret', { infer: true });
    if (!secret) throw new Error('JWT_ACCESS_SECRET not configured');
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    return {
      id: payload.sub,
      role: payload.role,
      isFirstLogin: payload.isFirstLogin,
    };
  }
}
