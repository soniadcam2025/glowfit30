"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { adminNavItems } from "@/lib/constants";
import { cn } from "@/lib/utils";

export function Sidebar({ collapsed }: { collapsed: boolean }) {
  const pathname = usePathname();
  return (
    <aside
      className={cn(
        "glass-strong fixed left-0 top-0 z-40 h-screen transition-all duration-300",
        collapsed ? "w-[84px]" : "w-[260px]",
      )}
    >
      <div className="flex h-16 items-center justify-center border-b border-border-soft">
        <span className="text-lg font-bold text-blue-600">GF Admin</span>
      </div>
      <nav className="p-3">
        {adminNavItems.map((item) => {
          const active = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "mb-1 flex items-center gap-3 rounded-xl px-3 py-2 text-sm transition",
                active
                  ? "bg-blue-600 text-white shadow-sm"
                  : "text-slate-700 hover:bg-white/70 dark:text-slate-200",
              )}
            >
              <item.icon className="h-4 w-4" />
              {!collapsed && <span>{item.label}</span>}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
