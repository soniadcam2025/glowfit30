import { api } from "@/services/api";
import type { ApiResponse } from "@/types";

export type Timings = {
  count: number;
  avgMs: number | null;
  medianMs: number | null;
  p95Ms: number | null;
};

export type MediaSeriesPoint = {
  day: string;
  imageMs: number | null;
  videoMs: number | null;
  /** 0–1, or null on a day with nothing measured. */
  cacheHitRatio: number | null;
  failures: number;
};

export type MediaMetrics = {
  days: number;
  since: string;
  totalEvents: number;
  imageLoad: Timings;
  videoStart: Timings;
  cache: { hits: number; misses: number; hitRatio: number | null };
  bufferEvents: number;
  downloads: { ok: number; failed: number; failureRate: number | null };
  videoStartFailures: number;
  /** Average transferred size of a cache miss. Null when nothing was fetched. */
  averageBytes: number | null;
  transferredBytes: number;
  series: MediaSeriesPoint[];
  topFailures: { url: string; count: number }[];
};

export const mediaMetricsService = {
  async summary(days = 7) {
    const { data } = await api.get<ApiResponse<MediaMetrics>>("/media-metrics/summary", {
      params: { days },
    });
    return data.data;
  },
};

export function formatBytes(bytes: number | null): string {
  if (bytes === null) return "—";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(2)} GB`;
}

export function formatMs(ms: number | null): string {
  if (ms === null) return "—";
  return ms < 1000 ? `${ms} ms` : `${(ms / 1000).toFixed(2)} s`;
}

/** Null renders as an em dash, never as 0% — "no data" is not "always missed". */
export function formatRatio(ratio: number | null): string {
  if (ratio === null) return "—";
  return `${Math.round(ratio * 100)}%`;
}
