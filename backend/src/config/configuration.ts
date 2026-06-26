export interface AppConfig {
  port: number;
  nodeEnv: string;
  appUrl: string;
  supabase: { projectRef: string; serviceRoleKey: string };
  cors: { origin: string; credentials: boolean };
  database: { url: string };
  redis: { host: string; port: number };
  jwt: {
    accessSecret: string;
    refreshSecret: string;
    accessExpiresIn: string;
    refreshExpiresIn: string;
    storeAccessSecret: string;
    storeRefreshSecret: string;
    platformAdminSecret: string;
  };
  credential: { encryptionKey: string };
  wa: { gatewayUrl: string; token: string; senderNumber: string };
  email: { smtpHost: string; smtpPort: number; smtpUser: string; smtpPass: string; smtpFrom: string; storeEmail: string };
  storage: {
    endpoint: string;
    accessKey: string;
    secretKey: string;
    bucket: string;
    publicUrl: string;
  };
  sla: {
    receiveDevice: number;
    diagnosis: number;
    approval: number;
    payment: number;
    credentialClear: number;
    disputeRespond: number;
  };
  throttle: { ttl: number; limit: number };
  maintenance: { mode: boolean; message: string };
  midtrans: {
    serverKey: string;
    clientKey: string;
    merchantId: string;
    isProduction: boolean;
    snapUrl: string;
  };
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function validateConfig(): void {
  const required = [
    'DATABASE_URL',
    'JWT_ACCESS_SECRET',
    'JWT_REFRESH_SECRET',
    'JWT_STORE_ACCESS_SECRET',
    'JWT_STORE_REFRESH_SECRET',
    'JWT_PLATFORM_ADMIN_SECRET',
    'CREDENTIAL_ENCRYPTION_KEY',
  ];
  for (const name of required) {
    if (!process.env[name]) {
      throw new Error(`Missing required environment variable: ${name}`);
    }
  }
}

export default (): AppConfig => ({
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  appUrl: process.env.APP_URL || 'http://localhost:3000',

  supabase: {
    projectRef: process.env.SUPABASE_PROJECT_REF || '',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  },

  cors: {
    origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
    credentials: process.env.CORS_CREDENTIALS !== 'false',
  },

  database: {
    url: requireEnv('DATABASE_URL'),
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
  },

  jwt: {
    accessSecret: requireEnv('JWT_ACCESS_SECRET'),
    refreshSecret: requireEnv('JWT_REFRESH_SECRET'),
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '1h',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
    storeAccessSecret: requireEnv('JWT_STORE_ACCESS_SECRET'),
    storeRefreshSecret: requireEnv('JWT_STORE_REFRESH_SECRET'),
    platformAdminSecret: requireEnv('JWT_PLATFORM_ADMIN_SECRET'),
  },

  credential: {
    encryptionKey: requireEnv('CREDENTIAL_ENCRYPTION_KEY'),
  },

  wa: {
    gatewayUrl: process.env.WA_GATEWAY_URL || '',
    token: process.env.WA_GATEWAY_TOKEN || '',
    senderNumber: process.env.WA_SENDER_NUMBER || '',
  },

  email: {
    smtpHost: process.env.SMTP_HOST || '',
    smtpPort: parseInt(process.env.SMTP_PORT || '587', 10),
    smtpUser: process.env.SMTP_USER || '',
    smtpPass: process.env.SMTP_PASS || '',
    smtpFrom: process.env.SMTP_FROM || 'noreply@servisgadget.com',
    storeEmail: process.env.STORE_EMAIL || '',
  },

  storage: {
    endpoint: process.env.STORAGE_ENDPOINT || '',
    accessKey: process.env.STORAGE_ACCESS_KEY || '',
    secretKey: process.env.STORAGE_SECRET_KEY || '',
    bucket: process.env.STORAGE_BUCKET || '',
    publicUrl: process.env.STORAGE_PUBLIC_URL || '',
  },

  sla: {
    receiveDevice: parseInt(process.env.SLA_RECEIVE_DEVICE_MINUTES || '1440', 10),
    diagnosis: parseInt(process.env.SLA_DIAGNOSIS_MINUTES || '1440', 10),
    approval: parseInt(process.env.SLA_APPROVAL_MINUTES || '1440', 10),
    payment: parseInt(process.env.SLA_PAYMENT_MINUTES || '2880', 10),
    credentialClear: parseInt(process.env.SLA_CREDENTIAL_CLEAR_MINUTES || '1440', 10),
    disputeRespond: parseInt(process.env.SLA_DISPUTE_RESPOND_MINUTES || '1440', 10),
  },

  throttle: {
    ttl: parseInt(process.env.THROTTLE_TTL_SECONDS || '60', 10),
    limit: parseInt(process.env.THROTTLE_LIMIT || '100', 10),
  },

  maintenance: {
    mode: process.env.MAINTENANCE_MODE === 'true',
    message: process.env.MAINTENANCE_MESSAGE || 'Sedang Maintenance',
  },

  midtrans: {
    serverKey: requireEnv('MIDTRANS_SERVER_KEY'),
    clientKey: process.env.MIDTRANS_CLIENT_KEY || '',
    merchantId: process.env.MIDTRANS_MERCHANT_ID || '',
    isProduction: process.env.MIDTRANS_IS_PRODUCTION === 'true',
    snapUrl: process.env.MIDTRANS_IS_PRODUCTION === 'true'
      ? 'https://app.midtrans.com/snap/v1/transactions'
      : 'https://app.sandbox.midtrans.com/snap/v1/transactions',
  },
});
