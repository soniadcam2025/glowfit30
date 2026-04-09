"use client";

import { Button } from "@/components/ui/button";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body className="flex min-h-screen items-center justify-center p-4">
        <div className="glass w-full max-w-lg rounded-2xl p-6">
          <h2 className="text-lg font-semibold">Unexpected error</h2>
          <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{error.message}</p>
          <Button className="mt-4" onClick={reset}>
            Retry
          </Button>
        </div>
      </body>
    </html>
  );
}
