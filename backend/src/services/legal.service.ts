"use client";

import { api } from "@/services/api";
import type { ApiResponse, LegalDocument } from "@/types";

export const legalService = {
  async get(): Promise<LegalDocument> {
    const { data } = await api.get<ApiResponse<LegalDocument>>("/legal");
    return data.data;
  },
  async update(payload: { title?: string; content: string }): Promise<LegalDocument> {
    const { data } = await api.patch<ApiResponse<LegalDocument>>("/legal", payload);
    return data.data;
  },
};
