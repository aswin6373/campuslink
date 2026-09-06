const express = require('express');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth, withInstitution);

/**
 * GET /api/attendance?date=YYYY-MM-DD[&student_id=STD123]
 * Returns { records: [...], summary: { total, present:{count}, late:{count}, absent:{count} } }
 */
router.get('/', async (req, res, next) => {
  try {
    const date = req.query.date || new Date().toISOString().slice(0, 10);
    const params = [req.auth.institution, date];
    let where = 'institution = $1 AND date = $2';

    if (req.query.student_id) {
      params.push(String(req.query.student_id));
      where += ` AND student_id = $${params.length}`;
    } else if (req.auth.userType === 'student') {
      // Students can only see their own records
      params.push(req.auth.userId);
      where += ` AND student_id = $${params.length}`;
    }

    const { rows } = await pool.query(
      `SELECT student_id, username, status, timestamp, date
       FROM attendance WHERE ${where} ORDER BY timestamp`,
      params
    );

    const counts = { present: 0, late: 0, absent: 0 };
    for (const r of rows) {
      if (counts[r.status] !== undefined) counts[r.status]++;
    }
    const total = counts.present + counts.late + counts.absent;

    res.json({
      records: rows,
      summary: {
        total,
        present: { count: counts.present },
        late: { count: counts.late },
        absent: { count: counts.absent },
      },
    });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
