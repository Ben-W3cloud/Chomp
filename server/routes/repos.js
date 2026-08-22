/// Repository routes.
///
/// Handles repository synchronization and watchlist management:
/// - POST /github/sync-repos - Sync repos from GitHub
/// - GET /repos - List all repos for the user
/// - POST /repos/:id/watch - Add repo to watchlist
/// - POST /repos/:id/unwatch - Remove repo from watchlist
/// - GET /repos/:id/scans - Get scan history for a repo
/// - GET /repos/:id/alerts - Get alerts for a repo

import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { asyncHandler } from '../middleware/asyncHandler.js';
import { query } from '../db.js';
import { decryptToken } from '../lib/crypto.js';
import { fetchRepos } from '../lib/githubClient.js';
import { AUTO_WATCH_COUNT, MAX_MANUAL_WATCHLIST } from '../lib/constants.js';

export const reposRouter = Router();

/// Sync repositories from GitHub.
///
/// Fetches the user's repos from GitHub, upserts them into the database,
/// and sets auto-watch flags for the top N most recently active repos.
///
/// @route POST /github/sync-repos
/// @returns {Object} Updated repo list
reposRouter.post('/github/sync-repos', requireAuth, async (req, res) => {
  try {
    const userRow = (await query('select * from users where id = $1', [req.userId])).rows[0];
    const accessToken = decryptToken(userRow.access_token_encrypted);
    const githubRepos = await fetchRepos(accessToken);

    // Sort by last push date and mark top N as auto-watched
    const sorted = [...githubRepos].sort((a, b) => new Date(b.pushed_at) - new Date(a.pushed_at));
    const autoWatchedIds = new Set(sorted.slice(0, AUTO_WATCH_COUNT).map((r) => r.id));

    // Upsert each repo into database
    for (const repo of githubRepos) {
      await query(
        `insert into repos (user_id, github_repo_id, name, full_name, description, language, default_branch, is_auto_watched, last_pushed_at)
         values ($1,$2,$3,$4,$5,$6,$7,$8,$9)
         on conflict (github_repo_id) do update set
           name = excluded.name,
           full_name = excluded.full_name,
           description = excluded.description,
           language = excluded.language,
           default_branch = excluded.default_branch,
           is_auto_watched = excluded.is_auto_watched,
           last_pushed_at = excluded.last_pushed_at`,
        [
          req.userId,
          repo.id,
          repo.name,
          repo.full_name,
          repo.description,
          repo.language,
          repo.default_branch,
          autoWatchedIds.has(repo.id),
          repo.pushed_at,
        ],
      );
    }

    const result = await query('select * from repos where user_id = $1 order by last_pushed_at desc', [
      req.userId,
    ]);
    res.json({ repos: result.rows.map(toRepoJson) });
  } catch (err) {
    console.error('sync-repos failed', err);
    res.status(500).json({ error: 'Failed to sync repos from GitHub' });
  }
});

/// List all repositories for the authenticated user.
///
/// @route GET /repos
/// @returns {Object} List of repos with watch status
reposRouter.get('/repos', requireAuth, asyncHandler(async (req, res) => {
  const result = await query('select * from repos where user_id = $1 order by last_pushed_at desc', [
    req.userId,
  ]);
  res.json({ repos: result.rows.map(toRepoJson) });
}));

/// Add a repository to the manual watchlist.
///
/// Enforces the maximum manual watchlist size limit.
///
/// @route POST /repos/:id/watch
/// @returns {Object} Success status
reposRouter.post('/repos/:id/watch', requireAuth, asyncHandler(async (req, res) => {
  const countRow = await query(
    'select count(*) from repos where user_id = $1 and is_manually_watched = true',
    [req.userId],
  );
  if (Number(countRow.rows[0].count) >= MAX_MANUAL_WATCHLIST) {
    return res.status(400).json({ error: `Watchlist is full (${MAX_MANUAL_WATCHLIST} max)` });
  }
  await query('update repos set is_manually_watched = true where id = $1 and user_id = $2', [
    req.params.id,
    req.userId,
  ]);
  res.json({ ok: true });
}));

/// Remove a repository from the manual watchlist.
///
/// @route POST /repos/:id/unwatch
/// @returns {Object} Success status
reposRouter.post('/repos/:id/unwatch', requireAuth, asyncHandler(async (req, res) => {
  await query('update repos set is_manually_watched = false where id = $1 and user_id = $2', [
    req.params.id,
    req.userId,
  ]);
  res.json({ ok: true });
}));

/// Get scan history for a repository.
///
/// @route GET /repos/:id/scans
/// @param {number} limit - Max number of scans to return (default: 30)
/// @returns {Object} List of scan results
reposRouter.get('/repos/:id/scans', requireAuth, asyncHandler(async (req, res) => {
  const limit = Number(req.query.limit ?? 30);
  if (!Number.isFinite(limit) || limit <= 0) {
    return res.status(400).json({ error: 'Invalid limit' });
  }
  const result = await query(
    'select * from scan_results where repo_id = $1 order by scanned_at desc limit $2',
    [req.params.id, limit],
  );
  res.json({ scans: result.rows });
}));

/// Get alerts for a repository.
///
/// @route GET /repos/:id/alerts
/// @returns {Object} List of alerts
reposRouter.get('/repos/:id/alerts', requireAuth, asyncHandler(async (req, res) => {
  const result = await query('select * from alerts where repo_id = $1 order by created_at desc', [
    req.params.id,
  ]);
  res.json({ alerts: result.rows });
}));

/// Converts a database row to a JSON-serializable repo object.
function toRepoJson(row) {
  return {
    id: row.id,
    github_repo_id: Number(row.github_repo_id),
    name: row.name,
    full_name: row.full_name,
    description: row.description,
    language: row.language,
    default_branch: row.default_branch,
    is_auto_watched: row.is_auto_watched,
    is_manually_watched: row.is_manually_watched,
    last_pushed_at: row.last_pushed_at,
  };
}