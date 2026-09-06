const { Pool } = require('pg');
const config = require('./config');

// Supabase provides PgBouncer; a small pool is plenty for this app.
// NOTE: we strip sslmode from the URL and set SSL explicitly below —
// newer pg drivers treat `sslmode=require` as strict verify-full, which
// fails against Supabase's pooler certificate.
const needsSsl = !/localhost|127\.0\.0\.1/.test(config.databaseUrl);
const cleanUrl = config.databaseUrl.replace(/[?&]sslmode=[^&]*/g, '');

const pool = new Pool({
  connectionString: cleanUrl,
  ssl: needsSsl ? { rejectUnauthorized: false } : undefined,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  console.error('Unexpected Postgres pool error:', err.message);
});

// Fail fast at startup if the database is unreachable, and print why.
(async () => {
  try {
    await pool.query('SELECT 1');
    console.log('Database connection OK');
  } catch (err) {
    console.error('DATABASE CONNECTION FAILED:', err.message);
  }
})();

module.exports = pool;
