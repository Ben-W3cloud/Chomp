import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';

export const feedRouter = Router();

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