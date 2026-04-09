"use client";

import { useQuery } from "@tanstack/react-query";
import { adminService } from "@/services/admin.service";
import { Card } from "@/components/ui/card";
import { PageHeader } from "@/components/common/page-header";

export default function DashboardPage() {
  const { data, isLoading } = useQuery({
    queryKey: ["admin-stats"],
    queryFn: () => adminService.getStats(),
  });

  return (
    <div className="space-y-4">
      <PageHeader title="Dashboard" description="Live admin overview from production API." />
      {isLoading ? (
        <Card>Loading...</Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-3">
          <Card>
            <p className="text-sm text-slate-500">Total users</p>
            <p className="text-2xl font-semibold">{data?.totalUsers ?? 0}</p>
          </Card>
          <Card>
            <p className="text-sm text-slate-500">Active users</p>
            <p className="text-2xl font-semibold">{data?.activeUsers ?? 0}</p>
          </Card>
          <Card>
            <p className="text-sm text-slate-500">Blocked users</p>
            <p className="text-2xl font-semibold">{data?.blockedUsers ?? 0}</p>
          </Card>
        </div>
      )}
    </div>
  );
}
