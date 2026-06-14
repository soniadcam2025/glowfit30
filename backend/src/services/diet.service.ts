"use client";

import { api } from "@/services/api";
import type { ApiResponse, DietPlan } from "@/types";

export const dietService = {
  async list(): Promise<DietPlan[]> {
    const { data } = await api.get<ApiResponse<{ items: DietPlan[] }>>("/diet");
    return data.data.items ?? [];
  },

  async create(payload: Omit<DietPlan, "id" | "createdAt">): Promise<DietPlan> {
    const { data } = await api.post<ApiResponse<DietPlan>>("/diet", payload);
    return data.data;
  },

  async update(id: string, payload: Partial<Omit<DietPlan, "id" | "createdAt">>): Promise<DietPlan> {
    const { data } = await api.patch<ApiResponse<DietPlan>>(`/diet/${id}`, payload);
    return data.data;
  },

  async delete(id: string): Promise<void> {
    await api.delete(`/diet/${id}`);
  },
};
