const express = require('express');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');

const router = express.Router();
router.use(requireAuth, withInstitution);

function parseEvent(body) {
  const { title, event_date, description, location, location_detail, schedule, coordinators } =
    body || {};
  if (!title || !event_date) {
    return null;
  }
  return [
    String(title),
    new Date(event_date),
    description ? String(description) : '',
    location ? String(location) : '',
    location_detail ? String(location_detail) : '',
    JSON.stringify(Array.isArray(schedule) ? schedule : []),
    JSON.stringify(Array.isArray(coordinators) ? coordinators : []),
  ];
}

/**
 * GET /api/events?institution=X — list, sorted by date
 */
router.get('/', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, title, event_date, description, location, location_detail,
              schedule, coordinators, institution
       FROM events WHERE institution = $1 ORDER BY event_date`,
      [req.auth.institution]
    );
    res.json({ status: 'success', data: rows });
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/events/upcoming — next event on/after now
 */
router.get('/upcoming', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, title, event_date, description, location, location_detail,
              schedule, coordinators, institution
       FROM events
       WHERE institution = $1 AND event_date >= now()
       ORDER BY event_date LIMIT 1`,
      [req.auth.institution]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'No upcoming events' });
    }
    res.json({ success: true, data: rows[0] });
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/events/detail/:id — full details incl. schedule/coordinators
 */
router.get('/detail/:id', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT id, title, event_date, description, location, location_detail,
              schedule, coordinators, institution
       FROM events WHERE id::text = $1 AND institution = $2`,
      [req.params.id, req.auth.institution]
    );
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Event not found' });
    }
    const ev = rows[0];
    res.json({
      success: true,
      data: {
        event: ev,
        schedules: ev.schedule || [],
        coordinators: ev.coordinators || [],
      },
    });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/events — create
 */
router.post('/', async (req, res, next) => {
  try {
    const values = parseEvent(req.body);
    if (!values) {
      return res.status(400).json({ message: 'title and event_date are required' });
    }
    const { rows } = await pool.query(
      `INSERT INTO events (institution, title, event_date, description, location, location_detail, schedule, coordinators)
       VALUES ($1,$2,$3,$4,$5,$6,$7::jsonb,$8::jsonb)
       RETURNING *`,
      [req.auth.institution, ...values]
    );
    res.status(201).json({ success: true, data: rows[0] });
  } catch (e) {
    next(e);
  }
});

/**
 * PUT /api/events/:id — update
 */
router.put('/:id', async (req, res, next) => {
  try {
    const values = parseEvent(req.body);
    if (!values) {
      return res.status(400).json({ message: 'title and event_date are required' });
    }
    const { rows } = await pool.query(
      `UPDATE events SET title=$3, event_date=$4, description=$5, location=$6,
              location_detail=$7, schedule=$8::jsonb, coordinators=$9::jsonb
       WHERE id::text = $1 AND institution = $2
       RETURNING *`,
      [req.params.id, req.auth.institution, ...values]
    );
    if (rows.length === 0) {
      return res.status(404).json({ message: 'Event not found' });
    }
    res.json({ success: true, data: rows[0] });
  } catch (e) {
    next(e);
  }
});

/**
 * DELETE /api/events/:id — delete
 */
router.delete('/:id', async (req, res, next) => {
  try {
    const { rowCount } = await pool.query(
      'DELETE FROM events WHERE id::text = $1 AND institution = $2',
      [req.params.id, req.auth.institution]
    );
    if (rowCount === 0) {
      return res.status(404).json({ message: 'Event not found' });
    }
    res.json({ status: 'success' });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
