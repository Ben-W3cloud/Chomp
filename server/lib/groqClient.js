/// Groq AI client for documentation and test evaluation.
///
/// Sends repository README and file tree to Groq's API for analysis.
/// Returns documentation quality and test coverage ratings.
///
/// Groq is used for these evaluations because it's faster and cheaper
/// than NVIDIA for simpler text analysis tasks.

import { parseJsonSafely } from './safeJson.js';

/// System prompt that instructs the AI to evaluate docs and tests.
const SYSTEM_PROMPT = `You are evaluating a code repository's documentation quality and test coverage. Respond with ONLY valid JSON, no markdown fences, no prose, matching exactly:
{
  "docs_rating": "Excellent" | "Great" | "Good" | "Standard" | "Poor" | "Critical",
  "docs_reasoning": <string, one sentence>,
  "tests_rating": "Excellent" | "Great" | "Good" | "Standard" | "Poor" | "Critical",
  "tests_reasoning": <string, one sentence>
}`;

/// Evaluates a repository's documentation and test coverage using Groq AI.
///
/// @param {Object} params - Evaluation parameters
/// @param {string} params.fullName - Repository full name (owner/repo)
/// @param {string} params.readme - README content
/// @param {Array} params.fileTree - List of file paths in the repository
/// @returns {Promise<Object>} Evaluation results with ratings and reasoning
export async function evaluateDocsAndTests({ fullName, readme, fileTree }) {
  const url = `${process.env.GROQ_BASE_URL}/chat/completions`;
  const testFiles = fileTree.filter((f) => /test|spec/i.test(f.path));
  const userContent = [
    `Repository: ${fullName}`,
    `README:\n${(readme ?? '(no README found)').slice(0, 6000)}`,
    `Detected test-related files (${testFiles.length}):\n${testFiles
      .slice(0, 100)
      .map((f) => f.path)
      .join('\n')}`,
  ].join('\n\n');

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.GROQ_MODEL,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userContent },
      ],
      temperature: 0.2,
    }),
  });

  if (!res.ok) throw new Error(`Groq API error ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const raw = data.choices?.[0]?.message?.content ?? '{}';
  return parseJsonSafely(raw, {
    docs_rating: null,
    docs_reasoning: '',
    tests_rating: null,
    tests_reasoning: '',
  });
}