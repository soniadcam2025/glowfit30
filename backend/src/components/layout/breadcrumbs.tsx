"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ChevronRight } from "lucide-react";
import { adminNavItems } from "@/lib/constants";

/**
 * Groups each route under a section so the trail reads "Content / Workouts"
 * rather than a lone page name. Sections are presentational only — there is no
 * route behind them, so they render as plain text, not links.
 */
const SECTION: Record<string, string> = {
  "/dashboard": "Overview",
  "/users": "People",
  "/workouts": "Content",
  "/workout-library": "Content",
  "/diet": "Content",
  "/beauty": "Content",
  "/analytics": "Insights",
  "/notifications": "System",
  "/settings": "System",
};

export function Breadcrumbs() {
  const pathname = usePathname();
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) return null;

  const label = (segment: string, href: string) =>
    adminNavItems.find((i) => i.href === href)?.label ??
    segment.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

  const section = SECTION[`/${segments[0]}`];

  return (
    <nav aria-label="Breadcrumb" className="min-w-0">
      <ol className="flex items-center gap-1.5 text-sm">
        {section && (
          <li className="flex shrink-0 items-center gap-1.5">
            <span className="text-muted-foreground">{section}</span>
            <span className="text-muted-foreground/60">/</span>
          </li>
        )}
        {segments.map((segment, i) => {
          const href = "/" + segments.slice(0, i + 1).join("/");
          const isLast = i === segments.length - 1;
          return (
            <li key={href} className="flex min-w-0 items-center gap-1.5">
              {i > 0 && (
                <ChevronRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
              )}
              {isLast ? (
                <span aria-current="page" className="truncate font-semibold text-foreground">
                  {label(segment, href)}
                </span>
              ) : (
                <Link
                  href={href}
                  className="truncate text-muted-foreground transition-colors hover:text-foreground"
                >
                  {label(segment, href)}
                </Link>
              )}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
