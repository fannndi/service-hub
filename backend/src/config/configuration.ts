import { registerAs } from '@nestjs/config';

export interface AppConfig {
  port: number;
  databaseUrl: string;
  redis: {
    host: string;
    port: number;
  };
  jwt: {
    customerSecret: string;
    storeSecret: string;
    expiresIn: string;
  };
  bcryptCost: number;
}

export default registerAs('app', (): AppConfig => ({
  port: parseInt(process.env.PORT || '3000', 10),
  databaseUrl: process.env.DATABASE_URL || '',
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
  },
  jwt: {
    customerSecret: process.env.CUSTOMER_JWT_SECRET || 'def-cust-secret-key-12345',
    storeSecret: process.env.STORE_JWT_SECRET || 'def-store-secret-key-12345',
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  },
  bcryptCost: parseInt(process.env.BCRYPT_COST || '12', 10),
}));
