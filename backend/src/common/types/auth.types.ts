export enum Role {
  CUSTOMER = 'customer',
  STORE_ADMIN = 'store_admin',
}

export interface JwtPayload {
  sub: string;
  role: Role;
  storeId?: string; // only for store_admin
}

export interface AuthenticatedUser {
  id: string;
  role: Role;
  storeId?: string;
}
