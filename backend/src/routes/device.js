const express = require('express');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');
const config = require('../config');

const router = express.Router();

/** Device is "connected" if it heartbeat within this window. */
function offlineCutoff() {
  return `now() - interval '${config.deviceOfflineAfterMinutes} minutes'`;
}

/** NodeMCU calls authenticate with a shared key header (no JWT). */
function requireDeviceKey(req, res, next) {
  if (req.headers['x-device-key'] !== config.deviceApiKey) {
    return res.status(401).json({ error: 'Invalid device key' });
  }
  next();
}

async function getDevice(deviceId = 'default') {
  const { rows } = await pool.query('SELECT * FROM devices WHERE device_id = $1', [deviceId]);
  return rows[0] || null;
}

async function isDeviceOnline(deviceId = 'default') {
  const device = await getDevice(deviceId);
  if (!device || !device.last_seen) return false;
  const ageMs = Date.now() - new Date(device.last_seen).getTime();
  return ageMs < config.deviceOfflineAfterMinutes * 60 * 1000;
}

/* ==========================================================================
 * Device-side endpoints (called by the NodeMCU over the internet)
 * ========================================================================== */

/**
 * POST /api/device/heartbeat
 * body: { device_id?, device_name?, ip? }
 * Called by the NodeMCU every ~30-60 seconds.
 */
router.post('/heartbeat', requireDeviceKey, async (req, res, next) => {
  try {
    const deviceId = String((req.body && req.body.device_id) || 'default');
    const deviceName = String((req.body && req.body.device_name) || 'fingerprint-scanner');
    const ip = String((req.body && req.body.ip) || '');

    await pool.query(
      `INSERT INTO devices (device_id, device_name, last_ip, last_seen)
       VALUES ($1,$2,$3, now())
       ON CONFLICT (device_id) DO UPDATE SET
         device_name = EXCLUDED.device_name,
         last_ip = EXCLUDED.last_ip,
         last_seen = now()`,
      [deviceId, deviceName, ip]
    );
    res.json({ success: true, online: true });
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/device/commands/next?device_id=default
 * NodeMCU polls this every few seconds while it is powered & online.
 * Atomically claims the next pending command.
 */
router.get('/commands/next', requireDeviceKey, async (req, res, next) => {
  try {
    const deviceId = String(req.query.device_id || 'default');
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const { rows } = await client.query(
        `UPDATE device_commands
         SET status = 'sent', sent_at = now()
         WHERE id = (
           SELECT id FROM device_commands
           WHERE device_id = $1 AND status = 'pending'
           ORDER BY created_at LIMIT 1
           FOR UPDATE SKIP LOCKED
         )
         RETURNING id, command, student_id`,
        [deviceId]
      );
      await client.query('COMMIT');
      if (rows.length === 0) {
        return res.json({ has_command: false });
      }
      res.json({
        has_command: true,
        id: rows[0].id,
        command: rows[0].command,
        student_id: rows[0].student_id,
      });
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/device/commands/:id/result
 * body: { status: 'success'|'place_finger'|'remove_finger'|'place_finger_again'|'failed', message? }
 * NodeMCU reports progress; 'success'/'failed' terminate the command.
 */
router.post('/commands/:id/result', requireDeviceKey, async (req, res, next) => {
  try {
    const { status, message } = req.body || {};
    const terminal = status === 'success' || status === 'failed';
    const { rows } = await pool.query(
      `UPDATE device_commands
       SET status = CASE WHEN $2 THEN 'done' ELSE 'in_progress' END,
           result = $3, result_at = now()
       WHERE id = $1
       RETURNING command, student_id`,
      [req.params.id, terminal, JSON.stringify({ status: status || 'unknown', message: message || '' })]
    );

    // On successful enrollment, flag the student as enrolled.
    if (status === 'success' && rows.length > 0 && rows[0].command === 'enroll') {
      await pool.query(
        `UPDATE students SET fingerprint_enrolled = 'YES' WHERE id = $1`,
        [rows[0].student_id]
      );
    }

    res.json({ success: true });
  } catch (e) {
    next(e);
  }
});

/* ==========================================================================
 * App-side endpoints (called by the Flutter app)
 * ========================================================================== */

/**
 * GET /api/device/status — is the fingerprint scanner connected right now?
 */
router.get('/status', requireAuth, async (req, res, next) => {
  try {
    const online = await isDeviceOnline('default');
    const device = await getDevice('default');
    res.json({
      connected: online,
      device_name: device ? device.device_name : null,
      last_seen: device ? device.last_seen : null,
      offline_after_minutes: config.deviceOfflineAfterMinutes,
    });
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/device/enroll
 * body: { student_id }
 * Queues an enrollment command — ONLY succeeds while the device is online.
 * Returns 409 { connected: false } when the scanner is not connected.
 */
router.post('/enroll', requireAuth, withInstitution, async (req, res, next) => {
  try {
    const { student_id } = req.body || {};
    if (!student_id) {
      return res.status(400).json({ error: 'student_id is required' });
    }
    // Verify the student belongs to the caller's institution
    const student = await pool.query(
      'SELECT id FROM students WHERE id = $1 AND institution = $2',
      [String(student_id), req.auth.institution]
    );
    if (student.rowCount === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }

    if (!(await isDeviceOnline('default'))) {
      return res.status(409).json({
        connected: false,
        error: 'Fingerprint device not connected. Power it on and make sure it is connected to the internet.',
      });
    }

    const { rows } = await pool.query(
      `INSERT INTO device_commands (device_id, command, student_id, status)
       VALUES ('default', 'enroll', $1, 'pending')
       RETURNING id, created_at`,
      [String(student_id)]
    );

    // Mark the student as enrollment in progress
    await pool.query(
      `UPDATE students SET fingerprint_enrolled = 'PENDING' WHERE id = $1 AND institution = $2`,
      [String(student_id), req.auth.institution]
    );

    res.status(202).json({ success: true, command_id: rows[0].id });
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/device/enrollment-status?command_id=<id>
 * App polls this while the enrollment dialog is open.
 */
router.get('/enrollment-status', requireAuth, async (req, res, next) => {
  try {
    const { command_id } = req.query;
    if (!command_id) {
      return res.status(400).json({ error: 'command_id is required' });
    }
    const { rows } = await pool.query(
      'SELECT status, result, result_at FROM device_commands WHERE id = $1',
      [String(command_id)]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Command not found' });
    }
    const cmd = rows[0];
    const result = cmd.result ? cmd.result : {};
    res.json({
      status: result.status || (cmd.status === 'pending' ? 'waiting_device' : 'unknown'),
      done: cmd.status === 'done',
      message: result.message || '',
    });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
