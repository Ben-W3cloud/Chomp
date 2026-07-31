/// Feed routes.
///
/// Handles activity feed retrieval:
/// - GET /feed - Get user's activity feed

import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';

export const feedRouter = Router();

/// Get the user's activity feed.
///
/// Returns a chronological list of feed items including scan completions,
/// commits, pull requests, and issues (when webhooks are implemented).
///
/// @route GET /feed
/// @param {number} limit - Max number of items to return (default: 50)
/// @returns {Object} List of feed items with repo names
feedRouter.get('/feed', requireAuth, async (req, res) => {
  const limit = Number(req.query.limit ?? 50);
  const result = await query(
    `select f.*, r.name as repo_name from feed_items f
     join repos r on r.id = f.repo_id
     where f.user_id = $1 order by f.created_at desc limit $2`,
    [req.userId, limit],
  );
  res.json({ items: result.rows });
});