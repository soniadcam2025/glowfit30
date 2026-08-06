import { sendError, sendSuccess } from '../../utils/response.js';
import { uploadImageSet, uploadVideoSet } from '../../config/storage.js';
import { prisma } from '../../database/prisma.js';

/**
 * Records the derivatives so a url can later be resolved to its other sizes.
 *
 * Never allowed to fail the request: the objects are already in the bucket and
 * the url the admin is waiting for is valid without this row. Losing the
 * metadata costs a backfill, losing the upload costs the admin their work.
 */
async function recordAsset(result) {
  if (!result.baseKey) return null;
  try {
    return await prisma.mediaAsset.create({
      data: {
        kind: 'image',
        baseKey: result.baseKey,
        bucket: result.bucket,
        mime: 'image/webp',
        blurhash: result.blurhash ?? null,
        originalUrl: result.originalUrl,
        originalMime: result.originalMime,
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
  } catch (e) {
    console.error('[uploads] failed to record media asset:', e.message);
    return null;
  }
}

export async function upload(req, res, next) {
  try {
    if (!req.file) {
      return sendError(res, 'No file uploaded', 400);
    }

    const folder = req.body.folder === 'diet' ? 'diet' : 'exercises';
    const result = await uploadImageSet(req.file.buffer, req.file.mimetype, folder);

    await recordAsset(result);

    // `url` is unchanged in name and meaning, so every existing caller — admin
    // forms, the Glow section editor — keeps working without being touched. The
    // rest is additive for clients that want to pick a size.
    return sendSuccess(
      res,
      {
        url: result.url,
        variants: result.variants,
        originalUrl: result.originalUrl ?? result.url,
        width: result.source?.width ?? null,
        height: result.source?.height ?? null,
      },
      'Uploaded',
    );
  } catch (e) {
    if (e.message?.includes('not configured')) {
      return sendError(res, e.message, 503);
    }
    next(e);
  }
}

export async function uploadVideo(req, res, next) {
  try {
    if (!req.file) {
      return sendError(res, 'No file uploaded', 400);
    }

    const result = await uploadVideoSet(req.file.buffer, req.file.mimetype, 'exercises');

    try {
      await prisma.mediaAsset.create({
        data: {
          kind: 'video',
          baseKey: result.baseKey,
          bucket: result.bucket,
          mime: 'video/mp4',
          blurhash: result.blurhash ?? null,
          videoUrl: result.url,
          posterUrl: result.posterUrl,
          durationSeconds: result.meta.durationSeconds,
          width: result.meta.width ?? null,
          height: result.meta.height ?? null,
          bytes: result.meta.bytes ?? null,
          originalUrl: result.originalUrl,
          originalMime: result.originalMime,
          // Poster sizes ride in the same row: it is an image like any other,
          // and a client picking a poster wants the same choice of widths.
          thumbUrl: result.poster.thumb?.url ?? null,
          thumbBytes: result.poster.thumb?.bytes ?? null,
          mediumUrl: result.poster.medium?.url ?? null,
          mediumBytes: result.poster.medium?.bytes ?? null,
          largeUrl: result.poster.large?.url ?? null,
          largeBytes: result.poster.large?.bytes ?? null,
        },
      });
    } catch (e) {
      console.error('[uploads] failed to record video asset:', e.message);
    }

    console.log(
      `[uploads] video ${result.action}` +
        (result.reasons.length ? ` (${result.reasons.join('; ')})` : '') +
        ` — ${Math.round(result.meta.originalBytes / 1024)}kb → ${Math.round(result.meta.bytes / 1024)}kb,` +
        ` faststart=${result.faststart}`,
    );

    // `url` unchanged for the admin; the rest is additive.
    return sendSuccess(
      res,
      {
        url: result.url,
        poster: result.posterUrl,
        posterVariants: result.poster,
        blurhash: result.blurhash,
        duration: result.meta.durationSeconds,
        width: result.meta.width,
        height: result.meta.height,
        size: result.meta.bytes,
        faststart: result.faststart,
      },
      'Uploaded',
    );
  } catch (e) {
    if (e.message?.includes('not configured')) {
      return sendError(res, e.message, 503);
    }
    // Validation failures are the admin's problem to fix, not a server fault.
    if (/Unsupported video type|no video stream|Not an MP4/.test(e.message ?? '')) {
      return sendError(res, e.message, 400);
    }
    next(e);
  }
}
