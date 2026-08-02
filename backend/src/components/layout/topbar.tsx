"use client";

import { useRouter } from "next/navigation";
import { LogOut, Menu, PanelLeft } from "lucide-react";
import { Breadcrumbs } from "@/components/layout/breadcrumbs";
import { Button } from "@/components/ui/button";
import { ThemeToggle } from "@/components/ui/theme-toggle";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { authService } from "@/services/auth.service";

export function Topbar({ onToggle }: { onToggle: () => void }) {
  const router = useRouter();

  const onLogout = async () => {
    await authService.logout();
    router.push("/login");
    router.refresh();
  };

  return (
    <header className="glass sticky top-0 z-30 my-3 flex items-center gap-2 rounded-2xl px-2.5 py-2 sm:gap-3 sm:px-3">
      <Tooltip>
        <TooltipTrigger asChild>
          <Button
            variant="ghost"
            size="icon"
            onClick={onToggle}
            aria-label="Toggle navigation"
          >
            {/* A hamburger reads as "opens a menu" on mobile; the panel icon
                reads as "collapse the rail" on desktop. */}
            <Menu className="h-4 w-4 md:hidden" />
            <PanelLeft className="hidden h-4 w-4 md:block" />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Toggle navigation</TooltipContent>
      </Tooltip>

      {/* Hidden on the smallest screens, where the trail would crowd out the controls. */}
      <div className="hidden min-w-0 flex-1 sm:block">
        <Breadcrumbs />
      </div>
      <div className="flex-1 sm:hidden" />

      <div className="flex shrink-0 items-center gap-1.5 sm:gap-2">
        <ThemeToggle />
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="ghost" size="icon" onClick={onLogout} aria-label="Log out">
              <LogOut className="h-4 w-4" />
            </Button>
          </TooltipTrigger>
          <TooltipContent>Log out</TooltipContent>
        </Tooltip>
      </div>
    </header>
  );
}
