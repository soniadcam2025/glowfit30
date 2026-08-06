/**
 * Checks what Object Storage — and the CDN, if configured — actually return.
 *
 *   node scripts/verify-media-headers.mjs
 *
 * Setting a header on upload is not evidence that it survives. This issues real
 * requests against real stored objects and reports what came back, including
 * the second request, which is the one that shows whether a CDN cached the
 * first.
 */
import { prisma } from '../src/database/prisma.js';
import { toCdnUrl, cdnEnabled } from '../src/config/cdn.js';

const EXPECTED = ['public', 'max-age=31536000', 'immutable'];

async function head(url) {
  const t0 = Date.now();
  const res = await fetch(url, { method: 'GET', headers: { Range: 'bytes=0-0' } });
  const ms = Date.now() - t0;
  const h = (n) => res.headers.get(n);
  return {
    status: res.status,
    ms,
    cacheControl: h('cache-control'),
    contentType: h('content-type'),
    etag: h('etag'),
    // Cloudflare reports HIT/MISS/EXPIRED here; absent means no CDN in front.
    cfCache: h('cf-cache-status'),
    cfRay: h('cf-ray'),
    age: h('age'),
  };
}

function verdict(cacheControl) {
  if (!cacheControl) return 'MISSING';
  const v = cacheControl.toLowerCase();
  const missing = EXPECTED.filter((e) => !v.includes(e));
  return missing.length === 0 ? 'OK' : `missing ${missing.join(', ')}`;
}

const rows = await prisma.mediaAsset.findMany({
  take: 4,
  orderBy: { createdAt: 'desc' },
  select: { thumbUrl: true, largeUrl: true, videoUrl: true, posterUrl: true },
});

const urls = [
  ...new Set(
    rows.flatMap((r) => [r.thumbUrl, r.largeUrl, r.videoUrl, r.posterUrl]).filter(Boolean),
  ),
].slice(0, 6);

if (urls.length === 0) {
  console.log('No media assets stored yet — upload one first.');
  await prisma.$disconnect();
  process.exit(0);
}

console.log(`CDN: ${cdnEnabled() ? 'configured' : 'not configured (serving from bucket)'}\n`);

console.log('── ORIGIN (Object Storage) ──');
for (const url of urls) {
  const r = await head(url);
  console.log(`  ${r.status}  ${String(r.ms).padStart(5)}ms  ${verdict(r.cacheControl).padEnd(10)}  ${r.contentType}`);
  console.log(`        cache-control: ${r.cacheControl ?? '(none)'}`);
  console.log(`        ${url}`);
}

if (cdnEnabled()) {
  console.log('\n── CDN (second request shows whether it cached) ──');
  for (const url of urls.slice(0, 3)) {
    const cdnUrl = toCdnUrl(url);
    const a = await head(cdnUrl);
    const b = await head(cdnUrl);
    console.log(`  ${cdnUrl}`);
    console.log(`        1st: ${a.status} ${String(a.ms).padStart(5)}ms  cf-cache=${a.cfCache ?? '-'}  age=${a.age ?? '-'}`);
    console.log(`        2nd: ${b.status} ${String(b.ms).padStart(5)}ms  cf-cache=${b.cfCache ?? '-'}  age=${b.age ?? '-'}`);
    console.log(`        cache-control: ${b.cacheControl ?? '(none)'}  ->  ${verdict(b.cacheControl)}`);
    if (a.ms > 0 && b.ms > 0) {
      console.log(`        first-byte change: ${a.ms}ms -> ${b.ms}ms (${Math.round((1 - b.ms / a.ms) * 100)}% faster)`);
    }
  }
} else {
  console.log('\nMEDIA_CDN_BASE is not set, so there is nothing to compare against.');
  console.log('Origin timings above are the current baseline.');
}

await prisma.$disconnect();
