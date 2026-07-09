"use client";

import { api } from "@/services/api";
import type { ApiResponse, DietDayMeals, DietPlan, DietPlanDay } from "@/types";

export const dietService = {
  async list(): Promise<DietPlan[]> {
    const { data } = await api.get<ApiResponse<{ items: DietPlan[] }>>("/diet");
    return data.data.items ?? [];
  },

  async create(payload: Omit<DietPlan, "id" | "createdAt" | "_count">): Promise<DietPlan> {
    const { data } = await api.post<ApiResponse<DietPlan>>("/diet", payload);
    return data.data;
  },

  async update(id: string, payload: Partial<Omit<DietPlan, "id" | "createdAt" | "_count">>): Promise<DietPlan> {
    const { data } = await api.patch<ApiResponse<DietPlan>>(`/diet/${id}`, payload);
    return data.data;
  },

  async delete(id: string): Promise<void> {
    await api.delete(`/diet/${id}`);
  },

  // ─── Per-day meals ─────────────────────────────────────────────────────────

  async listDays(planId: string): Promise<DietPlanDay[]> {
    const { data } = await api.get<ApiResponse<{ items: DietPlanDay[] }>>(`/diet/${planId}/days`);
    return data.data.items ?? [];
  },

  async upsertDay(planId: string, dayNumber: number, meals: DietDayMeals): Promise<DietPlanDay> {
    const { data } = await api.put<ApiResponse<DietPlanDay>>(`/diet/${planId}/days/${dayNumber}`, { meals });
    return data.data;
  },

  async deleteDay(planId: string, dayNumber: number): Promise<void> {
    await api.delete(`/diet/${planId}/days/${dayNumber}`);
  },
};
