const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const config = require('./config');
const pool = require('./db');

const app = express();

app.set('trust proxy', 1); // behind Render's proxy
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '8mb' })); // base64 media fits here
app.use(morgan('tiny'));

// Basic rate limiting on the whole API
app.use(
  '/api',
  rateLimit({
    windowMs: 60 * 1000,
    max: 300,
    standardHeaders: true,
    legacyHeaders: false,
    message: { error: 'Too many requests' },
  })
);

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api', require('./routes/people')); // /api/students, /api/teachers, /api/counts
app.use('/api/attendance', require('./routes/attendance'));
app.use('/api/events', require('./routes/events'));
app.use('/api/posts', require('./routes/posts'));
app.use('/api/chatroom', require('./routes/chatroom'));
app.use('/api/chatbot', require('./routes/chatbot'));
app.use('/api/profile', require('./routes/profile'));
app.use('/api/device', require('./routes/device'));

// Health check (used by Render)
app.get('/healthz', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', db: 'up' });
  } catch (e) {
    console.error('Health check DB error:', e.message);
    res.status(503).json({ status: 'degraded', db: 'down' });
  }
});

// 404
app.use((req, res) => res.status(404).json({ error: 'Not found' }));

// Error handler
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  console.error('API error:', err.message);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(config.port, () => {
  console.log(`CampusLink API listening on port ${config.port}`);
});
