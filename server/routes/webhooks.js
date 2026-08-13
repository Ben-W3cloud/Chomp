import { Router } from 'express';
import crypto from 'crypto';
import { query } from '../db.js';

const router = Router();
const WEBHOOK_SECRET = process.env.GITHUB_WEBHOOK_SECRET;

router.post('/github/webhook', async (req, res) => {
  const signature = req.headers['x-hub-signature-256'];
  const payload = req.body;
  const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
  const digest = 'sha256=' + hmac.update(JSON.stringify(payload)).digest('hex');

  if (signature !== digest) return res.status(401).send('Invalid signature');

  const event = req.headers['x-github-event'];
  const repoFullName = payload.repository?.full_name;

  if (!repoFullName) return res.status(200).send('OK');

  const repos = await query(
    'SELECT id, user_id FROM repos WHERE full_name = $1 AND (is_auto_watched = true OR is_manually_watched = true)',
    [repoFullName]
  );

  if (repos.rows.length === 0) return res.status(200).send('OK');

  switch (event) {
    case 'push':
      const headCommit = payload.head_commit;
      for (const row of repos.rows) {
        await query(
          `INSERT INTO feed_items (user_id, repo_id, type, title, github_url)
           VALUES ($1, $2, 'commit', $3, $4)`,
          [row.user_id, row.id, headCommit?.message || 'New push', headCommit?.url]
        );
      }
      break;
  }

  res.status(200).send('OK');
});

export { router as webhookRouter };