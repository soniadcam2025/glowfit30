import { NextResponse } from "next/server";
import type { ApiResponse } from "@/types";

function getUpstreamBase(): string {
  return (process.env.NEXT_PUBLIC_API_URL?.trim() ?? "").replace(/\/$/, "");
}

export async function POST(request: Request) {
  const base = getUpstreamBase();
  if (!base) {
    return NextResponse.json(
      { success: false, data: null, message: "NEXT_PUBLIC_API_URL is not set" },
      { status: 500 },
    );
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ success: false, data: null, message: "Invalid JSON" }, { status: 400 });
  }

  const upstream = await fetch(`${base}/auth/reset-password`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  const data = (await upstream.json()) as ApiResponse<null>;
  return NextResponse.json(data, { status: upstream.status });
}
