export interface JwtPayload {
  sub: string;
  role: 'customer' | 'store_admin' | 'platform_admin';
  storeId?: string;
  isFirstLogin?: boolean;
  username?: string;
  iat?: number;
  exp?: number;
}

export interface AuthenticatedUser {
  id: string;
  role: 'customer' | 'store_admin' | 'platform_admin';
  storeId?: string;
  isFirstLogin?: boolean;
  username?: string;
}
