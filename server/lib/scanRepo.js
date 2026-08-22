/// Repository scan orchestrator.
///
/// Coordinates the full scan pipeline for a single repository:
/// 1. Fetch repo data from GitHub (README, file tree, commits)
/// 2. Pick sample files for AI analysis
/// 3. Run NVIDIA for code quality + security scores
/// 4. Run Groq for documentation + test ratings
/// 5. Store results in Neon database
/// 6. Create alerts for new findings
/// 7. Send push notifications if needed
///
/// This is the heart of the Chomp app - where all the AI magic happens.

import { query } from '../db.js';
import { fetchReadme, fetchRepoTree, fetchFileContent } from './githubClient.js';
import { analyseCodeAndSecurity } from './nvidiaClient.js';
import { evaluateDocsAndTests } from './groqClient.js';
import { SCORE_DROP_NOTIFY_THRESHOLD } from './constants.js';
import { sendPush } from './fcm.js';

/**
 * Runs a full scan for one repo. `onPhase(phase, message, payload?)` is
 * called at each step — the SSE route uses it to stream live updates
 * to the phone; the hourly cron job ignores it (default no-op).
 *
 * @param {Object} repoRow - Repository database row
 * @param {string} accessToken - GitHub access token
 * @param {Function} onPhase - Callback for scan phase updates
 * @returns {Promise<Object>} Inserted scan result row
 */
export async function scanRepo(repoRow, accessToken, onPhase = () => {}) {
  onPhase('fetching', `Fetching ${repoRow.full_name} from GitHub...`);
  const [readme, fileTree] = await Promise.all([
    fetchReadme(accessToken, repoRow.full_name),
    fetchRepoTree(accessToken, repoRow.full_name, repoRow.default_branch),
  ]);
  onPhase('ingesting', `Ingesting ${fileTree.length} files...`);
  const sampleFiles = await pickSampleFiles(accessToken, repoRow.full_name, fileTree);

  onPhase('analysing', 'Analysing repository structure...');
  onPhase('code_review', 'Running code review (NVIDIA)...');
  onPhase('security_check', 'Running security check (NVIDIA)...');
  const nvidiaResult = await analyseCodeAndSecurity({
    fullName: repoRow.full_name,
    fileTree: fileTree.map((f) => f.path),
    sampleFiles,
  });

  onPhase('docs_eval', 'Evaluating documentation (Groq)...');
  const groqResult = await evaluateDocsAndTests({
    fullName: repoRow.full_name,
    readme,
    fileTree,
  });
  onPhase('tests_eval', 'Evaluating test coverage (Groq)...');

  const findings = [
    ...(nvidiaResult.security_findings ?? []),
    ...(nvidiaResult.code_quality_findings ?? []),
  ];

  const previous = (
    await query('select * from scan_results where repo_id = $1 order by scanned_at desc limit 1', [
      repoRow.id,
    ])
  ).rows[0];

  const inserted = (
    await query(
      `insert into scan_results (repo_id, security_score, code_quality_score, docs_rating, tests_rating, findings)
       values ($1,$2,$3,$4,$5,$6) returning *`,
      [
        repoRow.id,
        nvidiaResult.security_score,
        nvidiaResult.code_quality_score,
        groqResult.docs_rating,
        groqResult.tests_rating,
        JSON.stringify(findings),
      ],
    )
  ).rows[0];

  await query(
    `insert into feed_items (user_id, repo_id, type, title, github_url) values ($1,$2,'scan_complete',$3,$4)`,
    [repoRow.user_id, repoRow.id, `Scan complete — Security ${nvidiaResult.security_score ?? '—'}`, null],
  );

  await maybeCreateAlertsAndNotify(repoRow, previous, inserted, findings);

  onPhase('complete', `Done — ${findings.length} findings`, inserted);
  return inserted;
}

/**
 * Creates alerts for new findings and sends push notifications.
 *
 * Alerts are only created if:
 * - There are new findings not in the previous scan
 * - Security score dropped by threshold or more
 *
 * @param {Object} repoRow - Repository database row
 * @param {Object} previous - Previous scan result (if any)
 * @param {Object} current - Current scan result
 * @param {Array} findings - List of findings from current scan
 */
async function maybeCreateAlertsAndNotify(repoRow, previous, current, findings) {
  const previousFindings = previous?.findings ?? [];
  const newFindings = findings.filter((f) => !previousFindings.includes(f));

  const scoreDropped =
    previous?.security_score != null &&
    current.security_score != null &&
    previous.security_score - current.security_score >= SCORE_DROP_NOTIFY_THRESHOLD;

  if (newFindings.length === 0 && !scoreDropped) return; // silent scan — nothing worth telling the user

  for (const finding of newFindings) {
    await query(
      `insert into alerts (repo_id, scan_result_id, message, severity) values ($1,$2,$3,$4)`,
      [repoRow.id, current.id, finding, 'warning'],
    );
  }

  const devices = await query('select fcm_token from device_tokens where user_id = $1', [repoRow.user_id]);
  const message = scoreDropped
    ? `${repoRow.name}: security score dropped to ${current.security_score}`
    : `${repoRow.name}: ${newFindings.length} new finding(s)`;

  for (const { fcm_token } of devices.rows) {
    await sendPush(fcm_token, repoRow.name, message);
  }
}

/**
 * Picks a small sample of files for AI analysis.
 *
 * Deliberately limited to avoid exceeding AI model context limits
 * and to keep API costs low. Prioritizes common code file types.
 *
 * @param {string} accessToken - GitHub access token
 * @param {string} fullName - Repository full name
 * @param {Array} fileTree - Complete file tree
 * @returns {Promise<Array>} Array of {path, content} objects
 */
async function pickSampleFiles(accessToken, fullName, fileTree) {
  // Deliberately small and cheap — full repos can blow past model
  // context limits and the free-tier rate limits on NVIDIA/Groq. Grab
  // a handful of the most relevant files rather than everything.
  const candidates = fileTree
    .filter((f) => f.type === 'blob')
    .filter((f) => /\.(dart|js|ts|py|go|rs|java|kt|swift|json|yaml|yml|toml)$/.test(f.path))
    .slice(0, 8);

  const files = [];
  for (const c of candidates) {
    const content = await fetchFileContent(accessToken, fullName, c.path);
    if (content != null) files.push({ path: c.path, content });
  }
  return files;
}