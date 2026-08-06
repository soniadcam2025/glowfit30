"use client";

import * as React from "react";
import { useQuery } from "@tanstack/react-query";
import {
  AlertTriangle,
  Database,
  Gauge,
  HardDrive,
  Image as ImageIcon,
  PlayCircle,
} from "lucide-react";
import {
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { withRoleGuard } from "@/components/auth/with-role-guard";
import { PageHeader } from "@/components/common/page-header";
import { ErrorState, TableSkeleton } from "@/components/common/state";
import { StatCard } from "@/components/dashboard/stat-card";
import { Alert } from "@/components/ui/alert";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  formatBytes,
  formatMs,
  formatRatio,
  mediaMetricsService,
} from "@/services/media-metrics.service";

const RANGES = [7, 14, 30] as const;

function MediaMetricsPage() {
  const [days, setDays] = React.useState<number>(7);

  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["media-metrics", days],
    queryFn: () => mediaMetricsService.summary(days),
    // Devices flush in batches, so a shorter interval would mostly re-render
    // the same numbers.
    refetchInterval: 60_000,
  });

  const empty = !isLoading && !isError && (data?.totalEvents ?? 0) === 0;

  return (
    <div className="space-y-4">
      <PageHeader
        title="Media Performance"
        description="What images and video actually cost on real devices."
      />

      <div className="flex gap-2">
        {RANGES.map((r) => (
          <button
            key={r}
            type="button"
            onClick={() => setDays(r)}
            className={
              days === r
                ? "rounded-lg bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground"
                : "rounded-lg border border-border px-3 py-1.5 text-xs font-medium text-muted-foreground hover:border-primary/40"
            }
          >
            Last {r} days
          </button>
        ))}
      </div>

      {isError ? (
        <ErrorState
          message={error instanceof Error ? error.message : "Could not load metrics."}
          onRetry={() => void refetch()}
        />
      ) : isLoading ? (
        <TableSkeleton rows={6} />
      ) : empty ? (
        <Alert variant="info">
          No measurements yet. The app reports these as people use it — figures
          appear here once a build carrying media analytics has been in use.
        </Alert>
      ) : (
        data && (
          <>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <StatCard
                index={0}
                label="Image load (median)"
                value={formatMs(data.imageLoad.medianMs)}
                sub={`p95 ${formatMs(data.imageLoad.p95Ms)} · ${data.imageLoad.count.toLocaleString()} loads`}
                icon={ImageIcon}
                tone="primary"
              />
              <StatCard
                index={1}
                label="Video startup (median)"
                value={formatMs(data.videoStart.medianMs)}
                sub={`p95 ${formatMs(data.videoStart.p95Ms)} · ${data.videoStart.count.toLocaleString()} starts`}
                icon={PlayCircle}
                tone="primary"
              />
              <StatCard
                index={2}
                label="Cache hit ratio"
                value={formatRatio(data.cache.hitRatio)}
                sub={`${data.cache.hits.toLocaleString()} hits · ${data.cache.misses.toLocaleString()} misses`}
                icon={Gauge}
                tone={
                  data.cache.hitRatio !== null && data.cache.hitRatio < 0.5
                    ? "warning"
                    : "success"
                }
              />
              <StatCard
                index={3}
                label="Average media size"
                value={formatBytes(data.averageBytes)}
                sub={`${formatBytes(data.transferredBytes)} transferred`}
                icon={HardDrive}
              />
            </div>

            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <StatCard
                index={4}
                label="Buffer events"
                value={data.bufferEvents}
                sub="Times a clip stalled mid-playback"
                icon={AlertTriangle}
                tone={data.bufferEvents > 0 ? "warning" : "success"}
              />
              <StatCard
                index={5}
                label="Download failures"
                value={data.downloads.failed}
                sub={`${formatRatio(data.downloads.failureRate)} of ${(
                  data.downloads.ok + data.downloads.failed
                ).toLocaleString()} attempts`}
                icon={AlertTriangle}
                tone={data.downloads.failed > 0 ? "danger" : "success"}
              />
              <StatCard
                index={6}
                label="Video start failures"
                value={data.videoStartFailures}
                sub="Clip never produced a first frame"
                icon={PlayCircle}
                tone={data.videoStartFailures > 0 ? "danger" : "success"}
              />
              <StatCard
                index={7}
                label="Events recorded"
                value={data.totalEvents}
                sub={`Since ${new Date(data.since).toLocaleDateString()}`}
                icon={Database}
              />
            </div>

            <Card className="h-[340px]">
              <CardHeader className="p-0 pb-4">
                <CardTitle className="text-base">Load times by day</CardTitle>
                <CardDescription>
                  Average milliseconds to fetch an image, and to reach a video&apos;s
                  first frame.
                </CardDescription>
              </CardHeader>
              <ResponsiveContainer width="100%" height="78%">
                <LineChart data={data.series}>
                  <CartesianGrid strokeDasharray="3 3" opacity={0.25} />
                  <XAxis dataKey="day" fontSize={11} />
                  <YAxis fontSize={11} unit="ms" />
                  <Tooltip
                    formatter={(v, name) => [
                      formatMs(typeof v === "number" ? v : null),
                      name,
                    ]}
                  />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="imageMs"
                    name="Image"
                    stroke="#FF136B"
                    strokeWidth={2.5}
                    dot={false}
                    connectNulls
                  />
                  <Line
                    type="monotone"
                    dataKey="videoMs"
                    name="Video start"
                    stroke="#6366F1"
                    strokeWidth={2.5}
                    dot={false}
                    connectNulls
                  />
                </LineChart>
              </ResponsiveContainer>
            </Card>

            {data.topFailures.length > 0 && (
              <Card>
                <CardHeader className="p-0 pb-3">
                  <CardTitle className="text-base">Assets failing most often</CardTitle>
                  <CardDescription>
                    Repeated failures usually mean a missing object rather than a
                    bad connection.
                  </CardDescription>
                </CardHeader>
                <div className="divide-y divide-border">
                  {data.topFailures.map((f) => (
                    <div
                      key={f.url}
                      className="flex items-center justify-between gap-4 py-2.5"
                    >
                      <span className="break-all font-mono text-xs text-muted-foreground">
                        {f.url}
                      </span>
                      <span className="shrink-0 text-sm font-semibold text-danger">
                        {f.count}
                      </span>
                    </div>
                  ))}
                </div>
              </Card>
            )}
          </>
        )
      )}
    </div>
  );
}

export default withRoleGuard(MediaMetricsPage, ["super_admin"]);
