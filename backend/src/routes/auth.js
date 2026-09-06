const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const pool = require('../db');
const config = require('../config');

const router = express.Router();

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many login attempts. Try again later.' },
});

function signToken(user) {
  return jwt.sign(
    {
      userId: user.user_id,
      userType: user.user_type,
      institution: user.institution,
    },
    config.jwtSecret,
    { expiresIn: config.jwtExpiresIn }
  );
}

const VALID_USER_TYPES = ['admin', 'teacher', 'student', 'guest'];

/**
 * POST /api/auth/login
 * body: { username, password, institution, userType }
 * Guest logins omit password.
 */
router.post('/login', loginLimiter, async (req, res, next) => {
  try {
    const { username, password, institution, userType } = req.body || {};

    if (!username || !institution || !userType) {
      return res
        .status(400)
        .json({ error: 'username, institution and userType are required' });
    }
    if (!VALID_USER_TYPES.includes(String(userType).toLowerCase())) {
      return res.status(400).json({ error: 'Invalid userType' });
    }

    const type = String(userType).toLowerCase();

    // Guests authenticate with username + institution only.
    if (type === 'guest') {
      const { rows } = await pool.query(
        `INSERT INTO users (user_id, institution, user_type, email, password_hash)
         VALUES ($1, $2, 'guest', NULL, NULL)
         ON CONFLICT (user_id) DO UPDATE SET institution = EXCLUDED.institution
         RETURNING user_id, user_type, institution, email`,
        [String(username).trim(), String(institution).trim()]
      );
      const user = rows[0];
      return res.json({
        status: 'success',
        token: signToken(user),
        user: {
          user_id: user.user_id,
          email: user.email,
          institution: user.institution,
          user_type: user.user_type,
        },
      });
    }

    if (!password) {
      return res.status(400).json({ error: 'password is required' });
    }

    const { rows } = await pool.query(
      'SELECT * FROM users WHERE user_id = $1 AND institution = $2',
      [String(username).trim(), String(institution).trim()]
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = rows[0];

    if (user.user_type !== type) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const ok = await bcrypt.compare(password, user.password_hash || '');
    if (!ok) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    res.json({
      status: 'success',
      token: signToken(user),
      user: {
        user_id: user.user_id,
        email: user.email,
        institution: user.institution,
        user_type: user.user_type,
      },
    });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/auth/signup  (admin account creation)
 * body: { user_id, institution, email, password, user_type }
 */
router.post('/signup', loginLimiter, async (req, res, next) => {
  try {
    const { user_id, institution, email, password, user_type } = req.body || {};

    if (!user_id || !institution || !email || !password) {
      return res.status(400).json({
        error: 'user_id, institution, email and password are required',
      });
    }
    const type = String(user_type || 'admin').toLowerCase();
    if (!['admin', 'teacher', 'student'].includes(type)) {
      return res
        .status(400)
        .json({ error: 'user_type must be admin, teacher or student' });
    }
    if (String(password).length < 6) {
      return res
        .status(400)
        .json({ error: 'Password must be at least 6 characters' });
    }

    const hash = await bcrypt.hash(String(password), 10);

    const { rows } = await pool.query(
      `INSERT INTO users (user_id, institution, user_type, email, password_hash)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING user_id, user_type, institution, email`,
      [String(user_id).trim(), String(institution).trim(), type, String(email).trim(), hash]
    );

    const user = rows[0];
    res.status(201).json({
      success: true,
      token: signToken(user),
      user_id: user.user_id,
      user_type: user.user_type,
      institution: user.institution,
      email: user.email,
    });
  } catch (e) {
    if (e.code === '23505') {
      return res.status(409).json({ error: 'Username already exists' });
    }
    next(e);
  }
});

/**
 * POST /api/auth/fcm-token  — register/update the device push token
 */
router.post('/fcm-token', async (req, res, next) => {
  try {
    const { username, fcm_token } = req.body || {};
    if (!username || !fcm_token) {
      return res
        .status(400)
        .json({ error: 'username and fcm_token are required' });
    }
    await pool.query(
      `INSERT INTO fcm_tokens (username, token, updated_at)
       VALUES ($1, $2, now())
       ON CONFLICT (username) DO UPDATE SET token = EXCLUDED.token, updated_at = now()`,
      [String(username).trim(), String(fcm_token).trim()]
    );
    res.json({ success: true });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
