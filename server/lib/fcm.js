import admin from 'firebase-admin';

let initialised = false;

function ensureInit() {
  if (initialised) return;
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)),
  });
  initialised = true;
}

export async function sendPush(token, title, body) {
  ensureInit();
  try {
    await admin.messaging().send({ token, notification: { title, body } });
  } catch (err) {
    console.error('FCM send failed', err);
  }
}