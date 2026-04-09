import { adminJwtStorageKey } from "@/lib/constants";
import { api } from "@/services/api";
import type { ApiResponse, Role } from "@/types";

type MePayload = { user: { id: string; name: string; email: string; role: Role }; token?: string };

async function postSameOriginJson<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    credentials: "include",
    body: JSON.stringify(body),
  });
  const json = (await res.json()) as T;
  if (!res.ok) {
    throw new Error("request failed");
  }
  return json;
}

export const authService = {
  async login(email: string, password: string) {
    const { data } = await postSameOriginJson<ApiResponse<MePayload>>("/api/auth/login", { email, password });
    if (typeof window !== "undefined") {
      if (data.token) {
        localStorage.setItem(adminJwtStorageKey, data.token);
      }
    }
    return { user: data.user };
  },
  async logout() {
    if (typeof window !== "undefined") {
      localStorage.removeItem(adminJwtStorageKey);
    }
    const { data } = await postSameOriginJson<ApiResponse<null>>("/api/auth/logout", {});
    return data;
  },
  async me() {
    const { data } = await api.get<ApiResponse<MePayload>>("/auth/me");
    return data.data;
  },
};
