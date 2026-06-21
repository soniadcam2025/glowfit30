import type { NextRequest } from "next/server";
import { NextResponse } from "next/server";
import { authCookieKey, routeRoleMap } from "@/lib/constants";
import type { Role } from "@/types";

const authRoutes = ["/login"];
const adminRoutes = [
  "/dashboard",
  "/users",
  "/workouts",
  "/diet",
  "/beauty",
  "/notifications",
  "/settings",
];

const mobileUserAgent = /Mobile|Android|iPhone|iPod|IEMobile|BlackBerry|Opera Mini/i;

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (pathname !== "/desktop-only") {
    const userAgent = request.headers.get("user-agent") ?? "";
    if (mobileUserAgent.test(userAgent)) {
      return NextResponse.redirect(new URL("/desktop-only", request.url));
    }
  }

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
