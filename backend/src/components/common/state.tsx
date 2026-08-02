import { AlertTriangle, Inbox, Loader2 } from "lucide-react";
import { Card } from "@/components/ui/card";
import { Skeleton, SkeletonRows } from "@/components/ui/skeleton";
import { cn } from "@/lib/utils";

/**
 * Shared loading / empty / error states. Every export keeps its original name
 * and call signature so existing pages are untouched; the new props are
 * optional. Previously these leaned on the `glass` utility, which was
 * undefined until Phase 1 — the skeletons were effectively invisible.
 */

export function AppLoader({ label = "Loading…" }: { label?: string }) {
  return (
    <div
      role="status"
      aria-live="polite"
      className="flex min-h-[220px] flex-col items-center justify-center gap-3"
    >
      <Loader2 className="h-7 w-7 animate-spin text-primary" />
      <span className="text-sm text-muted-foreground">{label}</span>
    </div>
  );
}

export function StatCardsSkeleton({ count = 3 }: { count?: number }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
      {Array.from({ length: count }).map((_, idx) => (
        <Skeleton key={idx} className="h-[122px] rounded-2xl" />
      ))}
    </div>
  );
}

export function ChartSkeleton() {
  return <Skeleton className="h-[320px] rounded-2xl" />;
}

export function TableSkeleton({ rows = 8 }: { rows?: number }) {
  return (
    <Card>
      <SkeletonRows rows={rows} />
    </Card>
  );
}

export function ErrorState({
  message,
  title = "Failed to load data",
  onRetry,
}: {
  message: string;
  title?: string;
  onRetry?: () => void;
}) {
  return (
    <Card className="border-danger/30 bg-danger/5">
      <div className="flex items-start gap-3">
        <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-danger" />
        <div className="min-w-0">
          <p className="text-sm font-semibold text-foreground">{title}</p>
          <p className="mt-1 text-sm text-muted-foreground">{message}</p>
          {onRetry && (
            <button
              type="button"
              onClick={onRetry}
              className="mt-2 text-sm font-medium text-primary underline-offset-4 hover:underline"
            >
              Try again
            </button>
          )}
        </div>
      </div>
    </Card>
  );
}

export function EmptyState({
  title,
  description,
  action,
  className,
}: {
  title: string;
  description?: string;
  action?: React.ReactNode;
  className?: string;
}) {
  return (
    <Card className={cn("flex flex-col items-center gap-2 py-10 text-center", className)}>
      <div className="grid h-10 w-10 place-items-center rounded-full bg-muted">
        <Inbox className="h-5 w-5 text-muted-foreground" />
      </div>
      <p className="text-sm font-semibold text-foreground">{title}</p>
      {description && <p className="max-w-sm text-sm text-muted-foreground">{description}</p>}
      {action && <div className="mt-2">{action}</div>}
    </Card>
  );
}
