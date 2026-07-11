"use client";

import { api } from "@/services/api";
import type { ApiResponse, WorkoutLibraryExercise, WorkoutLibraryItem } from "@/types";

export const workoutLibraryService = {
  async list(): Promise<WorkoutLibraryItem[]> {
    const { data } = await api.get<ApiResponse<{ items: WorkoutLibraryItem[] }>>("/workout-library");
    return data.data.items ?? [];
  },

  async get(id: string): Promise<WorkoutLibraryItem> {
    const { data } = await api.get<ApiResponse<WorkoutLibraryItem>>(`/workout-library/${id}`);
    return data.data;
  },

  async create(payload: Omit<WorkoutLibraryItem, "id" | "createdAt" | "exercises" | "_count">): Promise<WorkoutLibraryItem> {
    const { data } = await api.post<ApiResponse<WorkoutLibraryItem>>("/workout-library", payload);
    return data.data;
  },

  async update(
    id: string,
    payload: Partial<Omit<WorkoutLibraryItem, "id" | "createdAt" | "exercises" | "_count">>,
  ): Promise<WorkoutLibraryItem> {
    const { data } = await api.patch<ApiResponse<WorkoutLibraryItem>>(`/workout-library/${id}`, payload);
    return data.data;
  },

  async delete(id: string): Promise<void> {
    await api.delete(`/workout-library/${id}`);
  },

  // ─── Exercises ───────────────────────────────────────────────────────────

  async listExercises(itemId: string): Promise<WorkoutLibraryExercise[]> {
    const { data } = await api.get<ApiResponse<{ exercises: WorkoutLibraryExercise[] }>>(
      `/workout-library/${itemId}/exercises`,
    );
    return data.data.exercises ?? [];
  },

  async createExercise(
    itemId: string,
    payload: Omit<WorkoutLibraryExercise, "id" | "workoutLibraryItemId">,
  ): Promise<WorkoutLibraryExercise> {
    const { data } = await api.post<ApiResponse<WorkoutLibraryExercise>>(
      `/workout-library/${itemId}/exercises`,
      payload,
    );
    return data.data;
  },

  async updateExercise(
    exerciseId: string,
    payload: Partial<Omit<WorkoutLibraryExercise, "id" | "workoutLibraryItemId">>,
  ): Promise<WorkoutLibraryExercise> {
    const { data } = await api.patch<ApiResponse<WorkoutLibraryExercise>>(
      `/workout-library/exercises/${exerciseId}`,
      payload,
    );
    return data.data;
  },

  async deleteExercise(exerciseId: string): Promise<void> {
    await api.delete(`/workout-library/exercises/${exerciseId}`);
  },
};
