const express = require('express');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');

const router = express.Router();

// Only admins manage approvals.
router.use(requireAuth, withInstitution);
router.use((req, res, next) => {
  if (req.auth.userType !== 'admin') {
    return res.status(403).json({ error: 'Only admins can manage approvals' });
  }
  next();
});

/**
 * GET /api/approvals — all pending accounts for the admin's institution
 */
router.get('/', async (req, res, next) => {
  try {
    const users = await pool.query(
      `SELECT user_id AS id, user_id AS name, email, 'admin' AS role, created_at
       FROM users WHERE institution = $1 AND status = 'pending'
       ORDER BY created_at`,
      [req.auth.institution]
    );
    const teachers = await pool.query(
      `SELECT id, COALESCE(username, id) AS name, email, 'teacher' AS role, created_at
       FROM teachers WHERE institution = $1 AND status = 'pending'
       ORDER BY created_at`,
      [req.auth.institution]
    );
    const students = await pool.query(
      `SELECT id, COALESCE(username, id) AS name, email, 'student' AS role, created_at
       FROM students WHERE institution = $1 AND status = 'pending'
       ORDER BY created_at`,
      [req.auth.institution]
    );

    const pending = [
      ...users.rows.map((r) => ({ ...r, id: `u:${r.id}`, raw_id: r.id, table: 'users' })),
      ...teachers.rows.map((r) => ({ ...r, id: `t:${r.id}`, raw_id: r.id, table: 'teachers' })),
      ...students.rows.map((r) => ({ ...r, id: `s:${r.id}`, raw_id: r.id, table: 'students' })),
    ];
    res.json({ status: 'success', data: pending });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/approvals/:table/:id/approve
 * table: users | teachers | students
 */
router.post('/:table/:id/approve', async (req, res, next) => {
  try {
    const { table, id } = req.params;
    if (!['users', 'teachers', 'students'].includes(table)) {
      return res.status(400).json({ error: 'Invalid account type' });
    }
    // For users the institution key column is user_id; else id.
    const keyCol = table === 'users' ? 'user_id' : 'id';
    const { rowCount } = await pool.query(
      `UPDATE ${table} SET status = 'approved'
       WHERE ${keyCol} = $1 AND institution = $2 AND status = 'pending'`,
      [id, req.auth.institution]
    );
    if (rowCount === 0) {
      return res.status(404).json({ error: 'Pending account not found' });
    }
    res.json({ success: true });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/approvals/:table/:id/reject — marks rejected (stays in DB for audit)
 */
router.post('/:table/:id/reject', async (req, res, next) => {
  try {
    const { table, id } = req.params;
    if (!['users', 'teachers', 'students'].includes(table)) {
      return res.status(400).json({ error: 'Invalid account type' });
    }
    const keyCol = table === 'users' ? 'user_id' : 'id';
    const { rowCount } = await pool.query(
      `UPDATE ${table} SET status = 'rejected'
       WHERE ${keyCol} = $1 AND institution = $2 AND status = 'pending'`,
      [id, req.auth.institution]
    );
    if (rowCount === 0) {
      return res.status(404).json({ error: 'Pending account not found' });
    }
    res.json({ success: true });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
