/// NVIDIA AI client for code analysis.
///
/// Sends repository code samples to NVIDIA's API for analysis.
/// Returns security scores, code quality scores, and specific findings.
///
/// Uses the NVIDIA NIM or NVIDIA AI Foundation API endpoint.

import { parseJsonSafely } from './safeJson.js';

/// System prompt that instructs the AI to analyze code and security.
const SYSTEM_PROMPT = `You are a static analysis engine. You will be given a repository's file tree, its README, and a sample of source files. Respond with ONLY valid JSON, no markdown fences, no prose, matching exactly this shape:
{
  "security_score": <integer 0-100>,
  "security_findings": [<string>, ...],
  "code_quality_score": <integer 0-100>,
  "code_quality_findings": [<string>, ...]
}
Findings should be short, specific, and actionable — reference actual file names where possible. If you cannot assess something, give your best estimate rather than omitting the field.`;

/// Analyzes a repository's code and security using NVIDIA AI.
///
/// @param {Object} params - Analysis parameters
/// @param {string} params.fullName - Repository full name (owner/repo)
/// @param {Array} params.fileTree - List of file paths in the repository
/// @param {Array} params.sampleFiles - Sample file contents to analyze
/// @returns {Promise<Object>} Analysis results with scores and findings
export async function analyseCodeAndSecurity({ fullName, fileTree, sampleFiles }) {
  const url = `${process.env.NVIDIA_BASE_URL}/chat/completions`;
  const userContent = [
    `Repository: ${fullName}`,
    `File tree (first 300 entries):\n${fileTree.slice(0, 300).join('\n')}`,
    `Sample file contents:\n${sampleFiles
      .map((f) => `--- ${f.path} ---\n${f.content.slice(0, 4000)}`)
      .join('\n\n')}`,
  ].join('\n\n');

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${process.env.NVIDIA_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: process.env.NVIDIA_MODEL,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user', content: userContent },
      ],
      temperature: 0.2,
    }),
  });

  if (!res.ok) throw new Error(`NVIDIA API error ${res.status}: ${await res.text()}`);

  const data = await res.json();
  const raw = data.choices?.[0]?.message?.content ?? '{}';
  return parseJsonSafely(raw, {
    security_score: null,
    security_findings: [],
    code_quality_score: null,
    code_quality_findings: [],
  });
}