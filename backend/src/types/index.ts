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

export type WorkoutLibraryTag = {
  emoji: string;
  label: string;
  background: string;
  foreground: string;
};

export type WorkoutLibraryCategory = {
  id: string;
  name: string;
  headingLine1: string;
  headingLine2: string;
  description: string;
  heroImageUrl?: string;
  tags: WorkoutLibraryTag[];
  section: string;
  cardTagline: string;
  cardImageUrl?: string;
  cardBackground: string;
  cardTitleColor: string;
  order: number;
  createdAt: string;
};

export type WorkoutLibraryDifficulty = "Beginner" | "Intermediate" | "Advanced";

export type WorkoutLibraryExercise = {
  id: string;
  workoutLibraryItemId: string;
  name: string;
  durationSeconds: number;
  imageUrl?: string;
  videoUrl?: string;
  order: number;
};

export type WorkoutLibraryItem = {
  id: string;
  isFeatured: boolean;
  category: string;
  difficulty: WorkoutLibraryDifficulty;
  titleLine1: string;
  titleScript: string;
  description: string;
  heroImageUrl?: string;
  durationMinutes: number;
  kcalLabel: string;
  focusLabel: string;
  tags: WorkoutLibraryTag[];
  order: number;
  createdAt: string;
  exercises?: WorkoutLibraryExercise[];
  _count?: { exercises: number };
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

// ─── Glow screen content ────────────────────────────────────────────────────

export type GlowTopic = { emoji: string; label: string };

export type GlowSectionItem = { imageUrl?: string; videoUrl?: string; title: string; description: string };

export type GlowSections = {
  problemCause: GlowSectionItem[];
  solution: GlowSectionItem[];
  tips: GlowSectionItem[];
};

export type BeautyPost = {
  id: string;
  title: string;
  content: string;
  imageUrl?: string;
  tag: string;
  tagColor: string;
  tagBackground: string;
  minutesRead: number;
  categoryId?: string | null;
  resultBadge?: string | null;
  chips: GlowTopic[];
  sections: Partial<GlowSections>;
  isPremium: boolean;
  order: number;
  createdAt: string;
};

export type GlowCategory = {
  id: string;
  emoji: string;
  title: string;
  subtitle: string;
  background: string;
  heroImageUrl?: string | null;
  topics: GlowTopic[];
  order: number;
  createdAt: string;
};

export type GlowCategoryDetail = GlowCategory & {
  postsCount: number;
  shortsCount: number;
};

export type GlowShort = {
  id: string;
  imageUrl?: string;
  duration: string;
  title: string;
  views: string;
  categoryId?: string | null;
  content?: string | null;
  resultBadge?: string | null;
  chips: GlowTopic[];
  sections: Partial<GlowSections>;
  isPremium: boolean;
  order: number;
  createdAt: string;
};

export type LegalDocument = {
  id: string;
  title: string;
  content: string;
  updatedAt: string;
};
