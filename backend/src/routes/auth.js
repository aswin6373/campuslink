const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const pool = require('../db');
const config = require('../config');

const router = express.Router();

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
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

/** Normalize institution: trim + lowercase, so "Ebenezer" == "ebenezer". */
function normInst(value) {
  return String(value || '').trim().toLowerCase();
}

/** Maps an account status to a friendly login error (null = ok). */
function statusError(status) {
  switch (status) {
    case 'pending':
      return 'Your account is waiting for admin approval. You will be able to log in once your institution admin approves it.';
    case 'rejected':
      return 'Your account registration was rejected. Please contact your institution admin.';
    default:
      return null; // 'approved' or legacy rows
  }
}

/**
 * POST /api/auth/login
 * body: { username, password, institution, userType }
 * Guest logins omit password.
 */
router.post('/login', loginLimiter, async (req, res, next) => {
  try {
    const { username, password, userType } = req.body || {};

    if (!username || !req.body.institution || !userType) {
      return res
        .status(400)
        .json({ error: 'username, institution and userType are required' });
    }
    if (!VALID_USER_TYPES.includes(String(userType).toLowerCase())) {
      return res.status(400).json({ error: 'Invalid userType' });
    }

    const type = String(userType).toLowerCase();
    const institution = normInst(req.body.institution);

    // Guests authenticate with username + institution only.
    if (type === 'guest') {
      const guestName = String(username).trim();

      // A guest name must never impersonate a registered account.
      const adminRow = await pool.query(
        'SELECT user_type FROM users WHERE user_id = $1',
        [guestName]
      );
      if (adminRow.rows.length > 0 && adminRow.rows[0].user_type !== 'guest') {
        return res.status(409).json({
          error:
            'This username is already registered. Please login with the correct role or choose a different username.',
        });
      }
      const teacherRow = await pool.query(
        'SELECT 1 FROM teachers WHERE username = $1 OR id = $1',
        [guestName]
      );
      if (teacherRow.rows.length > 0) {
        return res.status(409).json({
          error:
            'This username belongs to a registered teacher. Please use the Teacher login.',
        });
      }
      const studentRow = await pool.query(
        'SELECT 1 FROM students WHERE username = $1 OR id = $1',
        [guestName]
      );
      if (studentRow.rows.length > 0) {
        return res.status(409).json({
          error:
            'This username belongs to a registered student. Please use the Student login.',
        });
      }

      const { rows } = await pool.query(
        `INSERT INTO users (user_id, institution, user_type, email, password_hash)
         VALUES ($1, $2, 'guest', NULL, NULL)
         ON CONFLICT (user_id) DO UPDATE SET institution = EXCLUDED.institution
         WHERE users.user_type = 'guest'
         RETURNING user_id, user_type, institution, email`,
        [guestName, institution]
      );
      if (rows.length === 0) {
        return res.status(409).json({
          error:
            'This username is already registered. Please choose a different username.',
        });
      }
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

    const usernameTrim = String(username).trim();

    // Admins live in the users table.
    if (type === 'admin') {
      const { rows } = await pool.query(
        'SELECT * FROM users WHERE user_id = $1 AND institution = $2',
        [usernameTrim, institution]
      );
      if (rows.length === 0) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
      const user = rows[0];
      const ok = await bcrypt.compare(password, user.password_hash || '');
      if (!ok) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }
      const authError = statusError(user.status);
      if (authError) return res.status(403).json({ error: authError });
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

    // Teachers & students live in their own tables (created via the
    // management screens). Their id column acts as the login id.
    const table = type === 'teacher' ? 'teachers' : 'students';
    const { rows } = await pool.query(
      `SELECT * FROM ${table} WHERE (username = $1 OR id = $1) AND institution = $2`,
      [usernameTrim, institution]
    );
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const person = rows[0];
    if (!person.password_hash) {
      return res
        .status(401)
        .json({ error: 'No password set for this account. Contact your admin.' });
    }
    const ok = await bcrypt.compare(password, person.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    const personAuthError = statusError(person.status);
    if (personAuthError) return res.status(403).json({ error: personAuthError });

    // Use the row id (STD.../TCH...) as the login identity so attendance
    // and other id-keyed features match; username rides along for display.
    const user = {
      user_id: person.id,
      user_type: type,
      institution: person.institution,
      email: person.email,
    };
    res.json({
      status: 'success',
      token: signToken(user),
      user: {
        user_id: user.user_id,
        username: person.username || person.id,
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

    const inst = normInst(institution);
    const hash = await bcrypt.hash(String(password), 10);

    // ---- Admin signup ----
    // The FIRST admin of an institution registers openly (they claim the
    // institution). Any admin after that goes to the approval queue of the
    // existing admins.
    if (type === 'admin') {
      const existing = await pool.query(
        `SELECT count(*)::int AS n FROM users
         WHERE institution = $1 AND user_type = 'admin' AND status = 'approved'`,
        [inst]
      );
      const isFirstAdmin = existing.rows[0].n === 0;

      const { rows } = await pool.query(
        `INSERT INTO users (user_id, institution, user_type, email, password_hash, status)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING user_id, user_type, institution, email, status`,
        [String(user_id).trim(), inst, type, String(email).trim(), hash,
         isFirstAdmin ? 'approved' : 'pending']
      );
      const user = rows[0];

      if (!isFirstAdmin) {
        return res.status(202).json({
          success: true,
          pending: true,
          message:
            'Registration received. Your account is waiting for approval by your institution admin.',
          user_id: user.user_id,
          user_type: user.user_type,
          institution: user.institution,
          email: user.email,
        });
      }

      return res.status(201).json({
        success: true,
        token: signToken(user),
        user_id: user.user_id,
        user_type: user.user_type,
        institution: user.institution,
        email: user.email,
      });
    }

    const table = type === 'teacher' ? 'teachers' : 'students';
    const id = `${type === 'teacher' ? 'TCH' : 'STD'}${Date.now()}`;
    const nameCol = String(user_id).trim();

    const person =
      type === 'teacher'
        ? await pool.query(
            `INSERT INTO teachers (id, institution, name, username, password_hash, email, status)
             VALUES ($1,$2,$3,$3,$4,$5,'pending')
             RETURNING id, username, institution, email, status`,
            [id, inst, nameCol, hash, String(email).trim()]
          )
        : await pool.query(
            `INSERT INTO students (id, institution, name, username, password_hash, email, fingerprint_enrolled, status)
             VALUES ($1,$2,$3,$3,$4,$5,'NO','pending')
             RETURNING id, username, institution, email, status`,
            [id, inst, nameCol, hash, String(email).trim()]
          );

    const row = person.rows[0];
    res.status(202).json({
      success: true,
      pending: true,
      message:
        'Registration received. Your account is waiting for approval by your institution admin.',
      user_id: row.id,
      username: row.username || row.id,
      user_type: type,
      institution: row.institution,
      email: row.email,
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
