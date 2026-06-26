import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../common/prisma/prisma.service';
import { JwtPayload, AuthenticatedUser } from '../../../common/types/jwt-payload.type';
import { AppConfig } from '../../../config/configuration';

@Injectable()
export class JwtAccessStrategy extends PassportStrategy(Strategy, 'jwt-access') {
  constructor(
    config: ConfigService<AppConfig>,
    private prisma: PrismaService,
  ) {
    const secret = config.get('jwt.accessSecret', { infer: true });
    if (!secret) throw new Error('JWT_ACCESS_SECRET not configured');
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: secret,
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: { accountStatus: true },
    });
    if (!user || user.accountStatus !== 'active') {
      throw new UnauthorizedException('Account is suspended or inactive');
    }
    return {
      id: payload.sub,
      role: payload.role,
      isFirstLogin: payload.isFirstLogin,
    };
  }
}
