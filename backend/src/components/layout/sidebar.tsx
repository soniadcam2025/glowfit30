"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ChevronDown, PanelLeft } from "lucide-react";
import { adminNavItems } from "@/lib/constants";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { UserMenu } from "@/components/layout/user-menu";
import { cn } from "@/lib/utils";

/**
 * Navigation list, shared by the fixed desktop rail and the mobile drawer, so
 * there is one source of nav markup rather than two that drift apart.
 *
 * Expanded rows use a dot marker per the reference design; the collapsed rail
 * falls back to each item's icon, since a column of identical dots would be
 * unusable without labels.
 */
export function SidebarNav({
  collapsed = false,
  onNavigate,
}: {
  collapsed?: boolean;
  onNavigate?: () => void;
}) {
  const pathname = usePathname();

  /** A child is current only on an exact match — "/settings" must not stay lit
   *  while "/settings/server" is open, or two rows appear active at once. */
  const isChildActive = (href: string) => pathname === href;
  const isSectionActive = (href: string) =>
    pathname === href || pathname.startsWith(`${href}/`);

  return (
    <nav className="flex flex-col gap-0.5 px-3 py-2" aria-label="Main">
      {adminNavItems.map((item) => {
        const sectionActive = isSectionActive(item.href);
        // A parent with children is only "active" itself when no child is.
        const selfActive = item.children
          ? item.children.every((c) => !isChildActive(c.href)) && sectionActive
          : sectionActive;

        const link = (
          <Link
            href={item.href}
            onClick={onNavigate}
            aria-current={selfActive ? "page" : undefined}
            className={cn(
              "group relative flex items-center gap-3 rounded-lg py-2 text-sm transition-colors",
              collapsed ? "justify-center px-0" : "px-3",
              selfActive
                ? "bg-primary/10 font-semibold text-foreground"
                : "text-muted-foreground hover:bg-muted hover:text-foreground",
            )}
          >
            {/* Left accent bar on the active row. */}
            {selfActive && !collapsed && (
              <span className="absolute left-0 top-1/2 h-5 w-0.5 -translate-y-1/2 rounded-r bg-primary" />
            )}

            {collapsed ? (
              <item.icon className="h-4 w-4 shrink-0" />
            ) : (
              <span
                className={cn(
                  "h-1.5 w-1.5 shrink-0 rounded-full transition-colors",
                  selfActive
                    ? "bg-primary"
                    : "bg-muted-foreground/40 group-hover:bg-muted-foreground",
                )}
              />
            )}
            {!collapsed && <span className="flex-1 truncate">{item.label}</span>}
            {!collapsed && item.children && (
              <ChevronDown
                className={cn(
                  "h-3.5 w-3.5 shrink-0 transition-transform",
                  sectionActive ? "rotate-0" : "-rotate-90",
                )}
              />
            )}
          </Link>
        );

        if (collapsed) {
          return (
            <Tooltip key={item.href}>
              <TooltipTrigger asChild>{link}</TooltipTrigger>
              <TooltipContent side="right">{item.label}</TooltipContent>
            </Tooltip>
          );
        }

        return (
          <div key={item.href}>
            {link}
            {/* Submenu expands with its section rather than needing a separate
                click, so the current page is always visible in context. */}
            {item.children && sectionActive && (
              <div className="mt-0.5 ml-[13px] border-l border-border pl-3">
                {item.children.map((child) => (
                  <div key={child.href}>
                    {child.group && (
                      <p className="px-2 pb-1 pt-2 text-[11px] font-semibold uppercase tracking-wide text-muted-foreground/70">
                        {child.group}
                      </p>
                    )}
                    <Link
                      href={child.href}
                      onClick={onNavigate}
                      aria-current={isChildActive(child.href) ? "page" : undefined}
                      className={cn(
                        "block rounded-md px-2 py-1.5 text-[13px] transition-colors",
                        isChildActive(child.href)
                          ? "bg-primary/10 font-semibold text-foreground"
                          : "text-muted-foreground hover:bg-muted hover:text-foreground",
                      )}
                    >
                      {child.label}
                    </Link>
                  </div>
                ))}
              </div>
            )}
          </div>
        );
      })}
    </nav>
  );
}

export function SidebarBrand({
  collapsed = false,
  onToggleCollapse,
}: {
  collapsed?: boolean;
  onToggleCollapse?: () => void;
}) {
  return (
    <div
      className={cn(
        "group/brand flex h-16 items-center gap-3 px-5",
        collapsed && "justify-center px-0",
      )}
    >
      <div className="h-7 w-7 shrink-0 rounded-lg bg-gradient-to-br from-primary to-primary/60" />
      {!collapsed && (
        <span className="flex-1 truncate text-base font-bold tracking-tight text-foreground">
          GlowFit Admin
        </span>
      )}
      {/* The reference topbar has no collapse control, so it lives here —
          revealed on hover to keep the header clean. */}
      {onToggleCollapse && (
        <button
          type="button"
          onClick={onToggleCollapse}
          aria-label={collapsed ? "Expand navigation" : "Collapse navigation"}
          className={cn(
            "rounded-md p-1 text-muted-foreground transition-all hover:bg-muted hover:text-foreground",
            !collapsed && "opacity-0 focus-visible:opacity-100 group-hover/brand:opacity-100",
          )}
        >
          <PanelLeft className="h-4 w-4" />
        </button>
      )}
    </div>
  );
}

/**
 * Full sidebar contents — brand, nav, and the account block pinned to the foot.
 * Shared by the desktop rail and the mobile drawer.
 */
export function SidebarBody({
  collapsed = false,
  onNavigate,
  onToggleCollapse,
}: {
  collapsed?: boolean;
  onNavigate?: () => void;
  onToggleCollapse?: () => void;
}) {
  return (
    <div className="flex h-full flex-col">
      <SidebarBrand collapsed={collapsed} onToggleCollapse={onToggleCollapse} />
      <div className="scrollbar-slim flex-1 overflow-y-auto">
        <SidebarNav collapsed={collapsed} onNavigate={onNavigate} />
      </div>
      <div className={cn("border-t border-border p-3", collapsed && "px-2")}>
        <UserMenu collapsed={collapsed} />
      </div>
    </div>
  );
}

/** Fixed rail for tablet and desktop. Hidden below md, where the drawer takes over. */
export function Sidebar({
  collapsed,
  onToggleCollapse,
}: {
  collapsed: boolean;
  onToggleCollapse?: () => void;
}) {
  return (
    <aside
      className={cn(
        "fixed left-0 top-0 z-40 hidden h-screen border-r border-border bg-surface md:block",
        "transition-[width] duration-300",
        collapsed ? "w-[76px]" : "w-[248px]",
      )}
    >
      <SidebarBody collapsed={collapsed} onToggleCollapse={onToggleCollapse} />
    </aside>
  );
}
