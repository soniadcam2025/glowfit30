"use client";

import { api } from "@/services/api";
import type { ApiResponse, BeautyPost, GlowCategory, GlowCategoryDetail, GlowShort } from "@/types";

export const glowContentService = {
  // ─── Reads (BeautyPost) ─────────────────────────────────────────────────
  async listReads(): Promise<BeautyPost[]> {
    const { data } = await api.get<ApiResponse<{ items: BeautyPost[] }>>("/beauty");
    return data.data.items ?? [];
  },
  async getCategoryDetail(id: string): Promise<GlowCategoryDetail> {
    const { data } = await api.get<ApiResponse<GlowCategoryDetail>>(`/glow/categories/${id}`);
    return data.data;
  },
  async createRead(payload: Omit<BeautyPost, "id" | "createdAt">): Promise<BeautyPost> {
    const { data } = await api.post<ApiResponse<BeautyPost>>("/beauty", payload);
    return data.data;
  },
  async updateRead(id: string, payload: Partial<Omit<BeautyPost, "id" | "createdAt">>): Promise<BeautyPost> {
    const { data } = await api.patch<ApiResponse<BeautyPost>>(`/beauty/${id}`, payload);
    return data.data;
  },
  async deleteRead(id: string): Promise<void> {
    await api.delete(`/beauty/${id}`);
  },

  // ─── Categories ("Explore by Goals") ────────────────────────────────────
  async listCategories(): Promise<GlowCategory[]> {
    const { data } = await api.get<ApiResponse<{ categories: GlowCategory[] }>>("/glow/categories");
    return data.data.categories ?? [];
  },
  async createCategory(payload: Omit<GlowCategory, "id" | "createdAt">): Promise<GlowCategory> {
    const { data } = await api.post<ApiResponse<GlowCategory>>("/glow/categories", payload);
    return data.data;
  },
  async updateCategory(id: string, payload: Partial<Omit<GlowCategory, "id" | "createdAt">>): Promise<GlowCategory> {
    const { data } = await api.patch<ApiResponse<GlowCategory>>(`/glow/categories/${id}`, payload);
    return data.data;
  },
  async deleteCategory(id: string): Promise<void> {
    await api.delete(`/glow/categories/${id}`);
  },

  // ─── Shorts ("Shorts & Quick Tips") ─────────────────────────────────────
  async listShorts(): Promise<GlowShort[]> {
    const { data } = await api.get<ApiResponse<{ shorts: GlowShort[] }>>("/glow/shorts");
    return data.data.shorts ?? [];
  },
  async createShort(payload: Omit<GlowShort, "id" | "createdAt">): Promise<GlowShort> {
    const { data } = await api.post<ApiResponse<GlowShort>>("/glow/shorts", payload);
    return data.data;
  },
  async updateShort(id: string, payload: Partial<Omit<GlowShort, "id" | "createdAt">>): Promise<GlowShort> {
    const { data } = await api.patch<ApiResponse<GlowShort>>(`/glow/shorts/${id}`, payload);
    return data.data;
  },
  async deleteShort(id: string): Promise<void> {
    await api.delete(`/glow/shorts/${id}`);
  },
};
