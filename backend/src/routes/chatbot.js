const express = require('express');
const pool = require('../db');
const { requireAuth, withInstitution } = require('../middleware/auth');
const { askGemini } = require('../services/gemini');

const router = express.Router();
router.use(requireAuth, withInstitution);

/**
 * POST /api/chatbot/ask — ask the AI assistant a question.
 * The institution's curated answers are used as grounding context.
 * body: { prompt }
 */
router.post('/ask', async (req, res, next) => {
  try {
    const prompt = String((req.body && req.body.prompt) || '').trim();
    if (!prompt) {
      return res.status(400).json({ error: 'prompt is required' });
    }

    // Fetch the institution's curated Q&A as grounding context
    const { rows } = await pool.query(
      `SELECT q.category, a.answer
       FROM chatbot_answers a
       JOIN chatbot_questions q ON q.id = a.question_id
       WHERE a.institution = $1 AND a.active = true`,
      [req.auth.institution]
    );
    const formattedAnswers = rows
      .map((r) => `Category: ${r.category}\nAnswer: ${r.answer}`)
      .join('\n\n');

    try {
      const text = await askGemini({
        prompt,
        institution: req.auth.institution,
        formattedAnswers,
      });
      res.json({ answer: text });
    } catch (e) {
      console.error('Chatbot error:', e.message);
      res.status(502).json({ error: 'The AI assistant is unavailable right now. Please try again later.' });
    }
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/chatbot/questions — predefined question bank (admins manage this)
 */
router.get('/questions', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, category, question_text, keywords FROM chatbot_questions ORDER BY category'
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/chatbot/questions — add a predefined question (admin only)
 * body: { category, question_text, keywords: "a,b,c" }
 */
router.post('/questions', async (req, res, next) => {
  try {
    if (req.auth.userType !== 'admin') {
      return res.status(403).json({ error: 'Only admins can add questions' });
    }
    const { category, question_text, keywords } = req.body || {};
    if (!category || !question_text || !keywords) {
      return res
        .status(400)
        .json({ error: 'category, question_text and keywords are required' });
    }
    const { rows } = await pool.query(
      `INSERT INTO chatbot_questions (category, question_text, keywords)
       VALUES ($1,$2,$3) RETURNING id, category, question_text, keywords`,
      [String(category).trim(), String(question_text).trim(), String(keywords).trim()]
    );
    res.status(201).json({ success: true, data: rows[0] });
  } catch (e) {
    next(e);
  }
});

/**
 * GET /api/chatbot/answers?institution=X — active answers for the caller's institution
 */
router.get('/answers', async (req, res, next) => {
  try {
    const { rows } = await pool.query(
      `SELECT a.id, a.question_id, a.answer, a.active, q.category, q.question_text
       FROM chatbot_answers a
       JOIN chatbot_questions q ON q.id = a.question_id
       WHERE a.institution = $1 AND a.active = true
       ORDER BY q.category`,
      [req.auth.institution]
    );
    res.json(rows);
  } catch (e) {
    next(e);
  }
});

/**
 * POST /api/chatbot/answers — save/update an answer (admin only)
 * body: { id?, question_id, answer, active, institution }
 * If `id` is empty a new answer is created (upsert on question_id+institution otherwise).
 */
router.post('/save', async (req, res, next) => {
  try {
    if (req.auth.userType !== 'admin') {
      return res.status(403).json({ error: 'Only admins can save answers' });
    }
    const { id, question_id, answer, active } = req.body || {};
    if (!question_id || answer === undefined) {
      return res.status(400).json({ error: 'question_id and answer are required' });
    }

    const { rows } = await pool.query(
      `INSERT INTO chatbot_answers (institution, question_id, answer, active)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT (institution, question_id) DO UPDATE SET
         answer = EXCLUDED.answer, active = EXCLUDED.active
       RETURNING id, question_id, answer, active`,
      [
        req.auth.institution,
        String(question_id),
        String(answer),
        active === undefined ? true : Boolean(active),
      ]
    );
    res.status(201).json({ success: true, data: rows[0] });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
