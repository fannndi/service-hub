export default () => ({
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  appUrl: process.env.APP_URL || 'http://localhost:3000',

  database: {
    url: process.env.DATABASE_URL,
  },

  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
  },

  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET,
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '1h',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
    storeAccessSecret: process.env.JWT_STORE_ACCESS_SECRET,
    storeRefreshSecret: process.env.JWT_STORE_REFRESH_SECRET,
  },

  credential: {
    encryptionKey: process.env.CREDENTIAL_ENCRYPTION_KEY,
  },

  wa: {
    gatewayUrl: process.env.WA_GATEWAY_URL,
    token: process.env.WA_GATEWAY_TOKEN,
    senderNumber: process.env.WA_SENDER_NUMBER,
  },

  storage: {
    endpoint: process.env.STORAGE_ENDPOINT,
    accessKey: process.env.STORAGE_ACCESS_KEY,
    secretKey: process.env.STORAGE_SECRET_KEY,
    bucket: process.env.STORAGE_BUCKET,
    publicUrl: process.env.STORAGE_PUBLIC_URL,
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
});
