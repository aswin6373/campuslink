const { Pool } = require('pg');
const config = require('./config');

// Supabase provides PgBouncer; a small pool is plenty for this app.
const needsSsl = !/localhost|127\.0\.0\.1/.test(config.databaseUrl);
const pool = new Pool({
  connectionString: config.databaseUrl,
  ssl: needsSsl ? { rejectUnauthorized: false } : undefined,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  console.error('Unexpected Postgres pool error:', err.message);
});

module.exports = pool;
