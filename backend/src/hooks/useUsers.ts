"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { usersService } from "@/services/users.service";
import type { PaginatedResponse, UserItem } from "@/types";

type UsersQuery = { page: number; pageSize: number; search?: string; status?: string };

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

export function useBlockUser(query: UsersQuery) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => usersService.block(id),
    onMutate: async (id) => {
      await queryClient.cancelQueries({ queryKey: ["users", query] });
      const previous = queryClient.getQueryData<PaginatedResponse<UserItem>>(["users", query]);
      queryClient.setQueryData<PaginatedResponse<UserItem>>(["users", query], (old) => {
        if (!old) return old;
        return {
          ...old,
          items: old.items.map((u) =>
            u.id === id ? { ...u, isBlocked: true, status: "blocked" } : u,
          ),
        };
      });
      return { previous };
    },
    onError: (_error, _id, context) => {
      if (context?.previous) {
        queryClient.setQueryData(["users", query], context.previous);
      }
    },
    onSettled: () => {
      void queryClient.invalidateQueries({ queryKey: ["users"] });
    },
  });
}
