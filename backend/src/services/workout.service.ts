"use client";

import { api } from "@/services/api";
import type { ApiResponse, Workout, WorkoutDay, Exercise } from "@/types";

export const workoutService = {
  async list(): Promise<Workout[]> {
    const { data } = await api.get<ApiResponse<{ items: Workout[] }>>("/workouts");
    return data.data.items;
  },

  async create(payload: Omit<Workout, "id" | "createdAt">): Promise<Workout> {
    const { data } = await api.post<ApiResponse<Workout>>("/workouts", payload);
    return data.data;
  },

  async update(id: string, payload: Partial<Omit<Workout, "id" | "createdAt">>): Promise<Workout> {
    const { data } = await api.patch<ApiResponse<Workout>>(`/workouts/${id}`, payload);
    return data.data;
  },

  async delete(id: string): Promise<void> {
    await api.delete(`/workouts/${id}`);
  },

  async getDays(workoutId: string): Promise<WorkoutDay[]> {
    const { data } = await api.get<ApiResponse<{ days: WorkoutDay[] }>>(`/workouts/${workoutId}/days`);
    return data.data.days;
  },

  async createDay(workoutId: string, payload: { title: string; focus?: string; dayNumber: number }): Promise<WorkoutDay> {
    const { data } = await api.post<ApiResponse<WorkoutDay>>(`/workouts/${workoutId}/days`, payload);
    return data.data;
  },

  async deleteDay(dayId: string): Promise<void> {
    await api.delete(`/workouts/days/${dayId}`);
  },

  async getExercises(dayId: string): Promise<Exercise[]> {
    const { data } = await api.get<ApiResponse<{ exercises: Exercise[] }>>(`/workouts/days/${dayId}/exercises`);
    return data.data.exercises;
  },

  async createExercise(dayId: string, payload: Omit<Exercise, "id" | "workoutDayId">): Promise<Exercise> {
    const { data } = await api.post<ApiResponse<Exercise>>(`/workouts/days/${dayId}/exercises`, payload);
    return data.data;
  },

  async updateExercise(id: string, payload: Partial<Omit<Exercise, "id" | "workoutDayId">>): Promise<Exercise> {
    const { data } = await api.patch<ApiResponse<Exercise>>(`/workouts/exercises/${id}`, payload);
    return data.data;
  },

  async deleteExercise(id: string): Promise<void> {
    await api.delete(`/workouts/exercises/${id}`);
  },
};
