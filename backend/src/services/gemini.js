const config = require('../config');

/**
 * Calls Google Gemini to answer a question grounded on the institution's
 * curated Q&A context. Throws on failure; returns the response text.
 */
async function askGemini({ prompt, institution, formattedAnswers }) {
  if (!config.geminiApiKey) {
    throw new Error('GEMINI_API_KEY is not configured on the server');
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${config.geminiApiKey}`;

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

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw new Error(`Gemini API error (${res.status}): ${detail.slice(0, 200)}`);
  }

  const data = await res.json();
  const text =
    data?.candidates?.[0]?.content?.parts?.[0]?.text ||
    "I apologize, but I couldn't find specific information about your query.";

  return text
    .replace(/\*\*(.*?)\*\*/g, '`$1`')
    .replace(/^\* /gm, '• ')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}

module.exports = { askGemini };
