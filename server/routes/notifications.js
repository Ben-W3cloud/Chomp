/// Notification routes.
///
/// Handles push notification device registration:
/// - POST /notifications/register-device - Register FCM device token

import { Router } from 'express';
import { requireAuth } from '../middleware/auth.js';
import { query } from '../db.js';

export const notificationsRouter = Router();

/// Register a device for push notifications.
///
/// Stores the FCM token in the database so the server can send
/// push notifications to this device when alerts are triggered.
///
/// @route POST /notifications/register-device
/// @param {string} fcm_token - Firebase Cloud Messaging device token
/// @returns {Object} Success status
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