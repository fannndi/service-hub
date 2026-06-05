export interface JwtPayload {
  sub: string;
  role: 'customer' | 'store_admin';
  storeId?: string;
  isFirstLogin?: boolean;
  iat?: number;
  exp?: number;
}
