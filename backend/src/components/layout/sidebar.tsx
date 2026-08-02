"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Sparkles } from "lucide-react";
import { adminNavItems } from "@/lib/constants";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

/**
 * Navigation list, shared by the fixed desktop rail and the mobile drawer, so
 * there is one source of nav markup rather than two that drift apart.
 */
export function SidebarNav({
  collapsed = false,
  onNavigate,
}: {
  collapsed?: boolean;
  onNavigate?: () => void;
}) {
  const pathname = usePathname();

  return (
    <nav className="flex flex-col gap-1 p-3" aria-label="Main">
      {adminNavItems.map((item) => {
        // startsWith so nested routes keep the parent item highlighted.
        const active = pathname === item.href || pathname.startsWith(`${item.href}/`);

        const link = (
          <Link
            href={item.href}
            onClick={onNavigate}
            aria-current={active ? "page" : undefined}
            className={cn(
              "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
              collapsed && "justify-center px-0",
              active
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground hover:bg-muted hover:text-foreground",
            )}
          >
            <item.icon className="h-4 w-4 shrink-0" />
            {!collapsed && <span className="truncate">{item.label}</span>}
          </Link>
        );

        // The collapsed rail shows icons only, so the label moves to a tooltip.
        return collapsed ? (
          <Tooltip key={item.href}>
            <TooltipTrigger asChild>{link}</TooltipTrigger>
            <TooltipContent side="right">{item.label}</TooltipContent>
          </Tooltip>
        ) : (
          <div key={item.href}>{link}</div>
        );
      })}
    </nav>
  );
}

export function SidebarBrand({ collapsed = false }: { collapsed?: boolean }) {
  return (
    <div
      className={cn(
        "flex h-16 items-center gap-2 border-b border-border px-4",
        collapsed && "justify-center px-0",
      )}
    >
      <div className="grid h-8 w-8 shrink-0 place-items-center rounded-lg bg-primary">
        <Sparkles className="h-4 w-4 text-primary-foreground" />
      </div>
      {!collapsed && (
        <span className="truncate text-sm font-bold tracking-tight text-foreground">
          GlowFit Admin
        </span>
      )}
    </div>
  );
}

/** Fixed rail for tablet and desktop. Hidden below md, where the drawer takes over. */
export function Sidebar({ collapsed }: { collapsed: boolean }) {
  return (
    <aside
      className={cn(
        "fixed left-0 top-0 z-40 hidden h-screen border-r border-border bg-surface md:block",
        "transition-[width] duration-300",
        collapsed ? "w-[76px]" : "w-[248px]",
      )}
    >
      <SidebarBrand collapsed={collapsed} />
      <SidebarNav collapsed={collapsed} />
    </aside>
  );
}
