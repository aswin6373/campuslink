const jwt = require('jsonwebtoken');
const config = require('../config');
const pool = require('../db');

/**
 * Verifies the Authorization: Bearer <token> header and attaches req.auth =
 * { userId, userType, institution }.
 */
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Missing authorization token' });
  }
  try {
    req.auth = jwt.verify(token, config.jwtSecret);
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

/**
 * Loads the caller's institution from the DB (source of truth) when the JWT
 * carries only the user id. Falls back to the claim.
 * Students/teachers live in their own tables, so we check those too.
 */
async function withInstitution(req, res, next) {
  try {
    const { userId, userType } = req.auth;

    if (userType === 'student' || userType === 'teacher') {
      const table = userType === 'teacher' ? 'teachers' : 'students';
      const { rows } = await pool.query(
        `SELECT institution FROM ${table} WHERE id = $1`,
        [userId]
      );
      if (rows.length === 0) {
        return res.status(401).json({ error: 'Account no longer exists' });
      }
      req.auth.institution = rows[0].institution;
      return next();
    }

    const { rows } = await pool.query(
      'SELECT institution FROM users WHERE user_id = $1',
      [userId]
    );
    if (rows.length === 0) {
      return res.status(401).json({ error: 'User no longer exists' });
    }
    req.auth.institution = rows[0].institution;
    next();
  } catch (e) {
    next(e);
  }
}

module.exports = { requireAuth, withInstitution };
