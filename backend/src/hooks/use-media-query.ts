"use client";

import { useCallback, useSyncExternalStore } from "react";

/**
 * Viewport query hook.
 *
 * Uses useSyncExternalStore rather than useEffect + setState: matchMedia is
 * external mutable state, and subscribing to it this way avoids the cascading
 * render that a synchronous setState inside an effect causes. It also gives a
 * defined server snapshot instead of a first-paint flash.
 *
 * The server snapshot is `false`, so treat the first render as "unknown, assume
 * desktop" rather than branching to a mobile-only layout from it.
 */
export function useMediaQuery(query: string): boolean {
  const subscribe = useCallback(
    (onChange: () => void) => {
      const mql = window.matchMedia(query);
      mql.addEventListener("change", onChange);
      return () => mql.removeEventListener("change", onChange);
    },
    [query],
  );

  return useSyncExternalStore(
    subscribe,
    () => window.matchMedia(query).matches,
    () => false,
  );
}

/** Tailwind's default breakpoints, so JS and CSS agree on where things break. */
export const useIsMobile = () => useMediaQuery("(max-width: 767px)");
export const useIsTablet = () => useMediaQuery("(min-width: 768px) and (max-width: 1023px)");
