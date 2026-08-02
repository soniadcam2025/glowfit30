import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";
import { authCookieKey, routeRoleMap } from "@/lib/constants";
import type { Role } from "@/types";

const authRoutes = ["/login"];
const adminRoutes = [
  "/dashboard",
  "/users",
  "/workouts",
  "/workout-library",
  "/diet",
  "/beauty",
  "/notifications",
  "/settings",
];

// NOTE: the previous user-agent sniff that redirected every phone to
// /desktop-only has been removed — the admin is now responsive down to mobile,
// so blocking small screens would hide working layouts behind a dead end.

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const token = request.cookies.get(authCookieKey)?.value;
  const role = request.cookies.get("admin_role")?.value as Role | undefined;

  const isAdminRoute = adminRoutes.some((route) => pathname.startsWith(route));
  const isAuthRoute = authRoutes.some((route) => pathname.startsWith(route));

  if (!token && isAdminRoute) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
  if (token && isAuthRoute) {
    return NextResponse.redirect(new URL("/dashboard", request.url));
  }
  if (token && role) {
    const match = Object.entries(routeRoleMap).find(([route]) => pathname.startsWith(route));
    if (match && !match[1].includes(role)) {
      return NextResponse.redirect(new URL("/dashboard", request.url));
    }
  }
  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|api).*)",
  ],
};
