"use client";

import { useRouter } from "next/navigation";
import { LogOut, PanelLeft } from "lucide-react";
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
    <header className="glass sticky top-0 z-30 mb-4 flex items-center justify-between gap-3 rounded-2xl px-3 py-2.5">
      <Tooltip>
        <TooltipTrigger asChild>
          <Button
            variant="ghost"
            size="icon"
            onClick={onToggle}
            aria-label="Toggle navigation"
          >
            <PanelLeft className="h-4 w-4" />
          </Button>
        </TooltipTrigger>
        <TooltipContent>Toggle navigation</TooltipContent>
      </Tooltip>

      <div className="flex items-center gap-2">
        <ThemeToggle />
        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              onClick={onLogout}
              aria-label="Log out"
            >
              <LogOut className="h-4 w-4" />
            </Button>
          </TooltipTrigger>
          <TooltipContent>Log out</TooltipContent>
        </Tooltip>
      </div>
    </header>
  );
}
