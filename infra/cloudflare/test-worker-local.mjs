/**
 * Runs the real Worker source in Node against the real Vultr origin.
 *
 * Node provides fetch/Request/Response, so `media-worker.js` can be imported
 * and invoked directly — this exercises the actual routing, allowlist and
 * header handling rather than a re-implementation of them. The `cf` option is
 * ignored outside Cloudflare, so edge caching is the one thing this cannot
 * prove; that needs a deployed Worker and is checked with cf-cache-status.
 *
 *   node infra/cloudflare/test-worker-local.mjs
 *
 * Reads every stored media url from the database and asserts the Worker serves
 * each one with the same status, content-type and byte length as the origin.
 */
import { pathToFileURL } from 'node:url';

const worker = (await import(new URL('media-worker.js', import.meta.url).href)).default;
const { prisma } = await import(
  pathToFileURL('f:/app/glowfit/api/src/database/prisma.js').href
);

const CDN_HOST = 'https://media.glowfit30.com';
const ENDPOINT_HOST = 'blr1.vultrobjects.com';

/** origin url -> the url the app would ask the CDN for. */
function toCdnUrl(url) {
  const parsed = new URL(url);
  const bucket = parsed.hostname.slice(0, -(ENDPOINT_HOST.length + 1));
  return `${CDN_HOST}/${bucket}${parsed.pathname}`;
}

async function collectStoredUrls() {
  const urls = new Set();
  const add = (u) => {
    if (typeof u === 'string' && u.includes(ENDPOINT_HOST)) urls.add(u);
  };

  for (const e of await prisma.exercise.findMany({
    select: { imageUrl: true, gifUrl: true, videoUrl: true },
  })) {
    add(e.imageUrl); add(e.gifUrl); add(e.videoUrl);
  }
  for (const a of await prisma.mediaAsset.findMany({
    select: {
      thumbUrl: true, mediumUrl: true, largeUrl: true,
      originalUrl: true, videoUrl: true, posterUrl: true,
    },
  })) {
    add(a.thumbUrl); add(a.mediumUrl); add(a.largeUrl);
    add(a.originalUrl); add(a.videoUrl); add(a.posterUrl);
  }
  for (const d of await prisma.workoutDay.findMany({ select: { imageUrl: true } })) add(d.imageUrl);
  for (const w of await prisma.workout.findMany({ select: { imageUrl: true } })) add(w.imageUrl);
  return [...urls];
}

const call = (url, init) => worker.fetch(new Request(url, init));

let failures = 0;
const fail = (label, detail) => { failures++; console.log(`FAIL  ${label} :: ${detail}`); };
const pass = (label) => console.log(`ok    ${label}`);

// ── Routing and safety ───────────────────────────────────────────────────────
console.log('--- routing and safety ---');

for (const [label, url, expected] of [
  ['rejects unknown bucket', `${CDN_HOST}/some-other-bucket/x/large.webp`, 404],
  ['rejects bucket with no key', `${CDN_HOST}/wrkt1bckt1`, 404],
  ['rejects empty path', `${CDN_HOST}/`, 404],
  ['rejects traversal out of bucket', `${CDN_HOST}/wrkt1bckt1/../evil/key.webp`, 404],
]) {
  const res = await call(url);
  res.status === expected ? pass(label) : fail(label, `expected ${expected}, got ${res.status}`);
}

for (const method of ['POST', 'PUT', 'DELETE']) {
  const res = await call(`${CDN_HOST}/wrkt1bckt1/x/large.webp`, { method });
  res.status === 405
    ? pass(`rejects ${method}`)
    : fail(`rejects ${method}`, `expected 405, got ${res.status}`);
}

// ── Every stored object ──────────────────────────────────────────────────────
console.log('\n--- stored media (worker vs origin) ---');
const stored = await collectStoredUrls();
console.log(`checking ${stored.length} stored urls`);

let checked = 0;
for (const originUrl of stored) {
  const cdnUrl = toCdnUrl(originUrl);
  const [viaWorker, viaOrigin] = await Promise.all([
    call(cdnUrl, { method: 'HEAD' }),
    fetch(originUrl, { method: 'HEAD' }),
  ]);

  const w = {
    status: viaWorker.status,
    type: viaWorker.headers.get('content-type'),
    len: viaWorker.headers.get('content-length'),
    cc: viaWorker.headers.get('cache-control'),
  };
  const o = {
    status: viaOrigin.status,
    type: viaOrigin.headers.get('content-type'),
    len: viaOrigin.headers.get('content-length'),
  };

  if (w.status !== 200) { fail(cdnUrl, `status ${w.status}`); continue; }
  if (w.status !== o.status || w.type !== o.type || w.len !== o.len) {
    fail(cdnUrl, `worker ${JSON.stringify(w)} != origin ${JSON.stringify(o)}`);
    continue;
  }
  if (!/immutable/.test(w.cc ?? '')) { fail(cdnUrl, `cache-control lost: ${w.cc}`); continue; }
  checked++;
}
console.log(`matched origin exactly: ${checked}/${stored.length}`);

// ── Range ────────────────────────────────────────────────────────────────────
console.log('\n--- range requests ---');
const video = stored.find((u) => u.endsWith('.mp4'));
if (video) {
  const res = await call(toCdnUrl(video), { headers: { range: 'bytes=0-1023' } });
  const cr = res.headers.get('content-range');
  res.status === 206 && res.headers.get('content-length') === '1024' && cr?.startsWith('bytes 0-1023/')
    ? pass(`206 partial content (${cr})`)
    : fail('range request', `status ${res.status}, len ${res.headers.get('content-length')}, range ${cr}`);
} else {
  console.log('skip  no video object stored');
}

// ── Body integrity ───────────────────────────────────────────────────────────
console.log('\n--- body integrity ---');
const image = stored.find((u) => u.endsWith('large.webp'));
if (image) {
  const [a, b] = await Promise.all([
    call(toCdnUrl(image)).then((r) => r.arrayBuffer()),
    fetch(image).then((r) => r.arrayBuffer()),
  ]);
  const same = a.byteLength === b.byteLength &&
    Buffer.from(a).equals(Buffer.from(b));
  same ? pass(`bytes identical (${a.byteLength})`) : fail('body integrity', 'bytes differ');
}

console.log(`\n${failures === 0 ? 'ALL PASSED' : failures + ' FAILURE(S)'}`);
process.exit(failures === 0 ? 0 : 1);
