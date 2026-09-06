require('dotenv').config();

const config = {
  port: process.env.PORT || 3000,
  // Supabase connection string (Session pooler, port 5432)
  databaseUrl: process.env.DATABASE_URL,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  // Shared secret the NodeMCU must send as "x-device-key" header
  deviceApiKey: process.env.DEVICE_API_KEY,
  // Minutes: device is considered "connected" if it heartbeats within this window
  deviceOfflineAfterMinutes: parseInt(process.env.DEVICE_OFFLINE_MINUTES || '2', 10),
  // Max stored media size (bytes) — media is stored in Postgres as bytea
  maxMediaBytes: parseInt(process.env.MAX_MEDIA_BYTES || '5242880', 10), // 5 MB
};

if (!config.databaseUrl) {
  console.error('FATAL: DATABASE_URL is not set. Add your Supabase connection string to the environment.');
  process.exit(1);
}

if (!config.jwtSecret) {
  console.error('FATAL: JWT_SECRET is not set. Generate one with: openssl rand -hex 32');
  process.exit(1);
}

if (!config.deviceApiKey) {
  console.error('FATAL: DEVICE_API_KEY is not set. Generate one with: openssl rand -hex 16');
  process.exit(1);
}

module.exports = config;
