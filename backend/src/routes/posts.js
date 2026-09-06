const express = require('express');
const crypto = require('crypto');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');
const config = require('../config');

const router = express.Router();
router.use(requireAuth, withInstitution);

/**
 * GET /api/posts — newest first, with signed-ish media URL
 * media is served through /api/posts/media/:id
 */
router.get('/', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT p.id, p.user_id, p.content, p.media_id, p.likes_count, p.created_at,
              COALESCE(u.user_id, s.username, t.username, p.user_id) AS username
       FROM posts p
       LEFT JOIN users u ON u.user_id = p.user_id
       LEFT JOIN students s ON s.id = p.user_id
       LEFT JOIN teachers t ON t.id = p.user_id
       WHERE p.institution = $1
       ORDER BY p.created_at DESC
       LIMIT 100`,
      [req.auth.institution]
    );
    const data = rows.map((r) => ({
      id: r.id,
      user_id: r.user_id,
      username: r.username,
      content: r.content,
      media_url: r.media_id ? `/api/posts/media/${r.media_id}` : null,
      likes_count: r.likes_count,
      created_at: r.created_at,
    }));
    res.json({ status: 'success', data });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/posts — JSON body { content, media_base64?, media_name? }
 */
router.post('/', async (req, res, next) => {
  try {
    const { content, media_base64, media_name } = req.body || {};
    if ((!content || !String(content).trim()) && !media_base64) {
      return res.status(400).json({ message: 'Content or media is required' });
    }

    let mediaId = null;
    if (media_base64) {
      const buf = Buffer.from(String(media_base64), 'base64');
      if (buf.length === 0) {
        return res.status(400).json({ message: 'Invalid media data' });
      }
      if (buf.length > config.maxMediaBytes) {
        return res.status(413).json({ message: 'Media too large (max 5 MB)' });
      }
      mediaId = crypto.randomUUID();
      await pool.query(
        'INSERT INTO media (id, institution, file_name, data, mime_type) VALUES ($1,$2,$3,$4,$5)',
        [mediaId, req.auth.institution, media_name || 'upload', buf,
         req.body.media_type || 'application/octet-stream']
      );
    }

    const { rows } = await pool.query(
      `INSERT INTO posts (institution, user_id, content, media_id)
       VALUES ($1,$2,$3,$4) RETURNING id, user_id, content, media_id, likes_count, created_at`,
      [req.auth.institution, req.auth.userId, String(content || ''), mediaId]
    );

    res.status(201).json({ success: true, data: rows[0] });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/posts/:id/like
 */
router.post('/:id/like', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `UPDATE posts SET likes_count = likes_count + 1
       WHERE id = $1 AND institution = $2
       RETURNING likes_count`,
      [req.params.id, req.auth.institution]
    );
    if (rows.length === 0) return res.status(404).json({ message: 'Post not found' });
    res.json({ success: true, likes_count: rows[0].likes_count });
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/posts/media/:id — stream stored media
 */
router.get('/media/:id', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      'SELECT data, mime_type FROM media WHERE id = $1',
      [req.params.id]
    );
    if (rows.length === 0) return res.status(404).json({ message: 'Media not found' });
    res.set('Content-Type', rows[0].mime_type || 'application/octet-stream');
    res.set('Cache-Control', 'public, max-age=86400');
    res.send(rows[0].data);
  } catch (e) {
    next(e);
  }
});

module.exports = router;
