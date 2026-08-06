import { prisma } from '../../database/prisma.js';

/** How long raw events are kept. Pruned on ingest, so no scheduled job. */
const RETENTION_DAYS = 60;

/**
 * Pruning runs at most once an hour rather than on every batch: the delete is
 * cheap but not free, and the app flushes often enough that doing it every time
 * would be pure overhead.
 */
let lastPruneAt = 0;
const PRUNE_INTERVAL_MS = 60 * 60 * 1000;

/** Path only. A query string on a storage url can carry a signature. */
function trimUrl(url) {
  if (!url) return null;
  try {
    const { pathname } = new URL(url);
    return pathname.slice(0, 500);
  } catch {
    return url.slice(0, 500);
  }
}

export async function record({ events, platform, appVersion, userId }) {
  const rows = events.map((e) => ({
    type: e.type,
    ms: e.ms ?? null,
    bytes: e.bytes ?? null,
    cacheHit: e.cacheHit ?? null,
    ok: e.ok ?? true,
    url: trimUrl(e.url),
    platform: platform ?? null,
    appVersion: appVersion ?? null,
    userId: userId ?? null,
  }));

  await prisma.mediaEvent.createMany({ data: rows });
  void prune();
  return rows.length;
}

async function prune() {
  const now = Date.now();
  if (now - lastPruneAt < PRUNE_INTERVAL_MS) return;
  lastPruneAt = now;
  try {
    const cutoff = new Date(now - RETENTION_DAYS * 86400000);
    await prisma.mediaEvent.deleteMany({ where: { createdAt: { lt: cutoff } } });
  } catch {
    // Housekeeping. Never allowed to fail an ingest.
  }
}

/** Median and p95 from a sorted list, so the slow tail stays visible. */
function percentile(sorted, p) {
  if (sorted.length === 0) return null;
  const idx = Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length));
  return sorted[idx];
}

function timings(values) {
  const sorted = values.filter((v) => typeof v === 'number').sort((a, b) => a - b);
  if (sorted.length === 0) {
    return { count: 0, avgMs: null, medianMs: null, p95Ms: null };
  }
  const sum = sorted.reduce((a, b) => a + b, 0);
  return {
    count: sorted.length,
    avgMs: Math.round(sum / sorted.length),
    medianMs: percentile(sorted, 50),
    p95Ms: percentile(sorted, 95),
  };
}

/**
 * Everything the dashboard shows, from one scan of the window.
 *
 * Pulled as rows and reduced in memory rather than as several grouped queries:
 * the retention cap bounds this to a size that fits comfortably, and one pass
 * keeps every figure describing exactly the same set of events.
 */
export async function summary(days = 7) {
  const since = new Date(Date.now() - days * 86400000);

  const events = await prisma.mediaEvent.findMany({
    where: { createdAt: { gte: since } },
    select: {
      type: true,
      ms: true,
      bytes: true,
      cacheHit: true,
      ok: true,
      url: true,
      createdAt: true,
    },
    orderBy: { createdAt: 'desc' },
    // A ceiling so a traffic spike cannot turn the dashboard into a slow query.
    take: 200000,
  });

  const imageMs = [];
  const videoMs = [];
  const sizes = [];
  let cacheHits = 0;
  let cacheMisses = 0;
  let bufferEvents = 0;
  let downloadOk = 0;
  let downloadFail = 0;
  let videoStartFail = 0;

  /** Per-day series for the chart, keyed yyyy-mm-dd. */
  const byDay = new Map();
  /** Assets that fail most often — the actionable part of a failure count. */
  const failuresByUrl = new Map();

  for (const e of events) {
    const day = e.createdAt.toISOString().slice(0, 10);
    let bucket = byDay.get(day);
    if (!bucket) {
      bucket = { day, imageMs: [], videoMs: [], hits: 0, misses: 0, failures: 0 };
      byDay.set(day, bucket);
    }

    if (e.cacheHit === true) {
      cacheHits += 1;
      bucket.hits += 1;
    } else if (e.cacheHit === false) {
      cacheMisses += 1;
      bucket.misses += 1;
    }

    // Only a miss moved bytes, so only a miss describes the real file size.
    if (typeof e.bytes === 'number' && e.bytes > 0 && e.cacheHit !== true) {
      sizes.push(e.bytes);
    }

    switch (e.type) {
      case 'image_load':
        if (e.ok && typeof e.ms === 'number') {
          imageMs.push(e.ms);
          bucket.imageMs.push(e.ms);
        }
        break;
      case 'video_start':
        if (e.ok && typeof e.ms === 'number') {
          videoMs.push(e.ms);
          bucket.videoMs.push(e.ms);
        } else if (!e.ok) {
          videoStartFail += 1;
        }
        break;
      case 'buffer':
        bufferEvents += 1;
        break;
      case 'download_ok':
        downloadOk += 1;
        break;
      case 'download_fail':
        downloadFail += 1;
        bucket.failures += 1;
        if (e.url) failuresByUrl.set(e.url, (failuresByUrl.get(e.url) ?? 0) + 1);
        break;
      default:
        break;
    }
  }

  const cacheTotal = cacheHits + cacheMisses;
  const sizeSum = sizes.reduce((a, b) => a + b, 0);

  const series = [...byDay.values()]
    .sort((a, b) => a.day.localeCompare(b.day))
    .map((b) => ({
      day: b.day,
      imageMs: b.imageMs.length
        ? Math.round(b.imageMs.reduce((x, y) => x + y, 0) / b.imageMs.length)
        : null,
      videoMs: b.videoMs.length
        ? Math.round(b.videoMs.reduce((x, y) => x + y, 0) / b.videoMs.length)
        : null,
      cacheHitRatio: b.hits + b.misses > 0 ? b.hits / (b.hits + b.misses) : null,
      failures: b.failures,
    }));

  return {
    days,
    since: since.toISOString(),
    totalEvents: events.length,
    imageLoad: timings(imageMs),
    videoStart: timings(videoMs),
    cache: {
      hits: cacheHits,
      misses: cacheMisses,
      // Null rather than zero when nothing was measured: "no data" and "every
      // request missed" are opposite readings and must not look the same.
      hitRatio: cacheTotal > 0 ? cacheHits / cacheTotal : null,
    },
    bufferEvents,
    downloads: {
      ok: downloadOk,
      failed: downloadFail,
      failureRate: downloadOk + downloadFail > 0 ? downloadFail / (downloadOk + downloadFail) : null,
    },
    videoStartFailures: videoStartFail,
    averageBytes: sizes.length ? Math.round(sizeSum / sizes.length) : null,
    transferredBytes: sizeSum,
    series,
    topFailures: [...failuresByUrl.entries()]
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10)
      .map(([url, count]) => ({ url, count })),
  };
}
