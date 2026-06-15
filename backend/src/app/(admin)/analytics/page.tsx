"use client";

import { useQuery } from "@tanstack/react-query";
import { adminService } from "@/services/admin.service";
import { PageHeader } from "@/components/common/page-header";
import { Card } from "@/components/ui/card";
import { ChartCard } from "@/components/dashboard/chart-card";

type StatCardProps = {
  label: string;
  value: number | string;
  sub?: string;
  accent?: "pink" | "blue" | "green";
};

function StatCard({ label, value, sub, accent }: StatCardProps) {
  const color =
    accent === "pink"
      ? "text-pink-600"
      : accent === "blue"
        ? "text-blue-600"
        : accent === "green"
          ? "text-green-600"
          : "text-slate-800 dark:text-slate-100";
  return (
    <Card className="flex flex-col gap-1">
      <p className="text-xs font-medium text-slate-500 dark:text-slate-400">{label}</p>
      <p className={`text-3xl font-bold ${color}`}>{value}</p>
      {sub && <p className="text-xs text-slate-400">{sub}</p>}
    </Card>
  );
}

function shortDate(iso: string) {
  const d = new Date(iso);
  return `${d.getMonth() + 1}/${d.getDate()}`;
}

export default function AnalyticsPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["admin-chart-data"],
    queryFn: () => adminService.getChartData(),
    refetchInterval: 5 * 60_000,
  });

  const signupsChartData = (data?.signupsPerDay ?? []).map((p) => ({
    name: shortDate(p.date),
    count: p.count,
  }));

  const completionsChartData = (data?.completionsPerDay ?? []).map((p) => ({
    name: shortDate(p.date),
    count: p.count,
  }));

  return (
    <div className="space-y-6">
      <PageHeader
        title="Analytics"
        description="Signups, workout completions, and active users over time."
      />

      {/* Stat cards */}
      {isLoading ? (
        <div className="grid gap-4 sm:grid-cols-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Card key={i} className="h-24 animate-pulse bg-slate-100 dark:bg-slate-800" />
          ))}
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-3">
          <StatCard
            label="New signups (7 days)"
            value={data?.totalSignupsThisWeek ?? 0}
            sub="users registered this week"
            accent="blue"
          />
          <StatCard
            label="Completions (7 days)"
            value={data?.totalCompletionsThisWeek ?? 0}
            sub="workout sessions logged this week"
            accent="pink"
          />
          <StatCard
            label="Active users (7 days)"
            value={data?.activeUsersThisWeek ?? 0}
            sub="distinct users who worked out"
            accent="green"
          />
        </div>
      )}

      {/* Charts */}
      {isLoading ? (
        <div className="grid gap-6 lg:grid-cols-2">
          <Card className="h-[320px] animate-pulse bg-slate-100 dark:bg-slate-800" />
          <Card className="h-[320px] animate-pulse bg-slate-100 dark:bg-slate-800" />
        </div>
      ) : (
        <div className="grid gap-6 lg:grid-cols-2">
          <ChartCard
            title="Daily Signups (14 days)"
            data={signupsChartData}
            dataKey="count"
            stroke="#3b82f6"
          />
          <ChartCard
            title="Daily Workout Completions (14 days)"
            data={completionsChartData}
            dataKey="count"
            stroke="#ec4899"
          />
        </div>
      )}

      {!isLoading && data && (
        <p className="text-xs text-slate-400">Refreshes every 5 minutes.</p>
      )}
    </div>
  );
}
