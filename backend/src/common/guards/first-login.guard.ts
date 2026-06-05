import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { FirstLoginRequiredException } from '../exceptions';

@Injectable()
export class FirstLoginGuard implements CanActivate {
  canActivate(ctx: ExecutionContext): boolean {
    const user = ctx.switchToHttp().getRequest().user;
    if (user?.isFirstLogin === true) throw new FirstLoginRequiredException();
    return true;
  }
}
