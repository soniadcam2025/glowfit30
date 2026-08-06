import { env } from './env.js';

/**
 * Serves media through a CDN hostname instead of the bucket.
 *
 * Rewriting happens on the way out, never on the way in: the database keeps
 * origin urls forever. That is what makes this reversible — unsetting
 * MEDIA_CDN_BASE puts every response straight back on the bucket with no data
 * migration, and a CDN outage is a config change away from being bypassed.
 * Storing cdn urls instead would bake the vendor into every content row.
 */

/** `https://media.glowfit30.com`, no trailing slash. */
function base() {
  const raw = (env.MEDIA_CDN_BASE ?? '').trim();
  if (!raw) return null;
  return raw.replace(/\/+$/, '');
}

/** Bucket hostname suffix, e.g. `blr1.vultrobjects.com`. */
function originHost() {
  const endpoint = (env.VULTR_S3_ENDPOINT ?? '').replace(/^https?:\/\//, '');
  return endpoint.replace(/\/+$/, '');
}

export function cdnEnabled() {
  return Boolean(base() && originHost());
}

/**
 * Origin url -> cdn url.
 *
 * The bucket name is kept as the first path segment so a single CDN hostname
 * can front both buckets, and so the path still says which bucket an object
 * came from when reading logs.
 */
export function toCdnUrl(url) {
  const cdn = base();
  const host = originHost();
  if (!cdn || !host || typeof url !== 'string') return url;

  try {
    const parsed = new URL(url);
    if (!parsed.hostname.endsWith(host)) return url;

    const bucket = parsed.hostname.slice(0, -(host.length + 1));
    if (!bucket) return url;

    return `${cdn}/${bucket}${parsed.pathname}`;
  } catch {
    return url;
  }
}

/**
 * cdn url -> origin url.
 *
 * Needed because deletes work backwards from whatever url a row holds. Without
 * this, a cdn url reaching the storage layer would parse into a nonsense bucket
 * and the delete would silently do nothing.
 */
export function toOriginUrl(url) {
  const cdn = base();
  const host = originHost();
  if (!cdn || !host || typeof url !== 'string' || !url.startsWith(`${cdn}/`)) {
    return url;
  }

  const rest = url.slice(cdn.length + 1);
  const slash = rest.indexOf('/');
  if (slash <= 0) return url;

  const bucket = rest.slice(0, slash);
  const key = rest.slice(slash + 1);
  return `https://${bucket}.${host}/${key}`;
}
