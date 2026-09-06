const express = require('express');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth, withInstitution);

/**
 * GET /api/chatroom — last 200 messages, oldest first
 */
router.get('/', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT m.id, m.sender, m.text, m.created_at AS timestamp,
              COALESCE(s.username, t.username, u.user_id, m.sender) AS username
       FROM (
         SELECT id, sender, text, created_at
         FROM chat_messages WHERE institution = $1
         ORDER BY created_at DESC LIMIT 200
       ) m
       LEFT JOIN students s ON s.id = m.sender
       LEFT JOIN teachers t ON t.id = m.sender
       LEFT JOIN users u ON u.user_id = m.sender
       ORDER BY m.created_at`,
      [req.auth.institution]
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/chatroom — body { text }
 */
router.post('/', async (req, res, next) => {
  try {
    const text = String((req.body && req.body.text) || '').trim();
    if (!text) return res.status(400).json({ error: 'text is required' });
    if (text.length > 2000) return res.status(400).json({ error: 'Message too long' });

    const { rows } = await pool.query(
      `INSERT INTO chat_messages (institution, sender, text)
       VALUES ($1,$2,$3)
       RETURNING id, sender, text, created_at AS timestamp`,
      [req.auth.institution, req.auth.userId, text]
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    next(e);
  }
});

module.exports = router;
