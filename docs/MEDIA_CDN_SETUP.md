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
| CNAME | `media` | `blr1.vultrobjects.com` | **Proxied** |

Grey cloud means DNS-only — no caching, no CDN, and the whole exercise is
pointless. It must be orange.

The target is the **endpoint**, not a bucket. An earlier version of this table
said `wrkt1bckt1.blr1.vultrobjects.com`, which contradicted the bucket-path
section below and cannot work — see the next section for why. Once the Worker
is deployed the record's target stops mattering (the Worker replaces the origin
entirely), but the record must exist and be proxied for the route to bind.

### 1b. Why a Worker is required, not optional

Vultr Object Storage is Ceph RadosGW, which derives the bucket from the **Host
header**. Cloudflare forwards `Host: media.glowfit30.com`, so the gateway looks
for a bucket by that name and answers:

```xml
<Code>NoSuchBucket</Code><BucketName>media.glowfit30.com</BucketName>
```

DNS alone therefore cannot work, whatever the CNAME points at. The origin needs
`Host: blr1.vultrobjects.com`. Overriding a Host header declaratively is a
Cloudflare Origin Rules feature that is not available on this account's Free
plan — but a Worker gets it for nothing simply by fetching the endpoint URL.

See [`infra/cloudflare/`](../infra/cloudflare/) for the Worker, its route, and
a local test harness that runs the real source against the real bucket.

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

One hostname fronts both buckets — `wrkt1bckt1` (exercises) and `diet1bckt1`
(diet), both of which are in use. The Worker keeps the bucket segment and
allowlists exactly those two, so `toCdnUrl` needs no change.

### ⚠️ Video stays on the bucket

Cloudflare has retired the old ToS section 2.8, but the substance survives:
video and large files **hosted outside Cloudflare** are still restricted on
Free, Pro and Business, and Cloudflare may redirect or throttle content that
looks like a video CDN.

An exercise clip is **6.4 MB** — an earlier version of this document claimed
"~136kb", which was wrong by a factor of about fifty. So **only images are
routed through the CDN**; `videoObject`, `legacyVideo` and the legacy
`videoUrl` string in [`api/src/utils/media.js`](../api/src/utils/media.js) all
return origin urls deliberately. Posters are images and do go through the CDN.

If video ever needs a CDN, the options are Cloudflare Stream or R2 (where
egress through Cloudflare is sanctioned and free) — not this Worker.

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
