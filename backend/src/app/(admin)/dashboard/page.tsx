"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import {
  Activity,
  Bell,
  Dumbbell,
  ShieldBan,
  Sparkles,
  UserCheck,
  Users,
  UtensilsCrossed,
} from "lucide-react";
import { adminService } from "@/services/admin.service";
import { PageHeader } from "@/components/common/page-header";
import { StatCard } from "@/components/dashboard/stat-card";
import { SystemStatus } from "@/components/dashboard/system-status";
import { StatCardsSkeleton, ErrorState } from "@/components/common/state";
import { Button } from "@/components/ui/button";
import { Card, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";

const QUICK_ACTIONS = [
  { href: "/beauty", label: "Glow content", icon: Sparkles },
  { href: "/workouts", label: "Workouts", icon: Dumbbell },
  { href: "/diet", label: "Diet plans", icon: UtensilsCrossed },
  { href: "/notifications", label: "Notifications", icon: Bell },
];

export default function DashboardPage() {
  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["admin-stats"],
    queryFn: () => adminService.getStats(),
    refetchInterval: 60_000,
  });

  return (
    <div className="space-y-6">
      <PageHeader title="Dashboard" description="Live admin overview from the production API." />

      {isError ? (
        <ErrorState
          message={error instanceof Error ? error.message : "Could not reach the API."}
          onRetry={() => void refetch()}
        />
      ) : isLoading ? (
        <StatCardsSkeleton count={5} />
      ) : (
        <>
          <section>
            <h2 className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Users
            </h2>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              <StatCard index={0} label="Total users" value={data?.totalUsers ?? 0} icon={Users} />
              <StatCard
                index={1}
                label="Active users"
                value={data?.activeUsers ?? 0}
                sub="not blocked"
                icon={UserCheck}
                tone="success"
              />
              <StatCard
                index={2}
                label="Blocked users"
                value={data?.blockedUsers ?? 0}
                icon={ShieldBan}
                tone={(data?.blockedUsers ?? 0) > 0 ? "danger" : "default"}
              />
            </div>
          </section>

          <section>
            <h2 className="mb-3 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Content &amp; activity
            </h2>
            <div className="grid gap-3 sm:grid-cols-2">
              <StatCard
                index={3}
                label="Completions today"
                value={data?.todayCompletions ?? 0}
                sub="workouts finished today"
                icon={Activity}
                tone="primary"
              />
              <StatCard
                index={4}
                label="Total workouts"
                value={data?.totalWorkouts ?? 0}
                sub="published plans"
                icon={Dumbbell}
              />
            </div>
          </section>

          <div className="grid gap-3 lg:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Quick actions</CardTitle>
                <CardDescription>Jump straight to the content you edit most</CardDescription>
              </CardHeader>
              <div className="grid grid-cols-2 gap-2">
                {QUICK_ACTIONS.map(({ href, label, icon: Icon }) => (
                  <Button key={href} asChild variant="secondary" className="justify-start">
                    <Link href={href}>
                      <Icon className="h-4 w-4" />
                      <span className="truncate">{label}</span>
                    </Link>
                  </Button>
                ))}
              </div>
            </Card>

            <SystemStatus />
          </div>

          {data?.generatedAt && (
            <p className="text-xs text-muted-foreground">
              Last updated {new Date(data.generatedAt).toLocaleTimeString()} · refreshes every 60s
            </p>
          )}
        </>
      )}
    </div>
  );
}
