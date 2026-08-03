"use client";

import { useRouter } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { LogOut, MoreVertical } from "lucide-react";
import { authService } from "@/services/auth.service";
import { ThemeToggle } from "@/components/ui/theme-toggle";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { cn } from "@/lib/utils";

const ROLE_LABEL: Record<string, string> = {
  super_admin: "Super Admin",
  admin: "Content Admin",
};

/**
 * Signed-in user block pinned to the foot of the sidebar.
 *
 * Logout and the theme switch live in its menu. The reference design has no
 * controls in the topbar, but both still need a home — burying them entirely
 * would trade a working feature for a screenshot match.
 */
export function UserMenu({ collapsed = false }: { collapsed?: boolean }) {
  const router = useRouter();
  const { data } = useQuery({
    queryKey: ["me"],
    queryFn: () => authService.me(),
    staleTime: 5 * 60_000,
    retry: false,
  });

  const user = data?.user;
  const initial = user?.name?.[0]?.toUpperCase() ?? "?";

  const onLogout = async () => {
    await authService.logout();
    router.push("/login");
    router.refresh();
  };

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button
          className={cn(
            "flex w-full items-center gap-3 rounded-lg px-2 py-2 text-left transition-colors hover:bg-muted",
            collapsed && "justify-center px-0",
          )}
          aria-label="Account menu"
        >
          <div className="grid h-8 w-8 shrink-0 place-items-center rounded-full bg-muted text-xs font-bold text-foreground">
            {initial}
          </div>
          {!collapsed && (
            <>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-semibold text-foreground">
                  {user?.name ?? "—"}
                </p>
                <p className="truncate text-xs text-muted-foreground">
                  {user ? (ROLE_LABEL[user.role] ?? user.role) : "Loading…"}
                </p>
              </div>
              <MoreVertical className="h-4 w-4 shrink-0 text-muted-foreground" />
            </>
          )}
        </button>
      </DropdownMenuTrigger>

      <DropdownMenuContent align="start" side="top" className="w-56">
        <DropdownMenuLabel className="truncate">{user?.email ?? "Signed in"}</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <div className="flex items-center justify-between px-2.5 py-1.5">
          <span className="text-sm text-foreground">Theme</span>
          <ThemeToggle />
        </div>
        <DropdownMenuSeparator />
        <DropdownMenuItem danger onSelect={() => void onLogout()}>
          <LogOut className="h-4 w-4" />
          Log out
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
