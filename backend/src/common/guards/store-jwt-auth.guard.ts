import { Injectable, ExecutionContext } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TokenInvalidException } from '../exceptions';

@Injectable()
export class StoreJwtAuthGuard extends AuthGuard('store-jwt-access') {
  handleRequest(err: any, user: any): any {
    if (err || !user) throw new TokenInvalidException();
    return user;
  }
}
