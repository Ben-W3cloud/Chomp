import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';

export const notificationsRouter = Router();

notificationsRouter.post('/notifications/register-device', requireAuth, async (req, res) => {
  const { fcm_token } = req.body;
  if (!fcm_token) return res.status(400).json({ error: 'Missing fcm_token' });
  await query(
    `insert into device_tokens (user_id, fcm_token) values ($1,$2)
     on conflict (fcm_token) do update set user_id = excluded.user_id`,
    [req.userId, fcm_token],
  );
  res.json({ ok: true });
});