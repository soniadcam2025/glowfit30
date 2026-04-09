"use client";

import { useState } from "react";
import { Sidebar } from "@/components/layout/sidebar";
import { Topbar } from "@/components/layout/topbar";
import { cn } from "@/lib/utils";

export function AdminShell({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-50/80 to-indigo-100/40 p-4 dark:from-slate-950 dark:to-slate-900">
      <Sidebar collapsed={collapsed} />
      <main
        className={cn(
          "transition-all duration-300",
          collapsed ? "ml-[92px]" : "ml-[268px]",
          "max-md:ml-0",
        )}
      >
        <Topbar onToggle={() => setCollapsed((v) => !v)} />
        <div className="pb-8">{children}</div>
      </main>
    </div>
  );
}
