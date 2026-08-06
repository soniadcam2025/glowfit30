import {
  Activity,
  BarChart2,
  Bell,
  Dumbbell,
  LayoutDashboard,
  Library,
  Settings,
  Sparkles,
  Users,
  UtensilsCrossed,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";
import type { Role } from "@/types";

export const authCookieKey = "token";

/** Client-side JWT for Authorization header when API is on another origin than the admin app. */
export const adminJwtStorageKey = "glowfit_admin_jwt";

export type AdminNavChild = {
  href: string;
  label: string;
  /** Renders as a non-clickable heading above the items that follow it. */
  group?: string;
};

export type AdminNavItem = {
  href: string;
  label: string;
  icon: LucideIcon;
  children?: AdminNavChild[];
};

export const adminNavItems: AdminNavItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/users", label: "Users", icon: Users },
  { href: "/workouts", label: "Workouts", icon: Dumbbell },
  { href: "/workout-library", label: "Workout Library", icon: Library },
  { href: "/diet", label: "Diet", icon: UtensilsCrossed },
  { href: "/beauty", label: "Glow Content", icon: Sparkles },
  { href: "/analytics", label: "Analytics", icon: BarChart2 },
  { href: "/notifications", label: "Notifications", icon: Bell },
  {
    href: "/settings",
    label: "Settings",
    icon: Settings,
    children: [
      { href: "/settings", label: "Admin Settings" },
      // "Manage Settings" is a heading rather than a third collapsible level —
      // three levels of nesting in a sidebar is hard to scan and harder to hit.
      { href: "/settings/delete-reset", label: "Delete / Reset", group: "Manage Settings" },
      { href: "/settings/server", label: "Server Setting" },
      { href: "/settings/media", label: "Media Performance" },
    ],
  },
];

export const routeRoleMap: Record<string, Role[]> = {
  "/dashboard": ["admin", "super_admin"],
  "/users": ["admin", "super_admin"],
  "/workouts": ["admin", "super_admin"],
  "/workout-library": ["admin", "super_admin"],
  "/diet": ["admin", "super_admin"],
  "/beauty": ["admin", "super_admin"],
  "/analytics": ["admin", "super_admin"],
  "/notifications": ["admin", "super_admin"],
  // Sub-pages inherit the parent's restriction; middleware matches by prefix,
  // but listing them keeps the map readable and survives a matcher change.
  "/settings": ["super_admin"],
  "/settings/delete-reset": ["super_admin"],
  "/settings/server": ["super_admin"],
  "/settings/media": ["super_admin"],
};

export const adminRoleBadgeColor: Record<Role, string> = {
  super_admin: "text-purple-700",
  admin: "text-blue-700",
  user: "text-slate-700",
};

export const dashboardTrendSeed = [
  { name: "Mon", users: 42, engagement: 28 },
  { name: "Tue", users: 56, engagement: 34 },
  { name: "Wed", users: 61, engagement: 38 },
  { name: "Thu", users: 73, engagement: 41 },
  { name: "Fri", users: 85, engagement: 44 },
  { name: "Sat", users: 90, engagement: 46 },
  { name: "Sun", users: 96, engagement: 49 },
];

export const appIcon = Activity;
