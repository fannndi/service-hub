import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TokenInvalidException } from '../../common/exceptions';

@Injectable()
export class PlatformAdminGuard extends AuthGuard('platform-admin-jwt') {
  handleRequest(err: any, user: any): any {
    if (err || !user) throw new TokenInvalidException();
    return user;
  }
}
