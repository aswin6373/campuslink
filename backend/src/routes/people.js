const express = require('express');
const bcrypt = require('bcryptjs');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');

const router = express.Router();

// NOTE: this router is mounted at /api, so middleware is applied per-route
// (a router.use() here would intercept every /api/* request).


const STUDENT_FIELDS = 'id, name, username, grade, section, contact, email, fingerprint_enrolled, status';
const TEACHER_FIELDS = 'id, name, username, subject, qualification, experience, contact, email, status';

/* ---------------- Students ---------------- */

router.get('/students', requireAuth, withInstitution, async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT ${STUDENT_FIELDS} FROM students WHERE institution = $1 ORDER BY name`,
      [req.auth.institution]
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

router.post('/students', requireAuth, withInstitution, async (req, res, next) => {
  try {
    if (req.auth.userType !== 'admin' && req.auth.userType !== 'teacher') {
      return res.status(403).json({ error: 'Not allowed' });
    }
    const { id, name, username, password, grade, section, contact, email, fingerprintEnrolled } =
      req.body || {};
    if (!name || !username) {
      return res.status(400).json({ error: 'name and username are required' });
    }
    const hash = password ? await bcrypt.hash(String(password), 10) : null;
    const studentId = id || `STD${Date.now()}`;

    const { rows } = await pool.query(
      `INSERT INTO students (id, institution, name, username, password_hash, grade, section, contact, email, fingerprint_enrolled, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'approved')
       ON CONFLICT (id) DO UPDATE SET
         name=EXCLUDED.name, username=EXCLUDED.username, password_hash=COALESCE(EXCLUDED.password_hash, students.password_hash),
         grade=EXCLUDED.grade, section=EXCLUDED.section, contact=EXCLUDED.contact, email=EXCLUDED.email,
         fingerprint_enrolled=EXCLUDED.fingerprint_enrolled
       RETURNING ${STUDENT_FIELDS}`,
      [studentId, req.auth.institution, name, username, hash, grade, section, contact, email,
       fingerprintEnrolled || 'NO']
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.put('/students/:id', requireAuth, withInstitution, async (req, res, next) => {
  try {
    const { name, username, password, grade, section, contact, email, fingerprintEnrolled } =
      req.body || {};
    const hash = password ? await bcrypt.hash(String(password), 10) : null;
    const { rows } = await pool.query(
      `UPDATE students SET
         name = COALESCE($3, name),
         username = COALESCE($4, username),
         password_hash = COALESCE($5, password_hash),
         grade = COALESCE($6, grade),
         section = COALESCE($7, section),
         contact = COALESCE($8, contact),
         email = COALESCE($9, email),
         fingerprint_enrolled = COALESCE($10, fingerprint_enrolled)
       WHERE id = $1 AND institution = $2
       RETURNING ${STUDENT_FIELDS}`,
      [req.params.id, req.auth.institution, name, username, hash, grade, section, contact, email,
       fingerprintEnrolled]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Student not found' });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.delete('/students/:id', requireAuth, withInstitution, async (req, res, next) => {
  try {
    if (req.auth.userType !== 'admin') {
      return res.status(403).json({ error: 'Only admins can delete students' });
    }
    const { rowCount } = await pool.query(
      'DELETE FROM students WHERE id = $1 AND institution = $2',
      [req.params.id, req.auth.institution]
    );
    if (rowCount === 0) return res.status(404).json({ error: 'Student not found' });
    res.json({ success: true });
  } catch (e) {
    next(e);
  }
});

/* ---------------- Teachers ---------------- */

router.get('/teachers', requireAuth, withInstitution, async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT ${TEACHER_FIELDS} FROM teachers WHERE institution = $1 ORDER BY name`,
      [req.auth.institution]
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

router.post('/teachers', requireAuth, withInstitution, async (req, res, next) => {
  try {
    if (req.auth.userType !== 'admin') {
      return res.status(403).json({ error: 'Only admins can add teachers' });
    }
    const { id, name, username, password, subject, qualification, experience, contact, email } =
      req.body || {};
    if (!name || !username) {
      return res.status(400).json({ error: 'name and username are required' });
    }
    const hash = password ? await bcrypt.hash(String(password), 10) : null;
    const teacherId = id || `TCH${Date.now()}`;

    const { rows } = await pool.query(
      `INSERT INTO teachers (id, institution, name, username, password_hash, subject, qualification, experience, contact, email, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'approved')
       ON CONFLICT (id) DO UPDATE SET
         name=EXCLUDED.name, username=EXCLUDED.username, password_hash=COALESCE(EXCLUDED.password_hash, teachers.password_hash),
         subject=EXCLUDED.subject, qualification=EXCLUDED.qualification, experience=EXCLUDED.experience,
         contact=EXCLUDED.contact, email=EXCLUDED.email
       RETURNING ${TEACHER_FIELDS}`,
      [teacherId, req.auth.institution, name, username, hash, subject, qualification, experience, contact, email]
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.put('/teachers/:id', requireAuth, withInstitution, async (req, res, next) => {
  try {
    const { name, username, password, subject, qualification, experience, contact, email } =
      req.body || {};
    const hash = password ? await bcrypt.hash(String(password), 10) : null;
    const { rows } = await pool.query(
      `UPDATE teachers SET
         name = COALESCE($3, name),
         username = COALESCE($4, username),
         password_hash = COALESCE($5, password_hash),
         subject = COALESCE($6, subject),
         qualification = COALESCE($7, qualification),
         experience = COALESCE($8, experience),
         contact = COALESCE($9, contact),
         email = COALESCE($10, email)
       WHERE id = $1 AND institution = $2
       RETURNING ${TEACHER_FIELDS}`,
      [req.params.id, req.auth.institution, name, username, hash, subject, qualification, experience, contact, email]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Teacher not found' });
    res.json(rows[0]);
  } catch (e) {
    next(e);
  }
});

router.delete('/teachers/:id', requireAuth, withInstitution, async (req, res, next) => {
  try {
    if (req.auth.userType !== 'admin') {
      return res.status(403).json({ error: 'Only admins can delete teachers' });
    }
    const { rowCount } = await pool.query(
      'DELETE FROM teachers WHERE id = $1 AND institution = $2',
      [req.params.id, req.auth.institution]
    );
    if (rowCount === 0) return res.status(404).json({ error: 'Teacher not found' });
    res.json({ success: true });
  } catch (e) {
    next(e);
  }
});

/* ---------------- Counts (dashboard) ---------------- */

router.get('/counts', requireAuth, withInstitution, async (req, res, next) => {
  try {
    const students = await pool.query(
      'SELECT count(*)::int AS total FROM students WHERE institution = $1',
      [req.auth.institution]
    );
    const teachers = await pool.query(
      'SELECT count(*)::int AS total FROM teachers WHERE institution = $1',
      [req.auth.institution]
    );
    res.json({
      total_students: students.rows[0].total,
      total_teachers: teachers.rows[0].total,
    });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
