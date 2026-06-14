"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { usersService } from "@/services/users.service";
import type { PaginatedResponse, UserItem } from "@/types";

export type UsersQuery = {
  page: number;
  pageSize: number;
  search?: string;
  status?: "active" | "blocked" | "all";
  goal?: string;
  fitnessLevel?: string;
  sortBy?: "name" | "email" | "createdAt" | "goal" | "fitnessLevel";
  sortDir?: "asc" | "desc";
};

export function useUsers(query: UsersQuery) {
  return useQuery({
    queryKey: ["users", query],
    queryFn: () => usersService.list(query),
  });
}

export function useUserDetails(id?: string) {
  return useQuery({
    queryKey: ["users", "detail", id],
    queryFn: () => usersService.getById(id as string),
    enabled: !!id,
  });
}

export function useUserProgress(id?: string) {
  return useQuery({
    queryKey: ["users", "progress", id],
    queryFn: () => usersService.getProgress(id as string),
    enabled: !!id,
  });
}

function useToggleBlock(query: UsersQuery, blocked: boolean) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => (blocked ? usersService.block(id) : usersService.unblock(id)),
    onMutate: async (id) => {
      await queryClient.cancelQueries({ queryKey: ["users", query] });
      const previous = queryClient.getQueryData<PaginatedResponse<UserItem>>(["users", query]);
      queryClient.setQueryData<PaginatedResponse<UserItem>>(["users", query], (old) => {
        if (!old) return old;
        return {
          ...old,
          items: old.items.map((u) =>
            u.id === id ? { ...u, isBlocked: blocked, status: blocked ? "blocked" : "active" } : u,
          ),
        };
      });
      return { previous };
    },
    onError: (_error, _id, context) => {
      if (context?.previous) queryClient.setQueryData(["users", query], context.previous);
    },
    onSettled: () => { void queryClient.invalidateQueries({ queryKey: ["users"] }); },
  });
}

export function useBlockUser(query: UsersQuery) { return useToggleBlock(query, true); }
export function useUnblockUser(query: UsersQuery) { return useToggleBlock(query, false); }
