"use client";

import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { authService } from "@/services/auth.service";

export function Topbar({ onToggle }: { onToggle: () => void }) {
  const router = useRouter();

  const onLogout = async () => {
    await authService.logout();
    router.push("/login");
    router.refresh();
  };

  return (
    <div className="mb-4 flex items-center justify-between rounded-2xl border border-slate-200 bg-white p-3 dark:border-slate-800 dark:bg-slate-900">
      <Button variant="secondary" onClick={onToggle}>
        Menu
      </Button>
      <Button variant="ghost" onClick={onLogout}>
        Logout
      </Button>
    </div>
  );
}
