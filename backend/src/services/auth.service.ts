import { api } from "@/services/api";
import type { ApiResponse, Role } from "@/types";

type MePayload = { user: { id: string; name: string; email: string; role: Role } };

export const authService = {
  async login(email: string, password: string) {
    const { data } = await api.post<ApiResponse<MePayload>>("/auth/login", { email, password });
    return data.data;
  },
  async logout() {
    const { data } = await api.post<ApiResponse<null>>("/auth/logout");
    return data;
  },
  async me() {
    const { data } = await api.get<ApiResponse<MePayload>>("/auth/me");
    return data.data;
  },
};
