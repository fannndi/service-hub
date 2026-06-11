import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TokenInvalidException } from '../../common/exceptions';
import { AuthenticatedUser } from '../../common/types/jwt-payload.type';

@Injectable()
export class PlatformAdminGuard extends AuthGuard('platform-admin-jwt') {
  handleRequest(err: unknown, user: AuthenticatedUser | false): AuthenticatedUser {
    if (err || !user) throw new TokenInvalidException();
    return user;
  }
}
