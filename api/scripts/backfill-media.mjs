/**
 * Generates WebP derivatives for media uploaded before the image pipeline.
 *
 *   node scripts/backfill-media.mjs            # dry run, reports what it would do
 *   node scripts/backfill-media.mjs --apply    # process and rewrite references
 *   node scripts/backfill-media.mjs --apply --limit 20
 *
 * Dry run is the default because this rewrites urls in content tables. Run it,
 * read the report, then run it again with --apply.
 *
 * Safe to re-run. Every processed url gets a MediaAsset row keyed by its old
 * url, so a second pass reuses that set instead of regenerating it — an
 * interrupted run resumes rather than duplicating objects in the bucket.
 *
 * Old objects are never deleted. Until the app has been seen working against
 * the new urls, the pre-pipeline file is the only copy of that image; freeing
 * it is a separate, deliberate step once MediaAsset.legacyUrl says what is safe
 * to remove.
 */
import { prisma } from '../src/database/prisma.js';
import { getObjectBuffer, uploadImageSet, uploadVideoSet } from '../src/config/storage.js';
import { buildVariants, isProcessable } from '../src/config/images.js';

const APPLY = process.argv.includes('--apply');
const LIMIT = (() => {
  const i = process.argv.indexOf('--limit');
  return i === -1 ? Infinity : Number(process.argv[i + 1]) || Infinity;
})();

/**
 * Video columns, handled separately from images.
 *
 * A clip is not resized into three widths; it is remuxed or transcoded so its
 * moov atom sits before the media data, and a poster frame is generated. Kept
 * apart from [COLUMNS] because the two pipelines share nothing but the shape of
 * the loop around them.
 */
const VIDEO_COLUMNS = [['exercise', ['videoUrl']]];

/** Plain image url columns. `videoUrl` is handled by [VIDEO_COLUMNS]. */
const COLUMNS = [
  ['user', ['photoUrl']],
  ['workout', ['imageUrl']],
  ['workoutDay', ['imageUrl']],
  // gifUrl is included: an exported still is common there, and animated GIFs
  // are rejected by isProcessable and left alone.
  ['exercise', ['imageUrl', 'gifUrl']],
  ['dietPlan', ['imageUrl']],
  ['workoutLibraryCategory', ['heroImageUrl', 'cardImageUrl']],
  ['workoutLibraryItem', ['heroImageUrl']],
  ['workoutLibraryExercise', ['imageUrl']],
  ['glowCategory', ['heroImageUrl']],
  ['beautyPost', ['imageUrl']],
  ['glowShort', ['imageUrl']],
];

/** Json columns holding media inside arbitrarily shaped cards. */
const JSON_COLUMNS = [
  ['dietPlanDay', 'meals'],
  ['beautyPost', 'sections'],
  ['glowShort', 'sections'],
];

/** Already written by the pipeline: `<uuid>/name.ext`. */
const VARIANT_KEY = /\/[0-9a-f-]{36}\/[^/]+$/i;

function isCandidate(url) {
  return (
    typeof url === 'string' &&
    url.startsWith('http') &&
    !VARIANT_KEY.test(url) &&
    // Google/Firebase avatars and other off-bucket urls are not ours to rewrite.
    /\.vultrobjects\.com\//.test(url)
  );
}

/** Collects every imageUrl/videoUrl string in a Json column. */
function walkJson(node, onFound) {
  if (Array.isArray(node)) return node.forEach((n) => walkJson(n, onFound));
  if (node && typeof node === 'object') {
    for (const [k, v] of Object.entries(node)) {
      if (k === 'imageUrl' && typeof v === 'string') onFound(v);
      else walkJson(v, onFound);
    }
  }
}

/** Returns a copy with every imageUrl found in `map` replaced. */
function rewriteJson(node, map) {
  if (Array.isArray(node)) return node.map((n) => rewriteJson(n, map));
  if (node && typeof node === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(node)) {
      out[k] = k === 'imageUrl' && typeof v === 'string' && map.has(v)
        ? map.get(v)
        : rewriteJson(v, map);
    }
    return out;
  }
  return node;
}

async function collect() {
  const urls = new Set();

  for (const [model, fields] of COLUMNS) {
    const rows = await prisma[model].findMany({
      select: Object.fromEntries(fields.map((f) => [f, true])),
    });
    for (const row of rows) {
      for (const f of fields) if (isCandidate(row[f])) urls.add(row[f]);
    }
  }

  for (const [model, field] of JSON_COLUMNS) {
    const rows = await prisma[model].findMany({ select: { [field]: true } });
    for (const row of rows) {
      walkJson(row[field], (u) => {
        if (isCandidate(u)) urls.add(u);
      });
    }
  }

  return [...urls];
}

/**
 * Downloads, re-encodes and uploads one legacy url. Returns its new large url.
 *
 * Not named `process` — a module-scope function declaration by that name
 * shadows the global and `process.argv` stops existing.
 */
