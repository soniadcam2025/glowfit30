# media.glowfit30.com Worker

Serves GlowFit images from Vultr Object Storage through Cloudflare's edge on
the **Free** plan. No paid feature is used and nothing here costs money.

## Why this exists

Vultr is Ceph RadosGW: it works out the bucket from the **Host header**.
Cloudflare forwards `Host: media.glowfit30.com`, so the gateway looks for a
bucket with that name and returns `NoSuchBucket`. DNS alone cannot fix that.

Overriding the Host header declaratively needs Cloudflare Origin Rules, which
this account's Free plan does not offer. A Worker sidesteps it entirely: it
requests `https://blr1.vultrobjects.com/<bucket>/<key>`, and `fetch` sets the
Host header to match the URL it is given. That one line is the whole fix.

```
Flutter / Admin
  -> https://media.glowfit30.com/wrkt1bckt1/<uuid>/large.webp
  -> Worker
  -> https://blr1.vultrobjects.com/wrkt1bckt1/<uuid>/large.webp   (Host: blr1…)
  -> 200 image/webp
```

## What it does and does not do

- **GET and HEAD only.** Anything else is 405.
- **Bucket allowlist**: `wrkt1bckt1`, `diet1bckt1`. Without it this is an open
  proxy to every public bucket in the region, under our domain.
- **Range passthrough**, so partial requests keep working.
- **Caching** via `cf: { cacheEverything: true }`, with no TTL override — the
  bucket already sends `public, max-age=31536000, immutable` and keys are
  uuid-addressed, so origin headers are correct and stricter than a hardcoded
  value.
- **No CORS headers.** Nothing needs them today (Android Flutter, and the admin
  loads images with `<img>`). Add them here if Flutter Web ever ships.
- **Images only.** Video urls are not rewritten by the API at all — see the
  video note in [`docs/MEDIA_CDN_SETUP.md`](../../docs/MEDIA_CDN_SETUP.md).

## Testing before deploying

Runs the real Worker source in Node against the real bucket, checks every
stored media url, and compares status, content-type and byte length against
origin:

```bash
cd api && node ../infra/cloudflare/test-worker-local.mjs
```

It needs the database (for the url list), so the SSH tunnel on `5433` must be
up. Edge caching is the one thing it cannot prove — `cf` is ignored outside
Cloudflare — so `cf-cache-status` is checked after deploy instead.

## Deploying

```bash
cd infra/cloudflare
npx wrangler deploy
```

`media` must exist as a **proxied** DNS record for the route to bind. Once the
Worker is live the record's target is irrelevant, since the Worker replaces the
origin.

## Verifying after deploy

```bash
curl -sI https://media.glowfit30.com/wrkt1bckt1/<uuid>/large.webp
curl -sI https://media.glowfit30.com/wrkt1bckt1/<uuid>/large.webp   # again
```

Expect `200`, `content-type: image/webp`, `cache-control: … immutable`, and
`cf-cache-status: MISS` then `HIT`. A `HIT` that is no faster than the `MISS`
usually just means you are close to the origin.

Only once that passes, set on the VPS:

```
MEDIA_CDN_BASE=https://media.glowfit30.com
```

## Rolling back

Unset `MEDIA_CDN_BASE` and restart the API. Every response returns to bucket
urls immediately: the database only ever stores origin urls, and rewriting
happens on the way out. Deleting the Worker is safe once that is done.
