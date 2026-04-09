import Redis from 'ioredis';
import { env } from '../config/env.js';

let client = null;

export function getRedis() {
  if (!env.REDIS_URL) return null;
  if (!client) {
    client = new Redis(env.REDIS_URL, {
      maxRetriesPerRequest: 2,
      enableOfflineQueue: false,
      lazyConnect: true,
    });
    client.on('error', (err) => console.error('[redis]', err.message));
  }
  return client;
}

export async function cacheGet(key) {
  const r = getRedis();
  if (!r) return null;
  try {
    if (r.status === 'wait' || r.status === 'end') await r.connect().catch(() => {});
    const raw = await r.get(key);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export async function cacheSet(key, value, ttlSeconds) {
  const r = getRedis();
  if (!r) return;
  try {
    if (r.status === 'wait' || r.status === 'end') await r.connect().catch(() => {});
    await r.set(key, JSON.stringify(value), 'EX', ttlSeconds);
  } catch {
    /* ignore cache errors */
  }
}

export async function cacheDel(key) {
  const r = getRedis();
  if (!r) return;
  try {
    await r.del(key);
  } catch {
    /* ignore */
  }
}
