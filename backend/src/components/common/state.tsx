import { AlertTriangle, Loader2 } from "lucide-react";

export function AppLoader() {
  return (
    <div className="flex min-h-[220px] items-center justify-center">
      <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
    </div>
  );
}

export function StatCardsSkeleton() {
  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
      {Array.from({ length: 3 }).map((_, idx) => (
        <div key={idx} className="glass h-[122px] animate-pulse rounded-2xl" />
      ))}
    </div>
  );
}

export function ChartSkeleton() {
  return <div className="glass h-[320px] animate-pulse rounded-2xl" />;
}

export function TableSkeleton() {
  return (
    <div className="glass rounded-2xl p-4">
      {Array.from({ length: 8 }).map((_, idx) => (
        <div key={idx} className="mb-3 h-8 animate-pulse rounded-lg bg-slate-300/30 last:mb-0" />
      ))}
    </div>
  );
}

export function ErrorState({ message }: { message: string }) {
  return (
    <div className="glass rounded-2xl p-5 text-rose-600 dark:text-rose-300">
      <div className="flex items-center gap-2 font-medium">
        <AlertTriangle className="h-4 w-4" />
        Failed to load data
      </div>
      <p className="mt-2 text-sm">{message}</p>
    </div>
  );
}

export function EmptyState({ title }: { title: string }) {
  return (
    <div className="glass rounded-2xl p-8 text-center text-sm text-slate-500 dark:text-slate-300">
      {title}
    </div>
  );
}
