import { spawn } from 'child_process';
import { randomUUID } from 'crypto';
import { mkdtemp, readFile, writeFile, rm } from 'fs/promises';
import { tmpdir } from 'os';
import path from 'path';
import ffmpegPath from 'ffmpeg-static';
import ffprobeStatic from 'ffprobe-static';

const FFPROBE = ffprobeStatic.path;

/**
 * Ceilings for a stored clip.
 *
 * These are exercise demos and 30-second tips played inside a phone-sized box,
 * not feature video. 1080p at ~2.5Mbps is already more than the screen can
 * show; anything above it is bytes the user waits for and never sees.
 */
const MAX_WIDTH = 1080;
const MAX_BITRATE_KBPS = 2500;
const TARGET_CRF = 23;

const run = (bin, args) =>
  new Promise((resolve, reject) => {
    const p = spawn(bin, args);
    let stderr = '';
    let stdout = '';
    p.stdout.on('data', (d) => (stdout += d));
    p.stderr.on('data', (d) => (stderr += d));
    p.on('error', reject);
    p.on('close', (code) =>
      code === 0
        ? resolve({ stdout, stderr })
        : reject(new Error(`${path.basename(bin)} exited ${code}: ${stderr.slice(-600)}`)),
    );
  });

/**
 * Whether the `moov` atom precedes `mdat`.
 *
 * This single fact decides whether playback starts immediately. `moov` holds
 * the index; a player cannot show frame one without it. Muxers write it last by
 * default, so the player must pull the whole file — the entire clip — before
 * anything appears. Moving it to the front is what `-movflags +faststart` does,
 * and it is the difference between "instant" and "a few seconds of nothing".
 *
 * Read by walking top-level MP4 boxes rather than shelling out: each is a
 * 4-byte big-endian size followed by a 4-byte type.
 */
export function hasFaststart(buffer) {
  let offset = 0;
  while (offset + 8 <= buffer.length) {
    const size = buffer.readUInt32BE(offset);
    const type = buffer.toString('ascii', offset + 4, offset + 8);

    if (type === 'moov') return true;
    if (type === 'mdat') return false;

    if (size === 0) break; // extends to EOF
    // size 1 means the real 64-bit size sits in the next 8 bytes.
    const advance = size === 1 ? Number(buffer.readBigUInt64BE(offset + 8)) : size;
    if (!Number.isFinite(advance) || advance < 8) break;
    offset += advance;
  }
  return false;
}

/** Container/stream facts, straight from ffprobe. */
export async function probe(file) {
  const { stdout } = await run(FFPROBE, [
    '-v', 'error',
    '-print_format', 'json',
    '-show_format',
    '-show_streams',
    file,
  ]);

  const info = JSON.parse(stdout);
  const video = info.streams?.find((s) => s.codec_type === 'video');
  const audio = info.streams?.find((s) => s.codec_type === 'audio');

  if (!video) throw new Error('File contains no video stream');

  // Rotation metadata means the displayed dimensions are swapped.
  const rotation = Math.abs(Number(video.side_data_list?.[0]?.rotation ?? video.tags?.rotate ?? 0));
  const turned = rotation === 90 || rotation === 270;

  return {
    durationSeconds: Number(info.format?.duration) || null,
    bitrateKbps: info.format?.bit_rate ? Math.round(Number(info.format.bit_rate) / 1000) : null,
    width: turned ? video.height : video.width,
    height: turned ? video.width : video.height,
    videoCodec: video.codec_name ?? null,
    audioCodec: audio?.codec_name ?? null,
    formats: (info.format?.format_name ?? '').split(','),
  };
}

/**
 * Decides what has to happen to a clip, and says why.
 *
 * A re-encode is expensive and lossy, so it is only worth it when the file is
 * actually too big or in the wrong codec. A file that is merely missing
 * faststart gets a stream copy instead: same bytes, same quality, seconds
 * rather than minutes, and it fixes the thing that matters most for startup.
 */
