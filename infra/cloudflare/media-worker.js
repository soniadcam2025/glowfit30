/**
 * Serves GlowFit media from Vultr Object Storage through media.glowfit30.com.
 *
 * The whole reason this exists is one header. Vultr is Ceph RadosGW, which
 * derives the bucket from the Host header. Cloudflare forwards
 * `Host: media.glowfit30.com`, so the gateway looks for a bucket by that name
 * and answers `NoSuchBucket`. Rewriting the request to the endpoint makes
 * `fetch` send `Host: blr1.vultrobjects.com`, which is the fix — the Free plan
 * cannot override a Host header declaratively, but a Worker gets it for free
 * by simply requesting the right URL.
 *
 *   in   https://media.glowfit30.com/wrkt1bckt1/<uuid>/large.webp
 *   out  https://blr1.vultrobjects.com/wrkt1bckt1/<uuid>/large.webp
 *
 * The bucket stays as the first path segment so one hostname fronts both
 * buckets, which is what the API's `toCdnUrl` already emits. Nothing about the
 * URLs stored in the database changes — they remain origin URLs, so unsetting
 * MEDIA_CDN_BASE reverts everything with no migration.
 */

/** Vultr S3 endpoint. Not a bucket — the bucket is the first path segment. */
const ORIGIN_ENDPOINT = 'https://blr1.vultrobjects.com';

/**
 * Without this the Worker is an open proxy to every public bucket in the
 * region, served under our domain and our Cloudflare account.
 */
const ALLOWED_BUCKETS = new Set(['wrkt1bckt1', 'diet1bckt1']);

/**
 * Forwarded verbatim. An allowlist rather than passing the client's headers
 * through, so cookies and Authorization can never reach the bucket — a signed
 * request arriving by accident would behave differently from an anonymous one.
 */
const FORWARDED_REQUEST_HEADERS = [
  'range',
  'if-none-match',
  'if-modified-since',
  'if-range',
  'accept',
  'accept-encoding',
];

function notFound() {
  // Deliberately terse: which buckets exist is not something to advertise on a
  // rejected path.
  return new Response('Not Found', {
    status: 404,
    headers: { 'content-type': 'text/plain; charset=utf-8' },
  });
}

export default {
  async fetch(request) {
    // Read-only. The bucket credentials are not here, but an unbounded method
    // set still invites the Worker being treated as a write path.
    if (request.method !== 'GET' && request.method !== 'HEAD') {
      return new Response('Method Not Allowed', {
        status: 405,
        headers: { allow: 'GET, HEAD', 'content-type': 'text/plain; charset=utf-8' },
      });
    }

    const url = new URL(request.url);

    // `new URL` has already resolved any `..`, so a traversal attempt arrives
    // here as a different first segment and is caught by the allowlist below.
    // filter(Boolean) collapses `//` and the leading empty segment.
    const segments = url.pathname.split('/').filter(Boolean);
    const bucket = segments[0];
    const key = segments.slice(1).join('/');

    if (!bucket || !key || !ALLOWED_BUCKETS.has(bucket)) return notFound();

    // Segments are left percent-encoded exactly as they arrived; decoding and
    // re-encoding here would corrupt any key containing a reserved character.
    const originUrl = `${ORIGIN_ENDPOINT}/${bucket}/${key}${url.search}`;

    const headers = new Headers();
    for (const name of FORWARDED_REQUEST_HEADERS) {
      const value = request.headers.get(name);
      if (value !== null) headers.set(name, value);
    }

    return fetch(originUrl, {
      method: request.method,
      headers,
      redirect: 'follow',
      cf: {
        // Make it cacheable at the edge. No cacheTtl override: the bucket
        // already sends `public, max-age=31536000, immutable` and the keys are
        // uuid-addressed, so origin headers are both correct and stricter than
        // anything worth hardcoding here.
        cacheEverything: true,
      },
    });
  },
};
