import { Router } from 'express';
import { runHourlyScan } from '../lib/hourlyScan.js';

export const internalCronRouter = Router();

/**
 * Use this if you deploy as serverless (no persistent process to host
 * node-cron). Point an external scheduler — Neon Functions' own cron
 * config once you've confirmed the current syntax, a free service like
 * cron-job.org, or a GitHub Actions scheduled workflow doing a `curl`
 * — at this endpoint once an hour. Protected by a shared secret header
 * so randoms can't trigger it.
 */
internalCronRouter.post('/internal/hourly-scan', async (req, res) => {
  if (req.headers['x-cron-secret'] !== process.env.CRON_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  const result = await runHourlyScan();
  res.json(result);
});