export function planFor(meta, faststart) {
  const reasons = [];
  if (meta.videoCodec !== 'h264') reasons.push(`codec is ${meta.videoCodec}, not h264`);
  if (meta.width > MAX_WIDTH) reasons.push(`${meta.width}px wide, over ${MAX_WIDTH}px`);
  if (meta.bitrateKbps && meta.bitrateKbps > MAX_BITRATE_KBPS) {
    reasons.push(`${meta.bitrateKbps}kbps, over ${MAX_BITRATE_KBPS}kbps`);
  }
  if (meta.audioCodec && meta.audioCodec !== 'aac') {
    reasons.push(`audio is ${meta.audioCodec}, not aac`);
  }

  if (reasons.length > 0) return { action: 'transcode', reasons };
  if (!faststart) return { action: 'remux', reasons: ['moov atom is behind mdat'] };
  return { action: 'copy', reasons: [] };
}

function transcodeArgs(input, output) {
  return [
    '-i', input,
    '-c:v', 'libx264',
    // baseline-friendly settings: high/4.0 plays on every Android and iOS
    // device in use, without giving up compression efficiency.
    '-profile:v', 'high',
    '-level', '4.0',
    '-preset', 'veryfast',
    '-crf', String(TARGET_CRF),
    '-maxrate', `${MAX_BITRATE_KBPS}k`,
    '-bufsize', `${MAX_BITRATE_KBPS * 2}k`,
    // Never upscale, and keep height even — libx264 rejects odd dimensions.
    '-vf', `scale='min(${MAX_WIDTH},iw)':-2`,
    '-pix_fmt', 'yuv420p',
    '-c:a', 'aac',
    '-b:a', '128k',
    '-movflags', '+faststart',
    '-y', output,
  ];
}

/**
 * Validates, optimises and extracts a poster frame from an uploaded clip.
 *
 * Works through temp files rather than pipes: ffmpeg has to seek to write
 * faststart, and a non-seekable stdout forces it into a second pass it cannot
 * do without a real file.
 */
export async function processVideo(buffer, mimetype) {
  if (mimetype !== 'video/mp4') {
    throw new Error(`Unsupported video type: ${mimetype}`);
  }

  const dir = await mkdtemp(path.join(tmpdir(), 'glowfit-video-'));
  const input = path.join(dir, `${randomUUID()}.mp4`);
  const output = path.join(dir, 'out.mp4');
  const posterFile = path.join(dir, 'poster.jpg');

  try {
    await writeFile(input, buffer);

    const meta = await probe(input);
    if (!meta.formats.includes('mp4')) {
      throw new Error(`Not an MP4 container (${meta.formats.join(',')})`);
    }

    const plan = planFor(meta, hasFaststart(buffer));

    if (plan.action === 'transcode') {
      await run(ffmpegPath, transcodeArgs(input, output));
    } else if (plan.action === 'remux') {
      // Stream copy — no re-encode, only the atom order changes.
      await run(ffmpegPath, ['-i', input, '-c', 'copy', '-movflags', '+faststart', '-y', output]);
    }

    const optimized = plan.action === 'copy' ? buffer : await readFile(output);

    // A frame one second in, falling back to the first frame for clips shorter
    // than that. Frame zero is often a fade from black and makes a poor poster.
    const seek = (meta.durationSeconds ?? 0) > 1.2 ? '1' : '0';
    await run(ffmpegPath, [
      '-ss', seek,
      '-i', plan.action === 'copy' ? input : output,
      '-frames:v', '1',
      '-q:v', '2',
      '-y', posterFile,
    ]);
    const poster = await readFile(posterFile);

    const finalMeta = plan.action === 'transcode' ? await probe(output) : meta;

    return {
      buffer: optimized,
      poster,
      action: plan.action,
      reasons: plan.reasons,
      // Proof rather than assumption: re-read the atom order of the bytes that
      // are actually going to be stored.
      faststart: hasFaststart(optimized),
      meta: {
        ...finalMeta,
        bytes: optimized.length,
        originalBytes: buffer.length,
      },
    };
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
}
