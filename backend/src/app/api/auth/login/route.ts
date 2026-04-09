import { NextResponse } from "next/server";
import { authCookieKey } from "@/lib/constants";
import type { ApiResponse } from "@/types";
import type { Role } from "@/types";

type MePayload = { user: { id: string; name: string; email: string; role: Role }; token?: string };

const authCookieName = process.env.AUTH_COOKIE_NAME?.trim() || "token";

function extractTokenFromUpstream(upstream: Response): string | null {
  const cookies = typeof upstream.headers.getSetCookie === "function" ? upstream.headers.getSetCookie() : [];
  const prefix = `${authCookieName}=`;
  for (const line of cookies) {
    if (line.startsWith(prefix)) {
      const value = line.slice(prefix.length).split(";")[0];
      return value || null;
    }
  }
  const raw = upstream.headers.get("set-cookie");
  if (!raw) return null;
  const m = raw.match(new RegExp(`${authCookieName}=([^;]+)`));
  return m?.[1] ?? null;
}

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

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ success: false, data: null as null, message: "Invalid JSON" }, { status: 400 });
  }

  const upstream = await fetch(`${base}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const data = (await upstream.json()) as ApiResponse<MePayload>;
  const jwt = upstream.ok && data.success && data.data ? extractTokenFromUpstream(upstream) : null;
  if (jwt && data.data) {
    data.data = { ...data.data, token: jwt };
  }

  const res = NextResponse.json(data, { status: upstream.status });

  if (upstream.ok && jwt) {
    const reqUrl = new URL(request.url);
    const secure = reqUrl.protocol === "https:";
    res.cookies.set(authCookieKey, jwt, {
      httpOnly: true,
      secure,
      sameSite: secure ? "none" : "lax",
      path: "/",
      maxAge: 7 * 24 * 60 * 60,
    });
  }

  if (upstream.ok && data.success && data.data?.user?.role) {
    res.cookies.set("admin_role", data.data.user.role, {
      path: "/",
      maxAge: 7 * 24 * 60 * 60,
      sameSite: "lax",
      httpOnly: false,
    });
  }

  return res;
}
