"use client";

import { ThemeProvider } from "next-themes";
import { TooltipProvider } from "@/components/ui/tooltip";
import { AppQueryProvider } from "@/store/query-provider";

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider
      attribute="class"
      defaultTheme="system"
      enableSystem
      // Colour transitions during a theme swap read as a flash rather than a
      // fade, so they are suppressed while the class flips.
      disableTransitionOnChange
    >
      <AppQueryProvider>
        <TooltipProvider delayDuration={200}>{children}</TooltipProvider>
      </AppQueryProvider>
    </ThemeProvider>
  );
}
