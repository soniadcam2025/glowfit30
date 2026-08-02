"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { ChevronRight } from "lucide-react";
import { adminNavItems } from "@/lib/constants";

/**
 * Derives the trail from the pathname and the nav table, so a new page picks up
 * a breadcrumb automatically by being registered in `adminNavItems` — no second
 * list to keep in sync.
 */
export function Breadcrumbs() {
  const pathname = usePathname();
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) return null;

  const label = (segment: string, href: string) =>
    adminNavItems.find((i) => i.href === href)?.label ??
    segment.replace(/-/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

  return (
    <nav aria-label="Breadcrumb" className="min-w-0">
      <ol className="flex items-center gap-1 text-sm">
        {segments.map((segment, i) => {
          const href = "/" + segments.slice(0, i + 1).join("/");
          const isLast = i === segments.length - 1;
          return (
            <li key={href} className="flex min-w-0 items-center gap-1">
              {i > 0 && (
                <ChevronRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
              )}
              {isLast ? (
                <span
                  aria-current="page"
                  className="truncate font-semibold text-foreground"
                >
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
