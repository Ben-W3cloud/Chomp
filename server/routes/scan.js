/// Scan routes.
///
/// Handles manual scan triggers via Server-Sent Events (SSE):
/// - POST /scan/:repoId - Start a manual scan with live progress

import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';
import { decryptToken } from '../lib/crypto.js';
import { scanRepo } from '../lib/scanRepo.js';

export const scanRouter = Router();

/// Start a manual scan for a repository.
///
/// Opens an SSE connection and streams phase updates as the scan
/// progresses through fetching, analysis, and storage.
///
/// @route POST /scan/:repoId
/// @returns {Stream} SSE stream of scan phase events
scanRouter.post('/scan/:repoId', requireAuth, async (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();

  const send = (phase, message, payload) => {
    res.write(`event: ${phase}\n`);
    res.write(`data: ${JSON.stringify({ phase, message, ...(payload ? { result: payload } : {}) })}\n\n`);
  };

  try {
    const repoRow = (
      await query('select * from repos where id = $1 and user_id = $2', [req.params.repoId, req.userId])
    ).rows[0];
    if (!repoRow) {
      send('error', 'Repo not found');
      return res.end();
    }

    const userRow = (await query('select * from users where id = $1', [req.userId])).rows[0];
    const accessToken = decryptToken(userRow.access_token_encrypted);

    await scanRepo(repoRow, accessToken, send);
    res.end();
  } catch (err) {
    console.error('Manual scan failed', err);
    send('error', `Scan failed: ${err.message}`);
    res.end();
  }
});