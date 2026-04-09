import { NextResponse } from "next/server";
import { authCookieKey } from "@/lib/constants";
import type { ApiResponse } from "@/types";

function getUpstreamBase(): string | null {
  const raw = process.env.NEXT_PUBLIC_API_URL?.trim();
  if (!raw) return null;
  return raw.replace(/\/$/, "");
}

export async function POST(request: Request) {
  const base = getUpstreamBase();
  if (!base) {
    return NextResponse.json({ success: false, data: null as null, message: "NEXT_PUBLIC_API_URL is not set" }, { status: 500 });
  }

  const cookieHeader = request.headers.get("cookie") ?? "";
  const upstream = await fetch(`${base}/auth/logout`, {
    method: "POST",
    headers: cookieHeader ? { Cookie: cookieHeader } : {},
  });

  const data = (await upstream.json()) as ApiResponse<null>;
  const res = NextResponse.json(data, { status: upstream.status });

  res.cookies.set(authCookieKey, "", { path: "/", maxAge: 0 });
  res.cookies.set("admin_role", "", { path: "/", maxAge: 0 });

  return res;
}
