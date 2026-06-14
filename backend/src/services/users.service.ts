import { api } from "@/services/api";
import type { ApiResponse, PaginatedResponse, UserDetail, UserItem, UserProgress } from "@/types";

function mapUser(item: UserItem): UserItem {
  return {
    ...item,
    status: item.isBlocked ? "blocked" : "active",
    joinedAt: new Date(item.createdAt).toLocaleDateString(),
  };
}

export const usersService = {
  async list(query: { page: number; pageSize: number; search?: string; status?: string; goal?: string; fitnessLevel?: string; sortBy?: string; sortDir?: string }) {
    const { data } = await api.get<ApiResponse<PaginatedResponse<UserItem>>>("/users", {
      params: {
        page: query.page,
        limit: query.pageSize,
        q: query.search || undefined,
        status: query.status !== "all" ? query.status : undefined,
        goal: query.goal || undefined,
        fitnessLevel: query.fitnessLevel || undefined,
        sortBy: query.sortBy || undefined,
        sortDir: query.sortDir || undefined,
      },
    });
    return {
      ...data.data,
      items: data.data.items.map(mapUser),
    };
  },
  async getById(id: string): Promise<UserDetail> {
    const { data } = await api.get<ApiResponse<UserDetail>>(`/users/${id}`);
    return { ...mapUser(data.data), ...data.data };
  },

  async getProgress(id: string): Promise<UserProgress> {
    const { data } = await api.get<ApiResponse<UserProgress>>(`/users/${id}/progress`);
    return data.data;
  },
  async block(id: string) {
    const { data } = await api.patch<ApiResponse<UserItem>>(`/users/${id}/block`, {
      isBlocked: true,
    });
    return mapUser(data.data);
  },

  async unblock(id: string) {
    const { data } = await api.patch<ApiResponse<UserItem>>(`/users/${id}/block`, {
      isBlocked: false,
    });
    return mapUser(data.data);
  },
};
