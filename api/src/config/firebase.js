import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

function init() {
  if (getApps().length > 0) return;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not set in environment');
  }

  initializeApp({ credential: cert(JSON.parse(raw)) });
}

export async function verifyFirebaseToken(idToken) {
  init();
  return getAuth().verifyIdToken(idToken);
}
