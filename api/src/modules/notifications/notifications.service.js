import { initializeApp, cert, getApps } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { prisma } from '../../database/prisma.js';

function ensureFirebase() {
  if (getApps().length > 0) return;
  const raw = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON is not set');
  initializeApp({ credential: cert(JSON.parse(raw)) });
}

export async function sendToAll({ title, body }) {
  ensureFirebase();

  const users = await prisma.user.findMany({
    where: { fcmToken: { not: null }, role: 'user' },
    select: { id: true, fcmToken: true },
  });

  const tokens = users.map((u) => u.fcmToken).filter(Boolean);
  if (tokens.length === 0) return { sent: 0, failed: 0 };

  const response = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  });

  return {
    sent: response.successCount,
    failed: response.failureCount,
    total: tokens.length,
  };
}

export async function sendToUser({ userId, title, body }) {
  ensureFirebase();

  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { fcmToken: true },
  });

  if (!user?.fcmToken) throw new Error('User has no FCM token registered');

  await getMessaging().send({
    token: user.fcmToken,
    notification: { title, body },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  });

  return { sent: 1, failed: 0, total: 1 };
}
