import { api } from "@/services/api";
import type { ApiResponse } from "@/types";

export const uploadsService = {
  async upload(file: File, folder: "exercises" | "diet" = "exercises"): Promise<string> {
    const formData = new FormData();
    formData.append("file", file);
    formData.append("folder", folder);

    const { data } = await api.post<ApiResponse<{ url: string }>>("/uploads", formData, {
      headers: { "Content-Type": undefined },
    });
    return data.data.url;
  },

  async uploadVideo(file: File): Promise<string> {
    const formData = new FormData();
    formData.append("file", file);

    const { data } = await api.post<ApiResponse<{ url: string }>>("/uploads/video", formData, {
      headers: { "Content-Type": undefined },
    });
    return data.data.url;
  },
};
