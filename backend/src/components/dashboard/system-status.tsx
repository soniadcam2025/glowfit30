"use client";

import { useQuery } from "@tanstack/react-query";
import { CheckCircle2, CircleAlert, Loader2 } from "lucide-react";
import { Card, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { api } from "@/services/api";

/**
 * Live service status.
 *
 * Deliberately limited to what the admin can actually observe from the browser:
 * the API answering its health route. PM2, database and deployment state are
 * server-side facts this app has no endpoint for, so they are shown as
 * "not reported" rather than as green ticks that assert something unverified —
 * a dashboard claiming health it never checked is worse than no dashboard.
 */
type Row = { label: string; state: "ok" | "down" | "loading" | "unknown"; detail: string };

function StatusRow({ label, state, detail }: Row) {
  const Icon =
    state === "loading" ? Loader2 : state === "ok" ? CheckCircle2 : CircleAlert;

  return (
    <div className="flex items-center justify-between gap-3 border-b border-border py-2.5 last:border-0">
      <div className="flex min-w-0 items-center gap-2">
        <Icon
          className={cn(
            "h-4 w-4 shrink-0",
            state === "loading" && "animate-spin text-muted-foreground",
            state === "ok" && "text-success",
            state === "down" && "text-danger",
            state === "unknown" && "text-muted-foreground",
          )}
        />
        <span className="truncate text-sm font-medium text-foreground">{label}</span>
      </div>
      <span
        className={cn(
          "shrink-0 text-xs",
          state === "ok" ? "text-success" : "text-muted-foreground",
        )}
      >
        {detail}
      </span>
    </div>
  );
}

export function SystemStatus() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["api-health"],
    queryFn: async () => {
      const started = performance.now();
      const { data } = await api.get("/");
      return { payload: data, ms: Math.round(performance.now() - started) };
    },
    refetchInterval: 60_000,
    retry: 1,
  });

  const apiState: Row["state"] = isLoading ? "loading" : isError ? "down" : "ok";

  return (
    <Card>
      <CardHeader>
        <CardTitle>System status</CardTitle>
        <CardDescription>Checked from this browser, every 60s</CardDescription>
      </CardHeader>
      <StatusRow
        label="API"
        state={apiState}
        detail={
          isLoading ? "checking…" : isError ? "unreachable" : `healthy · ${data?.ms}ms`
        }
      />
      <StatusRow
        label="Admin panel"
        state="ok"
        detail="serving this page"
      />
      <StatusRow
        label="Database"
        state="unknown"
        detail="not reported by the API"
      />
      <StatusRow
        label="Deployment"
        state="unknown"
        detail="see CI verification"
      />
    </Card>
  );
}
