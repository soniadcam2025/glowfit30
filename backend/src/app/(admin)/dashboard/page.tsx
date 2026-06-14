"use client";

import { useQuery } from "@tanstack/react-query";
import { adminService } from "@/services/admin.service";
import { Card } from "@/components/ui/card";
import { PageHeader } from "@/components/common/page-header";

type StatCardProps = { label: string; value: number | string; sub?: string; accent?: boolean };

function StatCard({ label, value, sub, accent }: StatCardProps) {
  return (
    <Card className="flex flex-col gap-1">
      <p className="text-xs font-medium text-slate-500 dark:text-slate-400">{label}</p>
      <p className={`text-3xl font-bold ${accent ? "text-pink-600" : "text-slate-800 dark:text-slate-100"}`}>
        {value}
      </p>
      {sub && <p className="text-xs text-slate-400">{sub}</p>}
    </Card>
  );
}

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["admin-stats"],
    queryFn: () => adminService.getStats(),
    refetchInterval: 60_000,
  });

  return (
    <div className="space-y-6">
      <PageHeader title="Dashboard" description="Live admin overview from production API." />

      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
          {Array.from({ length: 5 }).map((_, i) => (
            <Card key={i} className="h-24 animate-pulse bg-slate-100 dark:bg-slate-800" />
          ))}
        </div>
      ) : (
        <>
          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-slate-400">Users</p>
            <div className="grid gap-4 sm:grid-cols-3">
              <StatCard label="Total users" value={data?.totalUsers ?? 0} />
              <StatCard label="Active users" value={data?.activeUsers ?? 0} sub="not blocked" />
              <StatCard label="Blocked users" value={data?.blockedUsers ?? 0} />
            </div>
          </div>

          <div>
            <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-slate-400">Content & Activity</p>
            <div className="grid gap-4 sm:grid-cols-2">
              <StatCard
                label="Completions today"
                value={data?.todayCompletions ?? 0}
                sub="workouts finished today"
                accent
              />
              <StatCard
                label="Total workouts"
                value={data?.totalWorkouts ?? 0}
                sub="published plans"
              />
            </div>
          </div>

          {data?.generatedAt && (
            <p className="text-xs text-slate-400">
              Last updated: {new Date(data.generatedAt).toLocaleTimeString()} (refreshes every 60s)
            </p>
          )}
        </>
      )}
    </div>
  );
}
