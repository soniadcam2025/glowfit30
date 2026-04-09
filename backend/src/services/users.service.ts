import { api } from "@/services/api";
import type { ApiResponse, PaginatedResponse, UserItem } from "@/types";

function mapUser(item: UserItem): UserItem {
  return {
    ...item,
    status: item.isBlocked ? "blocked" : "active",
    joinedAt: new Date(item.createdAt).toLocaleDateString(),
  };
}

export const usersService = {
  async list(query: { page: number; pageSize: number; search?: string }) {
    const { data } = await api.get<ApiResponse<PaginatedResponse<UserItem>>>("/users", {
      params: {
        page: query.page,
        limit: query.pageSize,
        q: query.search || undefined,
      },
    });
    return {
      ...data.data,
      items: data.data.items.map(mapUser),
    };
  },
  async getById(id: string) {
    const { data } = await api.get<ApiResponse<UserItem>>(`/users/${id}`);
    return mapUser(data.data);
  },
  async block(id: string) {
    const { data } = await api.patch<ApiResponse<UserItem>>(`/users/${id}/block`, {
      isBlocked: true,
    });
    return mapUser(data.data);
  },
};
