const config = require('../config');

/**
 * Model fallback chain: the first model is the primary (user request);
 * the rest are tried in order when the primary is unavailable
 * (deprecated, rate-limited, or erroring).
 */
const DEFAULT_MODEL_CHAIN = [
  'gemini-3.5-flash-lite', // primary — user request
  'gemini-2.5-flash-lite',
  'gemini-2.5-flash',
  'gemini-2.0-flash', // known stable fallback
];

// Optional override via env: GEMINI_MODELS="model-a,model-b"
const modelChain = (config.geminiModels
  ? config.geminiModels.split(',').map((m) => m.trim()).filter(Boolean)
  : DEFAULT_MODEL_CHAIN);

/**
 * Calls Google Gemini to answer a question grounded on the institution's
 * curated Q&A context. Tries each model in the chain until one succeeds.
 * Throws on total failure; returns { text, model }.
 */
async function askGemini({ prompt, institution, formattedAnswers }) {
  if (!config.geminiApiKey) {
    throw new Error('GEMINI_API_KEY is not configured on the server');
  }

  const body = {
    contents: [
      {
        parts: [
          {
            text: `
You are Campus Master, an advanced AI assistant specializing in information about the college ${institution}.
Use the following context for the institution's answers and categories:

${formattedAnswers}

Instructions:
- Provide answers based on the relevant categories and answers from the provided context, focusing on the ${institution} information.
- Prioritize responses related to computer science, IT, BCA, and other academic programs, eligibility, faculty, placements, and related technical subjects.
- Answer questions specific to the ${institution}, including details about its academic offerings, infrastructure, faculty, and placement opportunities.
- For any other queries not specifically related to the ${institution} but still involving technical subjects like computer science and IT, use the general knowledge from the context while focusing on the ${institution} offerings and expertise.
- Ensure your response is clear, structured, and relevant to the user's query, emphasizing the ${institution} strengths and offerings.

User Query: "${prompt}"

Provide a clear and structured response based on the provided answers.`
          }
        ]
      }
    ]
  };

  const errors = [];

  for (const model of modelChain) {
    try {
      const text = await callModel(model, body);
      return { text, model };
    } catch (e) {
      errors.push(`${model}: ${e.message}`);
      console.warn(`Gemini model "${model}" failed (${e.message}), trying next...`);
    }
  }

  throw new Error(`All Gemini models failed. ${errors.join(' | ')}`);
}

async function callModel(model, body) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${config.geminiApiKey}`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw new Error(`HTTP ${res.status}: ${detail.slice(0, 150)}`);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!text) {
    throw new Error('Empty response');
  }

  return text
    .replace(/\*\*(.*?)\*\*/g, '`$1`')
    .replace(/^\* /gm, '• ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

module.exports = { askGemini, modelChain };
