import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  ListObjectsV2Command,
} from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import { env } from './env.js';
import { buildVariants, isProcessable } from './images.js';
import { processVideo } from './video.js';
import { forgetMedia } from '../utils/media.js';
import { toOriginUrl } from './cdn.js';

let client = null;

function getClient() {
  if (client) return client;

  const { VULTR_S3_ENDPOINT, VULTR_S3_ACCESS_KEY, VULTR_S3_SECRET_KEY } = env;
  if (!VULTR_S3_ENDPOINT || !VULTR_S3_ACCESS_KEY || !VULTR_S3_SECRET_KEY) {
    throw new Error('Vultr Object Storage is not configured (VULTR_S3_* env vars missing)');
  }

  client = new S3Client({
    endpoint: VULTR_S3_ENDPOINT,
    region: env.VULTR_S3_REGION || 'us-east-1',
    credentials: {
      accessKeyId: VULTR_S3_ACCESS_KEY,
      secretAccessKey: VULTR_S3_SECRET_KEY,
    },
    forcePathStyle: false,
  });

  return client;
}

function bucketFor(folder) {
  const bucket = folder === 'diet' ? env.VULTR_S3_BUCKET_DIET : env.VULTR_S3_BUCKET_EXERCISES;
  if (!bucket) {
    throw new Error(`Vultr Object Storage bucket is not configured for "${folder}"`);
  }
  return bucket;
}

function publicUrlFor(bucket, key) {
  const endpoint = env.VULTR_S3_ENDPOINT.replace(/^https?:\/\//, '');
  return `https://${bucket}.${endpoint}/${key}`;
}

/**
 * File extension for a mime type.
 *
 * The subtype alone is not it: `image/svg+xml` would give `svg+xml`, and a `+`
 * in a key is legal but produces urls that look broken and encode awkwardly.
 */
function extFor(mimetype) {
  const sub = String(mimetype || '').split('/')[1] || 'bin';
  const clean = sub.split('+')[0].toLowerCase();
  return clean === 'jpeg' ? 'jpg' : clean;
}

export async function uploadFile(buffer, mimetype, folder = 'exercises') {
  const bucket = bucketFor(folder);
  const key = `${randomUUID()}.${extFor(mimetype)}`;

  await getClient().send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: mimetype,
      ACL: 'public-read',
      // The key is a uuid, so this object can never change. Letting caches keep
      // it indefinitely saves a revalidation round trip on every view.
      CacheControl: 'public, max-age=31536000, immutable',
    }),
  );

  return publicUrlFor(bucket, key);
}

