import { Injectable, HttpStatus } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../common/prisma/prisma.service';
import { AppException } from '../../common/exceptions';
import { JwtPayload } from '../../common/types/jwt-payload.type';
import { AppConfig } from '../../config/configuration';

@Injectable()
export class PlatformAuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private config: ConfigService<AppConfig>,
  ) {}

  async login(username: string, password: string) {
    const admin = await this.prisma.platformAdmin.findFirst({
      where: { username, isActive: true },
    });
    if (!admin || !(await bcrypt.compare(password, admin.passwordHash))) {
      throw new AppException(
        'INVALID_CREDENTIALS',
        'Invalid credentials',
        'Username atau password salah.',
        HttpStatus.UNAUTHORIZED,
      );
    }

    await this.prisma.platformAdmin.update({
      where: { id: admin.id },
      data: { lastLoginAt: new Date() },
    });

    const payload: JwtPayload = { sub: admin.id, role: 'platform_admin', username: admin.username };
    const token = this.jwt.sign(payload, {
      secret: this.config.get('jwt.platformAdminSecret', { infer: true }),
      expiresIn: '12h',
    });

    return {
      accessToken: token,
      admin: { id: admin.id, username: admin.username, fullName: admin.fullName },
    };
  }
}
