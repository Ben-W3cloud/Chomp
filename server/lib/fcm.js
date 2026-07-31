/// Firebase Cloud Messaging service.
///
/// Handles sending push notifications to user devices via Firebase.
/// Used to alert users when:
/// - New scan findings are discovered
/// - Security scores drop significantly
///
/// Requires Firebase Admin SDK initialization with a service account.

import admin from 'firebase-admin';

let initialised = false;

/// Initializes Firebase Admin SDK if not already initialized.
///
/// Reads the service account credentials from the FIREBASE_SERVICE_ACCOUNT_JSON
/// environment variable (JSON string).
function ensureInit() {
  if (initialised) return;
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)),
  });
  initialised = true;
}

/// Sends a push notification to a device.
///
/// @param {string} token - FCM device token
/// @param {string} title - Notification title
/// @param {string} body - Notification body text
export async function sendPush(token, title, body) {
  ensureInit();
  try {
    await admin.messaging().send({ token, notification: { title, body } });
  } catch (err) {
    console.error('FCM send failed', err);
  }
}