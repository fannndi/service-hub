# Structured Logging

Backend menggunakan `nestjs-pino` untuk structured JSON logging.

## Log Format (Production)

```json
{
  "level": 30,
  "time": 1718467200000,
  "pid": 1,
  "hostname": "server",
  "req": { "method": "GET", "url": "/v1/stores" },
  "res": { "statusCode": 200 },
  "responseTime": 45
}
```

## Log Levels

| Environment | Level |
|------------|-------|
| development | `debug` (pretty-print dengan pino-pretty) |
| production | `info` (JSON untuk log aggregator) |

## Exception Logging

Semua unhandled exception di `GlobalExceptionFilter` mencatat:
- method + url
- userId (jika terautentikasi)
- error message + stack trace
- status code

## Konfigurasi

Di `logger.module.ts`:
- Dev: transport = `pino-pretty` (colorized, timestamp `HH:MM:ss`)
- Prod: transport = `undefined` (JSON stdout)
- Request serializers: hanya `method`, `url`, `statusCode` (no sensitive headers)
