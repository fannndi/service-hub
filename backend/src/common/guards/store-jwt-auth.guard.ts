import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { TokenInvalidException } from '../exceptions';
import { AuthenticatedUser } from '../types/jwt-payload.type';

@Injectable()
export class StoreJwtAuthGuard extends AuthGuard('store-jwt-access') {
  handleRequest(err: unknown, user: AuthenticatedUser | false): AuthenticatedUser {
    if (err || !user) throw new TokenInvalidException();
    return user;
  }
}
