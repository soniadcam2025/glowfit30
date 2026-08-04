"use client";

import { useQuery } from "@tanstack/react-query";
import { HardDrive, Server } from "lucide-react";
import { withRoleGuard } from "@/components/auth/with-role-guard";
import { PageHeader } from "@/components/common/page-header";
import { ErrorState, TableSkeleton } from "@/components/common/state";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { maintenanceService } from "@/services/maintenance.service";

function Row({ label, value }: { label: string; value: string | null }) {
  return (
    <div className="flex items-start justify-between gap-4 border-b border-border py-2.5 last:border-0">
      <span className="text-sm text-muted-foreground">{label}</span>
      <span className="break-all text-right font-mono text-xs text-foreground">
        {value ?? <span className="text-muted-foreground">not set</span>}
      </span>
    </div>
  );
}

function ServerSettingPage() {
  const { data, isLoading, isError, error, refetch } = useQuery({
    queryKey: ["storage-config"],
    queryFn: () => maintenanceService.storage(),
  });

  return (
    <div className="space-y-4">
      <PageHeader
        title="Server Setting"
        description="Runtime and media-server configuration."
      />

      {isError ? (
        <ErrorState
          message={error instanceof Error ? error.message : "Could not load configuration."}
          onRetry={() => void refetch()}
        />
      ) : isLoading ? (
        <TableSkeleton rows={6} />
      ) : (
        <>
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <HardDrive className="h-4 w-4" />
                Media server
                {data?.configured ? (
                  <Badge variant="success">Connected</Badge>
                ) : (
                  <Badge variant="danger">Not configured</Badge>
                )}
              </CardTitle>
              <CardDescription>
                Where uploaded images and videos are stored and served from.
              </CardDescription>
            </CardHeader>

            <Row label="Provider" value={data?.provider ?? null} />
            <Row label="Endpoint" value={data?.endpoint ?? null} />
            <Row label="Region" value={data?.region ?? null} />
            <Row label="Bucket — exercises / glow" value={data?.bucketExercises ?? null} />
            <Row label="Bucket — diet" value={data?.bucketDiet ?? null} />
            <Row label="Access key" value={data?.accessKey ?? null} />
            <Row label="Secret key" value={data?.secretKey ?? null} />

            <Alert variant="info" title="This is read-only" className="mt-4">
              These values come from environment variables on the server, so they cannot
              be edited from the browser — the API reads them once at startup. Changing
              provider means updating the server&apos;s <code>.env</code> and restarting
              the API. Making it editable here needs the configuration moved into the
              database, which is a separate change.
            </Alert>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Server className="h-4 w-4" />
                Other server settings
              </CardTitle>
              <CardDescription>
                Nothing else is exposed yet — tell me what you want to see or control
                here and I will add it.
              </CardDescription>
            </CardHeader>
          </Card>
        </>
      )}
    </div>
  );
}

export default withRoleGuard(ServerSettingPage, ["super_admin"]);
