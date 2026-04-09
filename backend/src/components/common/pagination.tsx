"use client";

import { Button } from "@/components/ui/button";

export function Pagination({
  page,
  total,
  pageSize,
  onChange,
}: {
  page: number;
  total: number;
  pageSize: number;
  onChange: (page: number) => void;
}) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  return (
    <div className="mt-4 flex items-center justify-between">
      <p className="text-sm text-slate-600 dark:text-slate-300">
        Page {page} of {pages}
      </p>
      <div className="flex gap-2">
        <Button variant="secondary" onClick={() => onChange(page - 1)} disabled={page <= 1}>
          Prev
        </Button>
        <Button variant="secondary" onClick={() => onChange(page + 1)} disabled={page >= pages}>
          Next
        </Button>
      </div>
    </div>
  );
}