async function processUrl(url) {
  const existing = await prisma.mediaAsset.findUnique({ where: { legacyUrl: url } });
  if (existing?.largeUrl) return { url: existing.largeUrl, reused: true };

  const { buffer, contentType } = await getObjectBuffer(url);
  if (!isProcessable(contentType)) return { skipped: `not processable (${contentType})` };

  const folder = url.includes('diet') ? 'diet' : 'exercises';
  const result = await uploadImageSet(buffer, contentType, folder);

  await prisma.mediaAsset.create({
    data: {
      kind: 'image',
      baseKey: result.baseKey,
      bucket: result.bucket,
      mime: 'image/webp',
      blurhash: result.blurhash ?? null,
      originalUrl: result.originalUrl,
      originalMime: result.originalMime,
      legacyUrl: url,
      width: result.source?.width ?? null,
      height: result.source?.height ?? null,
      bytes: result.source?.bytes ?? null,
      thumbUrl: result.variants.thumb?.url ?? null,
      thumbBytes: result.variants.thumb?.bytes ?? null,
      mediumUrl: result.variants.medium?.url ?? null,
      mediumBytes: result.variants.medium?.bytes ?? null,
      largeUrl: result.variants.large?.url ?? null,
      largeBytes: result.variants.large?.bytes ?? null,
    },
  });

  return {
    url: result.url,
    before: buffer.length,
    after: result.variants.large.bytes,
  };
}

async function collectVideos() {
  const urls = new Set();
  for (const [model, fields] of VIDEO_COLUMNS) {
    const rows = await prisma[model].findMany({
      select: Object.fromEntries(fields.map((f) => [f, true])),
    });
    for (const row of rows) {
      for (const f of fields) if (isCandidate(row[f])) urls.add(row[f]);
    }
  }
  return [...urls];
}

/**
 * Remuxes/transcodes one legacy clip and generates its poster.
 *
 * Returns the new video url. The pre-pipeline object is left in place, so if a
 * transcode ever turns out to have degraded a clip the old file is still there
 * and `MediaAsset.legacyUrl` says which one it was.
 */
async function processVideoUrl(url) {
  const existing = await prisma.mediaAsset.findUnique({ where: { legacyUrl: url } });
  if (existing?.videoUrl) return { url: existing.videoUrl, reused: true };

  const { buffer, contentType } = await getObjectBuffer(url);
  // The stored content type is whatever the old upload path happened to set;
  // the extension is the more reliable signal for these pre-pipeline objects.
  const mime = contentType === 'video/mp4' || url.toLowerCase().endsWith('.mp4')
    ? 'video/mp4'
    : contentType;
  if (mime !== 'video/mp4') return { skipped: `not an mp4 (${contentType})` };

  const folder = url.includes('diet') ? 'diet' : 'exercises';
  const result = await uploadVideoSet(buffer, mime, folder);

  await prisma.mediaAsset.create({
    data: {
      kind: 'video',
      baseKey: result.baseKey,
      bucket: result.bucket,
      mime: 'video/mp4',
      blurhash: result.blurhash ?? null,
      originalUrl: result.originalUrl,
      originalMime: result.originalMime,
      legacyUrl: url,
      videoUrl: result.url,
      posterUrl: result.posterUrl,
      durationSeconds: result.meta?.durationSeconds ?? null,
      width: result.meta?.width ?? null,
      height: result.meta?.height ?? null,
      bytes: result.meta?.bytes ?? null,
      thumbUrl: result.poster?.thumb?.url ?? null,
      thumbBytes: result.poster?.thumb?.bytes ?? null,
      mediumUrl: result.poster?.medium?.url ?? null,
      mediumBytes: result.poster?.medium?.bytes ?? null,
      largeUrl: result.poster?.large?.url ?? null,
      largeBytes: result.poster?.large?.bytes ?? null,
    },
  });

  return {
    url: result.url,
    before: buffer.length,
    after: result.meta?.bytes ?? buffer.length,
    action: result.action,
    faststart: result.faststart,
    duration: result.meta?.durationSeconds,
  };
}

async function rewriteVideos(map) {
  let updated = 0;
  for (const [model, fields] of VIDEO_COLUMNS) {
    for (const f of fields) {
      for (const [from, to] of map) {
        const { count } = await prisma[model].updateMany({
          where: { [f]: from },
          data: { [f]: to },
        });
        updated += count;
      }
    }
  }
  return updated;
}

async function rewrite(map) {
  let updated = 0;

  for (const [model, fields] of COLUMNS) {
    for (const f of fields) {
      for (const [from, to] of map) {
        const { count } = await prisma[model].updateMany({
          where: { [f]: from },
          data: { [f]: to },
        });
        updated += count;
      }
    }
  }

  for (const [model, field] of JSON_COLUMNS) {
    const rows = await prisma[model].findMany({ select: { id: true, [field]: true } });
    for (const row of rows) {
      let touched = false;
      walkJson(row[field], (u) => {
        if (map.has(u)) touched = true;
      });
      if (!touched) continue;

      await prisma[model].update({
        where: { id: row.id },
        data: { [field]: rewriteJson(row[field], map) },
      });
      updated += 1;
    }
  }

  return updated;
}

