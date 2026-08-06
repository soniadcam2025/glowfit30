import { prisma } from '../database/prisma.js';
import { toCdnUrl } from '../config/cdn.js';

/**
 * Attaches full media objects to API responses.
 *
 * Done here, once, rather than in each module's serialisation. Image urls live
 * in eleven columns and inside two Json columns, and every one of them is
 * returned by several endpoints — expanding them at the source would mean
 * touching every service and would still miss the Json ones.
 *
 * Backward compatible on purpose: `imageUrl` and `videoUrl` keep their exact
 * previous meaning and type, and `image` / `video` objects appear alongside.
 * The live app and the admin panel read the strings and are unaffected; only
 * clients that know about the objects see them. Removing the strings would
 * break both at once, for no gain.
 */

/**
 * Assets are immutable — a `<uuid>/` prefix is written once and never changes —
 * so a resolved url can be cached for the life of the process. This is what
 * keeps the expansion off the request path after the first hit.
 */
const cache = new Map();
const CACHE_LIMIT = 5000;

function remember(url, value) {
  // Crude eviction, but the working set is the content library and it is small.
  // A stale entry is impossible; only unbounded growth is worth defending.
  if (cache.size >= CACHE_LIMIT) cache.clear();
  cache.set(url, value);
}

function imageObject(a) {
  return {
    thumb: toCdnUrl(a.thumbUrl),
    medium: toCdnUrl(a.mediumUrl),
    large: toCdnUrl(a.largeUrl),
    width: a.width,
    height: a.height,
    mime: a.mime ?? 'image/webp',
    size: a.largeBytes,
    blurhash: a.blurhash,
  };
}

function videoObject(a) {
  return {
    url: toCdnUrl(a.videoUrl),
    poster: toCdnUrl(a.posterUrl),
    duration: a.durationSeconds,
    width: a.width,
    height: a.height,
    mime: a.mime ?? 'video/mp4',
    size: a.bytes,
    blurhash: a.blurhash,
  };
}

/**
 * Everything an un-migrated url can still say about itself.
 *
 * Media uploaded before the pipeline has no row, and returning nothing for it
 * would make the new field unusable — a client would have to handle "sometimes
 * absent" everywhere. Instead every size points at the one file that exists, so
 * the shape is always the same and old content simply looks lower quality
 * rather than missing.
 */
function legacyImage(rawUrl) {
  const url = toCdnUrl(rawUrl);
  return {
    thumb: url,
    medium: url,
    large: url,
    width: null,
    height: null,
    mime: null,
    size: null,
    blurhash: null,
  };
}

function legacyVideo(rawUrl) {
  return { url: toCdnUrl(rawUrl), poster: null, duration: null, width: null, height: null, mime: 'video/mp4', size: null, blurhash: null };
}

/** Walks a payload collecting every imageUrl/videoUrl string value. */
function collect(node, found, depth = 0) {
  if (depth > 12 || node === null || typeof node !== 'object') return;
  if (Array.isArray(node)) {
    for (const n of node) collect(n, found, depth + 1);
    return;
  }
  for (const [k, v] of Object.entries(node)) {
    if ((k === 'imageUrl' || k === 'videoUrl' || k === 'heroImageUrl' ||
         k === 'cardImageUrl' || k === 'gifUrl' || k === 'photoUrl') &&
        typeof v === 'string' && v.startsWith('http')) {
      found.add(v);
    } else {
      collect(v, found, depth + 1);
    }
  }
}

/** Which sibling key an object goes under. `heroImageUrl` -> `heroImage`. */
const OBJECT_KEY = {
  imageUrl: 'image',
  heroImageUrl: 'heroImage',
  cardImageUrl: 'cardImage',
  gifUrl: 'gif',
  photoUrl: 'photo',
  videoUrl: 'video',
};

function attach(node, assets, depth = 0) {
  if (depth > 12 || node === null || typeof node !== 'object') return node;
  if (Array.isArray(node)) return node.map((n) => attach(n, assets, depth + 1));

  const out = {};
  for (const [k, v] of Object.entries(node)) {
    out[k] = attach(v, assets, depth + 1);

    const objectKey = OBJECT_KEY[k];
    if (!objectKey || typeof v !== 'string' || !v.startsWith('http')) continue;

    // The legacy string is rewritten too, not just the object. Screens that
    // still read `imageUrl` — the workout ones — get the CDN without any app
    // change, which is the point of doing this at the edge.
    out[k] = toCdnUrl(v);
    // Never clobber a real field that happens to share the name.
    if (objectKey in node) continue;

    const asset = assets.get(v);
    const isVideo = k === 'videoUrl';
    out[objectKey] = asset
      ? (isVideo ? videoObject(asset) : imageObject(asset))
      : (isVideo ? legacyVideo(v) : legacyImage(v));
  }
  return out;
}

/**
 * Looks up every url in one query and expands the payload.
 *
 * One `findMany` for the whole response rather than a lookup per url: a workout
 * list can carry a hundred images, and a query each would turn one response
 * into a hundred round trips.
 */
export async function expandMedia(data) {
  if (data === null || typeof data !== 'object') return data;

  const urls = new Set();
  collect(data, urls);
  if (urls.size === 0) return data;

  const assets = new Map();
  const missing = [];
  for (const url of urls) {
    if (cache.has(url)) {
      const hit = cache.get(url);
      if (hit) assets.set(url, hit);
    } else {
      missing.push(url);
    }
  }

  if (missing.length > 0) {
    try {
      const rows = await prisma.mediaAsset.findMany({
        where: {
          OR: [
            { largeUrl: { in: missing } },
            { videoUrl: { in: missing } },
            { legacyUrl: { in: missing } },
            { originalUrl: { in: missing } },
          ],
        },
      });

      for (const row of rows) {
        for (const url of [row.largeUrl, row.videoUrl, row.legacyUrl, row.originalUrl]) {
          if (url && missing.includes(url)) {
            assets.set(url, row);
            remember(url, row);
          }
        }
      }
      // Remember the misses too, so un-migrated urls stop costing a query.
      for (const url of missing) if (!assets.has(url)) remember(url, null);
    } catch (e) {
      // The strings are still correct without this. A lookup failure must
      // degrade the response, never fail it.
      console.error('[media] expansion failed:', e.message);
      return data;
    }
  }

  return attach(data, assets);
}

/** Drops cached entries for a url set. Called after a delete. */
export function forgetMedia(urls = []) {
  for (const url of urls) cache.delete(url);
}
