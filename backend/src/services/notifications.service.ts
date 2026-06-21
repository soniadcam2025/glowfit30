import { api } from "@/services/api";
import type { ApiResponse } from "@/types";

type SendPayload = {
  title: string;
  body: string;
  userId?: string;
};

type SendResult = {
  sent: number;
  failed: number;
  total: number;
};

export const notificationsService = {
  async send(payload: SendPayload) {
    const { data } = await api.post<ApiResponse<SendResult>>(
      "/notifications/send",
      payload
    );
    return data.data;
  },
};
