import {
  Activity,
  Bell,
  Dumbbell,
  LayoutDashboard,
  Settings,
  Sparkles,
  Users,
  UtensilsCrossed,
} from "lucide-react";
import type { Role } from "@/types";

export const authCookieKey = "glowfit_token";

export const adminNavItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/users", label: "Users", icon: Users },
  { href: "/workouts", label: "Workouts", icon: Dumbbell },
  { href: "/diet", label: "Diet", icon: UtensilsCrossed },
  { href: "/beauty", label: "Beauty", icon: Sparkles },
  { href: "/notifications", label: "Notifications", icon: Bell },
  { href: "/settings", label: "Settings", icon: Settings },
];

export const routeRoleMap: Record<string, Role[]> = {
  "/dashboard": ["admin", "super_admin"],
  "/users": ["admin", "super_admin"],
  "/workouts": ["admin", "super_admin"],
  "/diet": ["admin", "super_admin"],
  "/beauty": ["admin", "super_admin"],
  "/notifications": ["admin", "super_admin"],
  "/settings": ["super_admin"],
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
