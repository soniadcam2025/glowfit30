"use client";

import { useState } from "react";
import { usePathname } from "next/navigation";
import { Sidebar, SidebarBody } from "@/components/layout/sidebar";
import { Topbar } from "@/components/layout/topbar";
import { Sheet, SheetContent, SheetTitle } from "@/components/ui/sheet";
import { useIsMobile, useIsTablet } from "@/hooks/use-media-query";
import { cn } from "@/lib/utils";

/**
 * Responsive shell.
 *
 *   desktop (≥1024)   fixed rail, expanded by default, user-collapsible
 *   tablet  (768–1023) fixed rail, collapsed to icons by default
 *   mobile  (<768)     no rail; the toggle opens a drawer
 *
 * The mobile drawer is a Sheet rather than a shifted layout, so page content
 * never reflows to make room on a small screen.
 */
export function AdminShell({ children }: { children: React.ReactNode }) {
  // null = follow the breakpoint default; a boolean means the user chose.
  // Deriving instead of syncing in an effect avoids a cascading render and
  // keeps an explicit choice from being overwritten on resize.
  const [userCollapsed, setUserCollapsed] = useState<boolean | null>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const isMobile = useIsMobile();
  const isTablet = useIsTablet();
  const collapsed = userCollapsed ?? isTablet;

  // Close the drawer when the route changes, so it never covers the page it
  // navigated to. Adjusting state during render is React's supported pattern
  // for this — an effect here would fire after a needless paint.
  const pathname = usePathname();
  const [lastPathname, setLastPathname] = useState(pathname);
  if (pathname !== lastPathname) {
    setLastPathname(pathname);
    if (drawerOpen) setDrawerOpen(false);
  }

  const onToggle = () => {
    if (isMobile) setDrawerOpen((v) => !v);
    else setUserCollapsed(!collapsed);
  };

  return (
    <div className="min-h-screen bg-background">
      <Sidebar collapsed={collapsed} onToggleCollapse={() => setUserCollapsed(!collapsed)} />

      <Sheet open={drawerOpen} onOpenChange={setDrawerOpen}>
        <SheetContent side="left" className="p-0">
          {/* Radix requires a title for the dialog's accessible name. */}
          <SheetTitle className="sr-only">Navigation</SheetTitle>
          <SidebarBody onNavigate={() => setDrawerOpen(false)} />
        </SheetContent>
      </Sheet>

      <div
        className={cn(
          "ml-0 transition-[margin] duration-300",
          collapsed ? "md:ml-[76px]" : "md:ml-[248px]",
        )}
      >
        <div className="mx-auto w-full max-w-[1600px] px-3 pb-10 sm:px-4 lg:px-6">
          <Topbar onToggle={onToggle} />
          {children}
        </div>
      </div>
    </div>
  );
}
