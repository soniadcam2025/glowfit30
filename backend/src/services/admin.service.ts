import { api } from "@/services/api";
import type { ApiResponse } from "@/types";

type Stats = {
  totalUsers: number;
  activeUsers: number;
  blockedUsers: number;
  generatedAt: string;
};

export const adminService = {
  async getStats() {
    const { data } = await api.get<ApiResponse<Stats>>("/admin/stats");
    return data.data;
  },
  async getAnalytics() {
    const { data } = await api.get<ApiResponse<unknown>>("/admin/analytics");
    return data.data;
  },
};