const kb = (n) => `${Math.round(n / 1024)}kb`;

/**
 * Fills in blurhash on rows created before it existed.
 *
 * Encoded from the stored `thumb` rather than the original: it is already the
 * smallest file, and the hash only keeps a handful of frequency components so
 * a 400px source and a 4000px one produce the same result.
 */
async function refreshBlurhashes() {
  const rows = await prisma.mediaAsset.findMany({
    where: { blurhash: null },
    select: { id: true, thumbUrl: true, largeUrl: true },
  });

  console.log(`${rows.length} asset(s) missing a blurhash.\n`);
  if (rows.length === 0 || !APPLY) {
    if (rows.length > 0) console.log('Nothing was changed. Pass --apply to write.');
    return;
  }

  let done = 0;
  for (const row of rows) {
    const src = row.thumbUrl ?? row.largeUrl;
    if (!src) continue;
    try {
      const { buffer } = await getObjectBuffer(src);
      const { blurhash } = await buildVariants(buffer);
      if (!blurhash) continue;
      await prisma.mediaAsset.update({ where: { id: row.id }, data: { blurhash } });
      done += 1;
      console.log(`  ok  ${blurhash}  ${src}`);
    } catch (e) {
      console.error(`  FAIL ${src}\n       ${e.message}`);
    }
  }
  console.log(`\nblurhash written for ${done} asset(s).`);
}

async function main() {
  if (process.argv.includes('--blurhash-only')) {
    console.log(APPLY ? '── APPLYING (blurhash) ──' : '── DRY RUN (blurhash) ──');
    return refreshBlurhashes();
  }

  console.log(APPLY ? '── APPLYING ──' : '── DRY RUN (pass --apply to write) ──');

  const urls = await collect();
  const videoUrls = await collectVideos();
  console.log(`${urls.length} pre-pipeline image url(s) referenced by content.`);
  console.log(`${videoUrls.length} pre-pipeline video url(s) referenced by content.\n`);
  if (urls.length === 0 && videoUrls.length === 0) return;

  if (!APPLY) {
    for (const u of urls.slice(0, 40)) console.log(`  would process  ${u}`);
    if (urls.length > 40) console.log(`  … and ${urls.length - 40} more`);
    for (const u of videoUrls.slice(0, 40)) console.log(`  would process  (video) ${u}`);
    console.log('\nNothing was changed.');
    return;
  }

  const map = new Map();
  let before = 0;
  let after = 0;
  let failed = 0;

  for (const [i, url] of urls.slice(0, LIMIT).entries()) {
    const label = `[${i + 1}/${Math.min(urls.length, LIMIT)}]`;
    try {
      const r = await processUrl(url);
      if (r.skipped) {
        console.log(`${label} skip   ${r.skipped}  ${url}`);
        continue;
      }
      map.set(url, r.url);
      if (r.reused) {
        console.log(`${label} reuse  ${url}`);
      } else {
        before += r.before;
        after += r.after;
        console.log(`${label} ok     ${kb(r.before)} → ${kb(r.after)}  ${url}`);
      }
    } catch (e) {
      failed += 1;
      console.error(`${label} FAIL   ${url}\n         ${e.message}`);
    }
  }

  const videoMap = new Map();
  for (const [i, url] of videoUrls.slice(0, LIMIT).entries()) {
    const label = `[video ${i + 1}/${Math.min(videoUrls.length, LIMIT)}]`;
    try {
      const r = await processVideoUrl(url);
      if (r.skipped) {
        console.log(`${label} skip   ${r.skipped}  ${url}`);
        continue;
      }
      videoMap.set(url, r.url);
      if (r.reused) {
        console.log(`${label} reuse  ${url}`);
      } else {
        before += r.before;
        after += r.after;
        console.log(
          `${label} ok     ${r.action}  ${kb(r.before)} → ${kb(r.after)}  ` +
            `faststart=${r.faststart}  ${Math.round(r.duration ?? 0)}s  ${url}`,
        );
      }
    } catch (e) {
      failed += 1;
      console.error(`${label} FAIL   ${url}\n         ${e.message}`);
    }
  }

  const updated = (await rewrite(map)) + (await rewriteVideos(videoMap));

  console.log('\n── summary ──');
  console.log(`images processed: ${map.size}`);
  console.log(`videos processed: ${videoMap.size}`);
  console.log(`failed:         ${failed}`);
  console.log(`rows rewritten: ${updated}`);
  if (before > 0) {
    console.log(`largest size:   ${kb(before)} → ${kb(after)}  (${Math.round((1 - after / before) * 100)}% smaller)`);
  }
  console.log('\nOld objects were left in place. Delete them only after the app');
  console.log('has been verified against the new urls.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
