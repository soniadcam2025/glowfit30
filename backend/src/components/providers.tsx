"use client";

import { AppQueryProvider } from "@/store/query-provider";

export function Providers({ children }: { children: React.ReactNode }) {
  return <AppQueryProvider>{children}</AppQueryProvider>;
}
