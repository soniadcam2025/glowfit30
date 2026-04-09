import axios from "axios";

const baseURL = process.env.NEXT_PUBLIC_API_URL?.trim();

export const api = axios.create({
  baseURL,
  withCredentials: true,
  headers: {
    "Content-Type": "application/json",
  },
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const status = error?.response?.status;
    const url = error?.config?.url || "";
    if (status === 401 && !url.includes("/auth/login")) {
      if (typeof window !== "undefined") {
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  },
);
