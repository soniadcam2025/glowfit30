import sharp from 'sharp';
import { encode as encodeBlurhash } from 'blurhash';

/**
 * Derivative sizes, widest first.
 *
 * Widths, not heights: every image in the app is laid out by its width — cards,
 * heroes, thumbnails — and constraining one dimension keeps the aspect ratio.
 */
export const VARIANTS = [
  { name: 'large', width: 1200 },
  { name: 'medium', width: 800 },
  { name: 'thumb', width: 400 },
];

export const VARIANT_NAMES = VARIANTS.map((v) => v.name);

/** WebP quality. 82 is the point where artefacts stop being visible on photos. */
const WEBP_QUALITY = 82;

/**
 * Formats that must not be re-encoded.
 *
 * SVG is vector — rasterising it to 1200px throws away the reason to use it.
 * GIF is usually animated here (exercise loops) and sharp would flatten it to a
 * single frame, so it is passed through untouched rather than silently broken.
 */
const PASSTHROUGH = new Set(['image/svg+xml', 'image/gif']);

export function isProcessable(mimetype) {
  return Boolean(mimetype?.startsWith('image/')) && !PASSTHROUGH.has(mimetype);
}

/**
 * A ~30-character hash the client renders as a blurred approximation.
 *
 * This is what makes a screen feel instant: the shape and colours of the image
 * are already in the JSON the client parsed, so there is something correct to
 * draw at frame one instead of a grey box. Even a cached image has to be read
 * and decoded; the hash has nothing to wait for.
 *
 * Encoded from a 32px thumbnail because the algorithm only keeps a handful of
 * frequency components — feeding it more pixels costs time and changes nothing.
 */
async function blurhashFor(buffer) {
  try {
    const { data, info } = await sharp(buffer, { failOn: 'none' })
      .rotate()
      .raw()
      .ensureAlpha()
      .resize(32, 32, { fit: 'inside' })
      .toBuffer({ resolveWithObject: true });

    return encodeBlurhash(
      new Uint8ClampedArray(data),
      info.width,
      info.height,
      4,
      3,
    );
  } catch (e) {
    // A placeholder is a nicety. Never fail an upload over one.
    console.error('[images] blurhash failed:', e.message);
    return null;
  }
}

/**
 * Generates the WebP derivatives for one image.
 *
 * Returns the source dimensions alongside the variants: the client needs the
 * aspect ratio to reserve space before the bytes arrive, which is what stops a
 * list from jumping as images load.
 *
 * Never upscales. A 300px source produces a 300px "large" — inventing pixels
 * costs bytes and adds nothing, and `withoutEnlargement` keeps the file honest
 * about what it actually contains.
 *
 * Orientation is baked in with `rotate()` before resizing. Phone cameras record
 * rotation as EXIF metadata, and stripping that metadata without applying it
 * first is how portrait photos end up sideways.
 */
export async function buildVariants(buffer) {
  const image = sharp(buffer, { failOn: 'none' }).rotate();
  const meta = await image.metadata();

  // After rotate() the reported width/height are pre-rotation, so swap them for
  // quarter turns to describe what the output will actually be.
  const turned = meta.orientation >= 5 && meta.orientation <= 8;
  const width = turned ? meta.height : meta.width;
  const height = turned ? meta.width : meta.height;

  const blurhash = await blurhashFor(buffer);

  const variants = await Promise.all(
    VARIANTS.map(async (v) => {
      const out = await sharp(buffer, { failOn: 'none' })
        .rotate()
        .resize({ width: v.width, withoutEnlargement: true })
        .webp({ quality: WEBP_QUALITY })
        .toBuffer({ resolveWithObject: true });

      return {
        name: v.name,
        buffer: out.data,
        width: out.info.width,
        height: out.info.height,
        bytes: out.info.size,
      };
    }),
  );

  return {
    variants,
    blurhash,
    source: {
      width: width ?? null,
      height: height ?? null,
      format: meta.format ?? null,
      bytes: buffer.length,
    },
  };
}