function parsePublicUrl(rawUrl) {
  // A cdn url has to be mapped back first, or the hostname parses into a
  // bucket that does not exist and the delete quietly does nothing.
  const url = toOriginUrl(rawUrl);
  try {
    const { hostname, pathname } = new URL(url);
    const bucket = hostname.split('.')[0];
    const key = decodeURIComponent(pathname.replace(/^\//, ''));
    if (!bucket || !key) return null;
    return { bucket, key };
  } catch {
    return null;
  }
}

/**
 * Uploads an image and its WebP derivatives under one key prefix.
 *
 * Everything for an image lives under `<uuid>/`: the untouched original plus a
 * thumb, medium and large. Keeping the original is what makes the sizes
 * reversible — quality, widths and even the output format can be changed later
 * by re-running the pipeline, which is impossible once the source is discarded.
 *
 * Formats sharp must not touch (SVG, animated GIF) fall through to a plain
 * single-object upload, so an admin uploading one still gets a working url.
 */
export async function uploadImageSet(buffer, mimetype, folder = 'exercises') {
  if (!isProcessable(mimetype)) {
    return {
      url: await uploadFile(buffer, mimetype, folder),
      bucket: bucketFor(folder),
      baseKey: null,
      variants: null,
      source: null,
    };
  }

  const bucket = bucketFor(folder);
  const baseKey = randomUUID();
  const ext = extFor(mimetype);
  const client = getClient();

  const put = (key, body, contentType) =>
    client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
        ACL: 'public-read',
        // Keys are uuid-based and their contents never change, so anything that
        // fetches one may keep it forever. Without this every CDN and device
        // cache revalidates on each view, which is most of the latency this
        // pipeline exists to remove.
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );

  const { variants, source, blurhash } = await buildVariants(buffer);

  const originalKey = `${baseKey}/original.${ext}`;
  await Promise.all([
    put(originalKey, buffer, mimetype),
    ...variants.map((v) => put(`${baseKey}/${v.name}.webp`, v.buffer, 'image/webp')),
  ]);

  const built = {};
  for (const v of variants) {
    built[v.name] = {
      url: publicUrlFor(bucket, `${baseKey}/${v.name}.webp`),
      width: v.width,
      height: v.height,
      bytes: v.bytes,
    };
  }

  return {
    // `url` stays the top-level field every existing caller reads. It points at
    // `large` rather than the original: it is the closest visual equivalent of
    // what an upload used to return, so nothing downstream has to change.
    url: built.large.url,
    bucket,
    baseKey,
    originalUrl: publicUrlFor(bucket, originalKey),
    originalMime: mimetype,
    variants: built,
    blurhash,
    source,
  };
}

/**
 * Optimises a clip and uploads it with its poster frame.
 *
 * The poster goes through the image pipeline rather than being stored as the
 * raw JPEG ffmpeg emits: it is an image, so it gets the same WebP sizes and
 * blurhash as any other, and the client can show the still instantly while the
 * video opens.
 *
 * The source is discarded unless KEEP_ORIGINAL_VIDEO is set. Unlike an image —
 * where the original is the only way to regenerate sizes — the optimised clip
 * is a complete, playable file, and a second copy of every video is the largest
 * thing that would ever sit in this bucket.
 */
export async function uploadVideoSet(buffer, mimetype, folder = 'exercises') {
  const bucket = bucketFor(folder);
  const baseKey = randomUUID();
  const client = getClient();

  const put = (key, body, contentType) =>
    client.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
        ACL: 'public-read',
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );

  const processed = await processVideo(buffer, mimetype);
  const { variants: posterVariants, blurhash } = await buildVariants(processed.poster);

  const videoKey = `${baseKey}/video.mp4`;
  const uploads = [
    put(videoKey, processed.buffer, 'video/mp4'),
    ...posterVariants.map((v) => put(`${baseKey}/poster-${v.name}.webp`, v.buffer, 'image/webp')),
  ];

  const keepOriginal = String(env.KEEP_ORIGINAL_VIDEO ?? '').toLowerCase() === 'true';
  const originalKey = keepOriginal ? `${baseKey}/original.mp4` : null;
  if (originalKey) uploads.push(put(originalKey, buffer, mimetype));

  await Promise.all(uploads);

  const poster = {};
  for (const v of posterVariants) {
    poster[v.name] = {
      url: publicUrlFor(bucket, `${baseKey}/poster-${v.name}.webp`),
      width: v.width,
      height: v.height,
      bytes: v.bytes,
    };
  }

  return {
    // Same contract as an image upload: `url` is the thing to store on the row.
    url: publicUrlFor(bucket, videoKey),
    bucket,
    baseKey,
    posterUrl: poster.large.url,
    poster,
    blurhash,
    originalUrl: originalKey ? publicUrlFor(bucket, originalKey) : null,
    originalMime: mimetype,
    action: processed.action,
    reasons: processed.reasons,
    faststart: processed.faststart,
    meta: processed.meta,
  };
}

/** Downloads an object back into memory. Used by the backfill. */
export async function getObjectBuffer(url) {
  const parsed = parsePublicUrl(url);
  if (!parsed) throw new Error(`Not a storage url: ${url}`);

  const res = await getClient().send(
    new GetObjectCommand({ Bucket: parsed.bucket, Key: parsed.key }),
  );

  const chunks = [];
  for await (const chunk of res.Body) chunks.push(chunk);
  return {
    buffer: Buffer.concat(chunks),
    contentType: res.ContentType || 'application/octet-stream',
  };
}

/** `<uuid>/name.ext` — a key written by [uploadImageSet]. */
const VARIANT_KEY = /^([0-9a-f-]{36})\/[^/]+$/i;

/**
 * Deletes an object, and its siblings when it belongs to a variant set.
 *
 * Callers hold a single url — whichever one was written to the row — and have
 * no idea the other three exist. Deleting only that one would leave the
 * original and two derivatives in the bucket with nothing referencing them,
 * paying storage forever. The prefix is listed rather than assumed so the
 * original's extension does not have to be guessed.
 */
export async function deleteFile(url) {
  if (!url) return;
  const parsed = parsePublicUrl(url);
  if (!parsed) return;

  const client = getClient();
  const match = parsed.key.match(VARIANT_KEY);

  if (!match) {
    await client.send(
      new DeleteObjectCommand({ Bucket: parsed.bucket, Key: parsed.key }),
    );
    return;
  }

  const listed = await client.send(
    new ListObjectsV2Command({ Bucket: parsed.bucket, Prefix: `${match[1]}/` }),
  );

  const keys = (listed.Contents ?? []).map((o) => o.Key);
  // Fall back to the one key we were given if the listing came back empty, so a
  // permissions problem on ListBucket cannot turn a delete into a silent no-op.
  const targets = keys.length > 0 ? keys : [parsed.key];

  await Promise.all(
    targets.map((Key) =>
      client.send(new DeleteObjectCommand({ Bucket: parsed.bucket, Key })),
    ),
  );
}

export async function deleteFiles(urls) {
  const unique = [...new Set((urls || []).filter(Boolean))];
  // Drop them from the response-expansion cache first, so nothing can serve a
  // resolved object for media that is about to stop existing.
  forgetMedia(unique);
  await Promise.all(
    unique.map((url) =>
      deleteFile(url).catch((err) => {
        console.error(`[storage] failed to delete ${url}:`, err.message);
      }),
    ),
  );
}
