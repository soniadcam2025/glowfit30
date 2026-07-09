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
  imageUrl?: string;
  durationMinutes?: number;
  kcal?: number;
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
  videoUrl?: string;
  order: number;
};

export type DietMealItem = {
  type: string; // breakfast | mid_morning | lunch | snack | dinner
  label: string;
  time?: string;
  desc?: string;
  kcal?: number;
  image?: string;
};

export type DietDayMeals = {
  items?: DietMealItem[];
  tags?: string[];
  waterTarget?: number;
  // legacy plan-level fields (old admin form)
  breakfast?: string;
  lunch?: string;
  dinner?: string;
  snacks?: string;
};

export type DietPlanDay = {
  id: string;
  dietPlanId: string;
  dayNumber: number;
  meals: DietDayMeals;
  createdAt: string;
};

export type DietPlan = {
  id: string;
  type: string; // diet style: Vegetarian | Non-Vegetarian | Vegan | Balanced
  goal?: string | null;
  calories: number;
  meals: DietDayMeals;
  imageUrl?: string;
  createdAt: string;
  _count?: { days: number };
};

export type UserDetail = UserItem & {
  dietStyle?: string | null;
  targetWeight?: number | null;
  focusAreas?: string[];
  dob?: string | null;
  height?: number | null;
  weight?: number | null;
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
    streak: number;
  };
};

export type ChartDataPoint = { date: string; count: number };

export type AnalyticsData = {
  signupsPerDay: ChartDataPoint[];
  completionsPerDay: ChartDataPoint[];
  activeUsersThisWeek: number;
  totalSignupsThisWeek: number;
  totalCompletionsThisWeek: number;
};
