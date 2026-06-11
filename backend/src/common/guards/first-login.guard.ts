import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { FirstLoginRequiredException } from '../exceptions';
import { AuthenticatedUser } from '../types/jwt-payload.type';

@Injectable()
export class FirstLoginGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as AuthenticatedUser;
    if (user?.isFirstLogin === true) throw new FirstLoginRequiredException();
    return true;
  }
}
