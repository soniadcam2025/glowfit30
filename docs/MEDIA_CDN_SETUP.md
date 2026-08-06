# Putting media behind Cloudflare

The API side is finished and off by default. Setting one environment variable
switches every media url in every response to the CDN; unsetting it switches
them back. Nothing in the database changes either way, so this is reversible at
any time — including during an incident.

```
MEDIA_CDN_BASE=https://media.glowfit30.com
```

## What still needs your Cloudflare account

These steps need DNS and a Cloudflare login, so they are yours to run. Until
they are done, leave `MEDIA_CDN_BASE` unset — pointing it at a hostname that
does not resolve would break every image in the app.

### 1. DNS

Add a **proxied** (orange cloud) CNAME:

| Type | Name | Target | Proxy |
|---|---|---|---|
| CNAME | `media` | `wrkt1bckt1.blr1.vultrobjects.com` | **Proxied** |

Grey cloud means DNS-only — no caching, no CDN, and the whole exercise is
pointless. It must be orange.

### 2. Cache rule

Vultr already sends `Cache-Control: public, max-age=31536000, immutable` on
every object (verified — see `npm run media:verify`), so Cloudflare will honour
it without a rule. Add one anyway to be explicit and to survive an origin that
forgets the header:

- **When**: `Hostname equals media.glowfit30.com`
- **Then**: Cache eligibility → *Eligible for cache*, Edge TTL → *Respect
  origin*, Browser TTL → *Respect origin*

### 3. Bucket path

Cloudflare passes the path through unchanged, and the rewriter puts the bucket
name in the first path segment:

```
origin  https://wrkt1bckt1.blr1.vultrobjects.com/<uuid>/large.webp
cdn     https://media.glowfit30.com/wrkt1bckt1/<uuid>/large.webp
```

So the CNAME target has to be the **endpoint**, not a single bucket, and one
hostname then fronts both buckets. If you would rather point `media` at one
bucket directly, drop the bucket segment from `toCdnUrl` in
[`api/src/config/cdn.js`](../api/src/config/cdn.js) — but then you need a second
hostname for the diet bucket.

### ⚠️ Video and Cloudflare's terms

Cloudflare's free and Pro plans restrict serving a large volume of non-HTML
content — video specifically — through the CDN (ToS 2.8). Exercise clips at
~136kb are small, but this is worth knowing before the library grows. If it
becomes a problem the options are Cloudflare Stream, R2 (where egress through
Cloudflare is sanctioned and free), or leaving video on the bucket by rewriting
only image urls.

## Verifying it worked

```bash
cd api && npm run media:verify
```

Reports, against real stored objects:

- `Cache-Control` from the origin, and whether it has all three directives
- With the CDN on: `cf-cache-status` on a first and second request, `age`, and
  the first-byte time for each

`cf-cache-status: MISS` then `HIT` is the proof that caching is live. A `HIT`
that is not faster than the `MISS` usually means you are measuring from near the
origin — check from a different region before concluding anything.

## Current baseline

Measured from the dev machine before any CDN, so you have something to compare
against:

```
206  419ms  cache-control: public, max-age=31536000, immutable
206  199ms  cache-control: public, max-age=31536000, immutable
```
