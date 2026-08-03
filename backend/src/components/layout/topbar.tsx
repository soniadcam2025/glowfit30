"use client";

import { Menu } from "lucide-react";
import { Breadcrumbs } from "@/components/layout/breadcrumbs";
import { SyncStatus } from "@/components/layout/sync-status";
import { Button } from "@/components/ui/button";

/**
 * Minimal topbar: breadcrumb on the left, sync state on the right, separated
 * from the page by a hairline rule rather than sitting in its own panel.
 *
 * Logout and the theme switch moved to the sidebar account menu, matching the
 * reference design. The navigation toggle survives on mobile only — below md
 * there is no rail, so without it the drawer would be unreachable.
 */
export function Topbar({ onToggle }: { onToggle: () => void }) {
  return (
    <header className="sticky top-0 z-30 -mx-3 mb-5 flex items-center gap-3 border-b border-border bg-background/85 px-3 py-3 backdrop-blur sm:-mx-4 sm:px-4 lg:-mx-6 lg:px-6">
      <Button
        variant="ghost"
        size="icon"
        onClick={onToggle}
        aria-label="Open navigation"
        className="md:hidden"
      >
        <Menu className="h-4 w-4" />
      </Button>

      <div className="min-w-0 flex-1">
        <Breadcrumbs />
      </div>

      <SyncStatus className="shrink-0" />
    </header>
  );
}
