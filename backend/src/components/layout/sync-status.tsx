"use client";

import { useSyncExternalStore } from "react";
import { useIsFetching, useQueryClient } from "@tanstack/react-query";
import { cn } from "@/lib/utils";

const TICK_MS = 30_000;

function subscribeToTick(onChange: () => void) {
  const id = setInterval(onChange, TICK_MS);
  return () => clearInterval(id);
}

function ago(ms: number): string {
  const s = Math.floor(ms / 1000);
  if (s < 45) return "just now";
  const m = Math.floor(s / 60);
  if (m < 60) return `${m} min ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

/**
 * "Synced N min ago" indicator.
 *
 * Reads the newest successful fetch out of the React Query cache, so it
 * reflects real data rather than a decorative timestamp. Amber when the newest
 * data is over five minutes old, red if a query is currently in error.
 */
export function SyncStatus({ className }: { className?: string }) {
  const qc = useQueryClient();
  const fetching = useIsFetching();
  // Time comes from an external store rather than state-in-an-effect or a bare
  // Date.now() in the render body — both of which are impure. The snapshot is
  // quantised to the tick interval so it is stable between ticks, which is what
  // keeps useSyncExternalStore from re-rendering forever.
  const bucket = useSyncExternalStore(
    subscribeToTick,
    () => Math.floor(Date.now() / TICK_MS),
    () => 0,
  );
  const now = bucket * TICK_MS;

  const queries = qc.getQueryCache().getAll();
  const newest = queries.reduce((max, q) => Math.max(max, q.state.dataUpdatedAt ?? 0), 0);
  const hasError = queries.some((q) => q.state.status === "error");

  if (!newest && !fetching && !hasError) return null;

  const age = newest && now ? Math.max(0, now - newest) : 0;
  const tone = hasError
    ? "bg-danger"
    : fetching
      ? "bg-info animate-pulse"
      : age > 5 * 60_000
        ? "bg-warning"
        : "bg-success";

  const label = hasError
    ? "Sync failed"
    : fetching
      ? "Syncing…"
      : `Synced ${ago(age)}`;

  return (
    <div className={cn("flex items-center gap-2", className)}>
      <span className={cn("h-2 w-2 shrink-0 rounded-full", tone)} />
      <span className="text-xs text-muted-foreground">{label}</span>
    </div>
  );
}
