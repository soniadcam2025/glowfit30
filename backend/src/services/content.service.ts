"use client";

import { api } from "@/services/api";

export const contentService = {
  async saveWorkoutPlan(payload: unknown) {
    const { data } = await api.post("/workouts", payload);
    return data;
  },
  async saveDietPlan(payload: unknown) {
    const { data } = await api.post("/diet", payload);
    return data;
  },
  async saveBeautyPost(payload: unknown) {
    const { data } = await api.post("/beauty", payload);
    return data;
  },
  async sendNotification(payload: unknown) {
    return { success: true, data: payload, message: "Notification queued" };
  },
  async saveSettings(payload: unknown) {
    return { success: true, data: payload, message: "Settings saved" };
  },
};
