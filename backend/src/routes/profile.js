const express = require('express');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');
const config = require('../config');

const router = express.Router();
router.use(requireAuth, withInstitution);

/**
 * GET /api/profile — caller's profile
 */
router.get('/', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT user_id, institution, user_type, email, avatar_media_id, created_at
       FROM users WHERE user_id = $1`,
      [req.auth.userId]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const u = rows[0];
    res.json({
      success: true,
      data: {
        user_id: u.user_id,
        institution: u.institution,
        user_type: u.user_type,
        email: u.email,
        profile_image: u.avatar_media_id ? `/api/profile/avatar/${u.avatar_media_id}` : '',
      },
    });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/profile — update profile (multipart/form-data or JSON)
 * fields: email?, institution?, password?, avatar? (file)
 */
router.post('/', async (req, res, next) => {
  try {
    const { email, institution, password, avatar_base64, avatar_name, avatar_type } =
      req.body || {};

    let avatarMediaId;
    if (avatar_base64) {
      const buf = Buffer.from(String(avatar_base64), 'base64');
      if (buf.length > config.maxMediaBytes) {
        return res.status(413).json({ error: 'Avatar too large (max 5 MB)' });
      }
      avatarMediaId = crypto.randomUUID();
      await pool.query(
        'INSERT INTO media (id, institution, file_name, data, mime_type) VALUES ($1,$2,$3,$4,$5)',
        [avatarMediaId, req.auth.institution, avatar_name || 'avatar', buf, avatar_type || 'image/jpeg']
      );
    }

    let passwordHash;
    if (password) {
      if (String(password).length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters' });
      }
      passwordHash = await bcrypt.hash(String(password), 10);
    }

    const { rows } = await pool.query(
      `UPDATE users SET
         email = COALESCE($2, email),
         institution = COALESCE($3, institution),
         password_hash = COALESCE($4, password_hash),
         avatar_media_id = COALESCE($5, avatar_media_id)
       WHERE user_id = $1
       RETURNING user_id, institution, user_type, email, avatar_media_id`,
      [req.auth.userId, email || null, institution || null, passwordHash || null, avatarMediaId || null]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'User not found' });

    res.json({ success: true, data: rows[0] });
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/profile/avatar/:id — stream avatar image
 */
router.get('/avatar/:id', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      'SELECT data, mime_type FROM media WHERE id = $1',
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Not found' });
    res.set('Content-Type', rows[0].mime_type || 'image/jpeg');
    res.set('Cache-Control', 'public, max-age=86400');
    res.send(rows[0].data);
  } catch (e) {
    next(e);
  }
});

module.exports = router;
