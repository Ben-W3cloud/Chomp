/// Internal cron routes.
///
/// Provides an HTTP endpoint for triggering hourly scans.
/// This is used when the server is deployed as serverless (no
/// persistent process to run node-cron).
///
/// Protected by a shared secret to prevent unauthorized access.
/// - POST /internal/hourly-scan - Trigger hourly scan

import { Router } from 'express';
import crypto from 'crypto';
import { runHourlyScan } from '../lib/hourlyScan.js';

export const internalCronRouter = Router();

/// Constant-time string comparison to avoid timing attacks on the secret.
function safeEqual(a, b) {
  const bufA = Buffer.from(a ?? '');
  const bufB = Buffer.from(b ?? '');
  if (bufA.length !== bufB.length) return false;
  return crypto.timingSafeEqual(bufA, bufB);
}

/**
 * Triggers an hourly scan of all watched repositories.
 *
 * Use this if you deploy as serverless (no persistent process to host
 * node-cron). Point an external scheduler — Neon Functions' own cron
 * config once you've confirmed the current syntax, a free service like
 * cron-job.org, or a GitHub Actions scheduled workflow doing a `curl`
 * — at this endpoint once an hour. Protected by a shared secret header
 * so randoms can't trigger it.
 *
 * @route POST /internal/hourly-scan
 * @header x-cron-secret - Shared secret for authentication
 * @returns {Object} Scan results summary
 */
internalCronRouter.post('/internal/hourly-scan', async (req, res) => {
  const secret = process.env.CRON_SECRET;
  // Fail closed: if the secret is unset the endpoint must not run.
  if (!secret) {
    console.error('CRON_SECRET is not set; refusing to run hourly scan.');
    return res.status(500).json({ error: 'Server misconfiguration' });
  }
  if (!safeEqual(req.headers['x-cron-secret'], secret)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  try {
    const result = await runHourlyScan();
    res.json(result);
  } catch (err) {
    console.error('Hourly scan failed:', err);
    res.status(500).json({ error: 'Scan failed' });
  }
});