export type Role = "super_admin" | "admin" | "user";

export type UserItem = {
  id: string;
  name: string;
  email: string;
  role: Role;
  isBlocked: boolean;
  createdAt: string;
  status?: "active" | "blocked";
  joinedAt?: string;
};

export type PaginatedResponse<T> = {
  items: T[];
  total: number;
  page: number;
  limit: number;
  pages: number;
};

export type ApiResponse<T> = {
  success: boolean;
  data: T;
  message: string;
};

export type ChartPoint = {
  name: string;
  users: number;
  engagement: number;
};
