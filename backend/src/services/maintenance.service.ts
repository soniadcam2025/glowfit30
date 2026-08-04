import { api } from "@/services/api";
import type { ApiResponse } from "@/types";

export type TableCounts = {
  workouts: number;
  workoutDays: number;
  exercises: number;
  progress: number;
  dietPlans: number;
  dietPlanDays: number;
  beautyPosts: number;
  libraryCategories: number;
  libraryItems: number;
  libraryExercises: number;
  glowCategories: number;
  glowShorts: number;
  /** Every table available to back up, in dependency order. */
  tables: string[];
};

export type StorageConfig = {
  provider: string;
  endpoint: string | null;
  region: string | null;
  bucketExercises: string | null;
  bucketDiet: string | null;
  accessKey: string | null;
  secretKey: string | null;
  configured: boolean;
  source: string;
};

export type ResetScope =
  | "workouts"
  | "diet"
  | "glow-reads"
  | "workout-library"
  | "glow-content";

export const CONFIRM_PHRASE: Record<ResetScope, string> = {
  workouts: "DELETE ALL WORKOUTS",
  diet: "DELETE ALL DIET PLANS",
  "glow-reads": "DELETE ALL GLOW READS",
  "workout-library": "DELETE WORKOUT LIBRARY",
  "glow-content": "DELETE ALL GLOW CONTENT",
};

export const maintenanceService = {
  async counts() {
    const { data } = await api.get<ApiResponse<TableCounts>>("/admin/maintenance/counts");
    return data.data;
  },

  /**
   * Downloads the backup workbook.
   *
   * Fetched as a blob and saved client-side rather than opening the URL
   * directly, because the API is on another origin and the request needs the
   * Authorization header — a plain link would arrive unauthenticated.
   */
  async storage() {
    const { data } = await api.get<ApiResponse<StorageConfig>>("/admin/maintenance/storage");
    return data.data;
  },

  /** `tables` empty means every table. */
  async downloadBackup(tables: string[] = []): Promise<string> {
    const res = await api.get("/admin/maintenance/backup", {
      responseType: "blob",
      params: tables.length ? { tables: tables.join(",") } : undefined,
    });

    const disposition = (res.headers["content-disposition"] as string) ?? "";
    const match = disposition.match(/filename="?([^"]+)"?/);
    const filename =
      match?.[1] ?? `glowfit-backup-${new Date().toISOString().slice(0, 10)}.xlsx`;

    const url = URL.createObjectURL(res.data as Blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);

    return filename;
  },

  async reset(scope: ResetScope, deleteMedia: boolean) {
    const { data } = await api.post<ApiResponse<Record<string, number>>>(
      `/admin/maintenance/reset/${scope}`,
      { confirm: CONFIRM_PHRASE[scope], deleteMedia },
    );
    return data.data;
  },
};
