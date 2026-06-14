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
  photoUrl?: string | null;
  fitnessLevel?: string | null;
  goal?: string | null;
  firebaseUid?: string | null;
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

export type Workout = {
  id: string;
  title: string;
  level: string;
  duration: number;
  imageUrl?: string;
  description?: string;
  goal?: string;
  createdAt: string;
};

export type WorkoutDay = {
  id: string;
  workoutId: string;
  dayNumber: number;
  title: string;
  focus?: string;
  exercises?: Exercise[];
  _count?: { exercises: number };
};

export type Exercise = {
  id: string;
  workoutDayId: string;
  name: string;
  sets?: number;
  reps?: number;
  duration?: number;
  rest?: number;
  imageUrl?: string;
  gifUrl?: string;
  order: number;
};

export type DietPlan = {
  id: string;
  type: string;
  calories: number;
  meals: {
    breakfast?: string;
    lunch?: string;
    dinner?: string;
    snacks?: string;
  };
  createdAt: string;
};

export type UserDetail = UserItem & {
  photoUrl?: string;
  fitnessLevel?: string;
  goal?: string;
  dietStyle?: string;
  targetWeight?: number;
  focusAreas?: string[];
  dob?: string;
  height?: number;
  weight?: number;
};

export type UserProgress = {
  completions: Array<{
    id: string;
    completedAt: string;
    caloriesBurned?: number;
    durationMin?: number;
    workoutDay: { title: string; dayNumber: number; workoutId: string };
  }>;
  stats: {
    totalSessions: number;
    totalCalories: number;
    totalMinutes: number;
  };
};
