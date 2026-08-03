"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { ColumnDef } from "@tanstack/react-table";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { toast } from "sonner";
import { ChevronRight, Dumbbell, Pencil, Trash2 } from "lucide-react";
import { workoutService } from "@/services/workout.service";
import type { Exercise, Workout, WorkoutDay } from "@/types";
import { PageHeader } from "@/components/common/page-header";
import { DataTable } from "@/components/common/data-table";
import { EmptyState, TableSkeleton } from "@/components/common/state";
import { ImageUploadField } from "@/components/common/image-upload-field";
import { VideoUploadField } from "@/components/common/video-upload-field";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ConfirmModal } from "@/components/ui/modal";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";

/**
 * Workout management as three drill-down CRUD tables:
 *
 *   Workouts  ->  Days (of one workout)  ->  Exercises (of one day)
 *
 * Every create and edit happens in a modal with Zod validation, replacing the
 * previous design where each level was an always-visible inline form nested in
 * expanding rows. Numeric fields are now range-checked — sets, reps and kcal
 * were parseInt'd with no bounds, so a typo like 999999 saved silently.
 */

const GOALS = ["Loss weight", "Lift & tone", "Lose belly fat", "Build muscles"];
const LEVELS = ["Beginner", "Intermediate", "Advanced"];

const SELECT_CLS =
  "focus-ring h-9 w-full rounded-lg border border-input bg-surface px-3 text-sm text-foreground";

function levelTone(level?: string | null) {
  if (level === "Beginner") return "success" as const;
  if (level === "Intermediate") return "warning" as const;
  if (level === "Advanced") return "primary" as const;
  return "default" as const;
}

// ─── Schemas ──────────────────────────────────────────────────────────────────

const workoutSchema = z.object({
  title: z.string().min(1, "Title is required").max(300),
  level: z.string().min(1),
  goal: z.string().min(1),
  duration: z.coerce
    .number({ message: "Enter a number" })
    .int()
    .min(1, "At least 1 day")
    .max(365, "365 days maximum"),
  description: z.string().max(1000).optional().or(z.literal("")),
});
type WorkoutValues = z.input<typeof workoutSchema>;

const daySchema = z.object({
  title: z.string().min(1, "Title is required").max(300),
  focus: z.string().max(200).optional().or(z.literal("")),
  imageUrl: z.string().url("A day image is required"),
  durationMinutes: z.coerce
    .number({ message: "Enter a number" })
    .int()
    .min(1, "At least 1 minute")
    .max(600, "600 minutes maximum"),
  kcal: z.coerce
    .number({ message: "Enter a number" })
    .int()
    .min(1, "At least 1 kcal")
    .max(10000, "10000 kcal maximum"),
});
type DayValues = z.input<typeof daySchema>;

const exerciseSchema = z.object({
  name: z.string().min(1, "Name is required").max(300),
  sets: z.coerce.number().int().min(1).max(50).optional(),
  reps: z.coerce.number().int().min(1).max(500).optional(),
  duration: z.coerce.number().int().min(1).max(3600).optional(),
  rest: z.coerce.number().int().min(0).max(600).optional(),
  imageUrl: z.string().url("An exercise image is required"),
  videoUrl: z.string().url("An MP4 video is required"),
});
type ExerciseValues = z.input<typeof exerciseSchema>;

// ─── Workout dialog ───────────────────────────────────────────────────────────

function WorkoutDialog({
  open,
  onClose,
  editing,
}: {
  open: boolean;
  onClose: () => void;
  editing: Workout | null;
}) {
  const qc = useQueryClient();
  const form = useForm<WorkoutValues>({
    resolver: zodResolver(workoutSchema),
    mode: "onTouched",
    values: {
      title: editing?.title ?? "",
      level: editing?.level ?? LEVELS[0],
      goal: editing?.goal ?? GOALS[0],
      duration: editing?.duration ?? 30,
      description: editing?.description ?? "",
    },
  });

  const save = useMutation({
    mutationFn: (v: WorkoutValues) => {
      const payload = workoutSchema.parse(v);
      return editing
        ? workoutService.update(editing.id, payload)
        : workoutService.create(payload as never);
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workouts"] });
      toast.success(editing ? "Workout updated" : "Workout created");
      onClose();
    },
    onError: () => toast.error("Could not save the workout"),
  });

  return (
    <Dialog open={open} onOpenChange={(n) => !n && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{editing ? "Edit workout" : "New workout"}</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form
            className="space-y-3"
            onSubmit={form.handleSubmit((v) => save.mutate(v))}
            noValidate
          >
            <FormField
              control={form.control}
              name="title"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Title *</FormLabel>
                  <FormControl>
                    <Input {...field} placeholder="Full Body Fat Burn" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <div className="grid gap-3 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="level"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Level</FormLabel>
                    <FormControl>
                      <select {...field} className={SELECT_CLS}>
                        {LEVELS.map((l) => (
                          <option key={l}>{l}</option>
                        ))}
                      </select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="goal"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Goal</FormLabel>
                    <FormControl>
                      <select {...field} className={SELECT_CLS}>
                        {GOALS.map((g) => (
                          <option key={g}>{g}</option>
                        ))}
                      </select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
            <FormField
              control={form.control}
              name="duration"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Duration (days)</FormLabel>
                  <FormControl>
                    {/* z.coerce.number() widens the input type to unknown, so the
                        value is stringified for the DOM. */}
                    <Input
                      {...field}
                      value={String(field.value ?? "")}
                      type="number"
                      placeholder="30"
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="description"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Description</FormLabel>
                  <FormControl>
                    <Input {...field} placeholder="Short description…" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <DialogFooter>
              <Button type="button" variant="ghost" onClick={onClose}>
                Cancel
              </Button>
              <Button type="submit" disabled={save.isPending}>
                {save.isPending ? "Saving…" : "Save workout"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}

// ─── Day dialog ───────────────────────────────────────────────────────────────

function DayDialog({
  open,
  onClose,
  workoutId,
  nextDayNumber,
  editing,
}: {
  open: boolean;
  onClose: () => void;
  workoutId: string;
  nextDayNumber: number;
  editing: WorkoutDay | null;
}) {
  const qc = useQueryClient();
  const form = useForm<DayValues>({
    resolver: zodResolver(daySchema),
    mode: "onTouched",
    values: {
      title: editing?.title ?? "",
      focus: editing?.focus ?? "",
      imageUrl: editing?.imageUrl ?? "",
      durationMinutes: editing?.durationMinutes ?? 30,
      kcal: editing?.kcal ?? 200,
    },
  });

  const save = useMutation({
    mutationFn: (v: DayValues) => {
      const p = daySchema.parse(v);
      return editing
        ? workoutService.updateDay(editing.id, { ...p, focus: p.focus || undefined })
        : workoutService.createDay(workoutId, {
            ...p,
            focus: p.focus || undefined,
            dayNumber: nextDayNumber,
          });
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workout-days", workoutId] });
      toast.success(editing ? "Day updated" : `Day ${nextDayNumber} added`);
      onClose();
    },
    onError: () => toast.error("Could not save the day"),
  });

  return (
    <Dialog open={open} onOpenChange={(n) => !n && onClose()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>
            {editing ? `Edit day ${editing.dayNumber}` : `Add day ${nextDayNumber}`}
          </DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form
            className="space-y-3"
            onSubmit={form.handleSubmit((v) => save.mutate(v))}
            noValidate
          >
            <FormField
              control={form.control}
              name="title"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Title *</FormLabel>
                  <FormControl>
                    <Input {...field} placeholder="Upper Body" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <FormField
              control={form.control}
              name="focus"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Focus (optional)</FormLabel>
                  <FormControl>
                    <Input {...field} placeholder="Chest & triceps" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <div className="grid gap-3 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="durationMinutes"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Duration (minutes) *</FormLabel>
                    <FormControl>
                      <Input {...field} value={String(field.value ?? "")} type="number" />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="kcal"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Calories (kcal) *</FormLabel>
                    <FormControl>
                      <Input {...field} value={String(field.value ?? "")} type="number" />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
            <FormField
              control={form.control}
              name="imageUrl"
              render={({ field }) => (
                <FormItem>
                  <ImageUploadField
                    label="Day image *"
                    value={field.value}
                    onChange={field.onChange}
                    folder="exercises"
                  />
                  <FormMessage />
                </FormItem>
              )}
            />
            <DialogFooter>
              <Button type="button" variant="ghost" onClick={onClose}>
                Cancel
              </Button>
              <Button type="submit" disabled={save.isPending}>
                {save.isPending ? "Saving…" : "Save day"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}

// ─── Exercise dialog ──────────────────────────────────────────────────────────

function ExerciseDialog({
  open,
  onClose,
  dayId,
  nextOrder,
  editing,
}: {
  open: boolean;
  onClose: () => void;
  dayId: string;
  nextOrder: number;
  editing: Exercise | null;
}) {
  const qc = useQueryClient();
  const form = useForm<ExerciseValues>({
    resolver: zodResolver(exerciseSchema),
    mode: "onTouched",
    values: {
      name: editing?.name ?? "",
      sets: editing?.sets ?? 3,
      reps: editing?.reps ?? 12,
      duration: editing?.duration ?? undefined,
      rest: editing?.rest ?? 30,
      imageUrl: editing?.imageUrl ?? "",
      videoUrl: editing?.videoUrl ?? "",
    },
  });

  const save = useMutation({
    mutationFn: (v: ExerciseValues) => {
      const p = exerciseSchema.parse(v);
      return editing
        ? workoutService.updateExercise(editing.id, p)
        : workoutService.createExercise(dayId, { ...p, order: nextOrder } as never);
    },
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["day-exercises", dayId] });
      toast.success(editing ? "Exercise updated" : "Exercise added");
      onClose();
    },
    onError: () => toast.error("Could not save the exercise"),
  });

  return (
    <Dialog open={open} onOpenChange={(n) => !n && onClose()}>
      <DialogContent className="max-w-xl">
        <DialogHeader>
          <DialogTitle>{editing ? "Edit exercise" : "Add exercise"}</DialogTitle>
        </DialogHeader>
        <Form {...form}>
          <form
            className="space-y-3"
            onSubmit={form.handleSubmit((v) => save.mutate(v))}
            noValidate
          >
            <FormField
              control={form.control}
              name="name"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Name *</FormLabel>
                  <FormControl>
                    <Input {...field} placeholder="Push ups" />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {(
                [
                  ["sets", "Sets"],
                  ["reps", "Reps"],
                  ["duration", "Seconds (alt)"],
                  ["rest", "Rest (sec)"],
                ] as const
              ).map(([name, label]) => (
                <FormField
                  key={name}
                  control={form.control}
                  name={name}
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>{label}</FormLabel>
                      <FormControl>
                        <Input {...field} value={String(field.value ?? "")} type="number" />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              ))}
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              <FormField
                control={form.control}
                name="imageUrl"
                render={({ field }) => (
                  <FormItem>
                    <ImageUploadField
                      label="Image *"
                      value={field.value}
                      onChange={field.onChange}
                      folder="exercises"
                    />
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="videoUrl"
                render={({ field }) => (
                  <FormItem>
                    <VideoUploadField
                      label="Video (MP4) *"
                      value={field.value}
                      onChange={field.onChange}
                    />
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>
            <DialogFooter>
              <Button type="button" variant="ghost" onClick={onClose}>
                Cancel
              </Button>
              <Button type="submit" disabled={save.isPending}>
                {save.isPending ? "Saving…" : "Save exercise"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type Crumb = { workout?: Workout; day?: WorkoutDay };

export default function WorkoutsPage() {
  const qc = useQueryClient();
  const [crumb, setCrumb] = useState<Crumb>({});
  const [workoutDialog, setWorkoutDialog] = useState<{ open: boolean; editing: Workout | null }>({
    open: false,
    editing: null,
  });
  const [dayDialog, setDayDialog] = useState<{ open: boolean; editing: WorkoutDay | null }>({
    open: false,
    editing: null,
  });
  const [exDialog, setExDialog] = useState<{ open: boolean; editing: Exercise | null }>({
    open: false,
    editing: null,
  });
  const [confirm, setConfirm] = useState<{ label: string; run: () => void } | null>(null);

  const level: "workouts" | "days" | "exercises" = crumb.day
    ? "exercises"
    : crumb.workout
      ? "days"
      : "workouts";

  const workoutsQ = useQuery({ queryKey: ["workouts"], queryFn: () => workoutService.list() });
  const daysQ = useQuery({
    queryKey: ["workout-days", crumb.workout?.id],
    queryFn: () => workoutService.getDays(crumb.workout!.id),
    enabled: !!crumb.workout,
  });
  const exercisesQ = useQuery({
    queryKey: ["day-exercises", crumb.day?.id],
    queryFn: () => workoutService.getExercises(crumb.day!.id),
    enabled: !!crumb.day,
  });

  const askDelete = (label: string, run: () => Promise<unknown>, invalidate: unknown[]) =>
    setConfirm({
      label,
      run: () => {
        void run()
          .then(() => {
            void qc.invalidateQueries({ queryKey: invalidate });
            toast.success(`${label} deleted`);
          })
          .catch(() => toast.error(`Could not delete ${label.toLowerCase()}`));
        setConfirm(null);
      },
    });

  const workoutCols = useMemo<ColumnDef<Workout>[]>(
    () => [
      {
        id: "title",
        accessorKey: "title",
        header: "Workout",
        enableHiding: false,
        cell: ({ row }) => (
          <button
            onClick={() => setCrumb({ workout: row.original })}
            className="flex items-center gap-2 text-left font-medium text-foreground hover:text-primary"
          >
            <Dumbbell className="h-4 w-4 shrink-0 text-muted-foreground" />
            {row.original.title}
            <ChevronRight className="h-3.5 w-3.5 text-muted-foreground" />
          </button>
        ),
      },
      {
        id: "level",
        accessorKey: "level",
        header: "Level",
        cell: ({ row }) => (
          <Badge variant={levelTone(row.original.level)}>{row.original.level}</Badge>
        ),
      },
      { id: "goal", accessorKey: "goal", header: "Goal" },
      {
        id: "duration",
        accessorKey: "duration",
        header: "Days",
        cell: ({ row }) => `${row.original.duration} days`,
      },
      {
        id: "actions",
        header: "Actions",
        enableSorting: false,
        enableHiding: false,
        cell: ({ row }) => (
          <div className="flex gap-1.5">
            <Button
              variant="ghost"
              size="sm"
              aria-label="Edit workout"
              onClick={() => setWorkoutDialog({ open: true, editing: row.original })}
            >
              <Pencil className="h-3.5 w-3.5" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              aria-label="Delete workout"
              className="text-danger"
              onClick={() =>
                askDelete("Workout", () => workoutService.delete(row.original.id), ["workouts"])
              }
            >
              <Trash2 className="h-3.5 w-3.5" />
            </Button>
          </div>
        ),
      },
    ],
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [],
  );

  const dayCols = useMemo<ColumnDef<WorkoutDay>[]>(
    () => [
      {
        id: "dayNumber",
        accessorKey: "dayNumber",
        header: "Day",
        enableHiding: false,
        cell: ({ row }) => (
          <button
            onClick={() => setCrumb((c) => ({ ...c, day: row.original }))}
            className="flex items-center gap-2 text-left font-medium text-foreground hover:text-primary"
          >
            Day {row.original.dayNumber}
            <ChevronRight className="h-3.5 w-3.5 text-muted-foreground" />
          </button>
        ),
      },
      { id: "title", accessorKey: "title", header: "Title" },
      {
        id: "focus",
        accessorKey: "focus",
        header: "Focus",
        cell: ({ row }) =>
          row.original.focus || <span className="text-xs text-muted-foreground">—</span>,
      },
      {
        id: "durationMinutes",
        accessorKey: "durationMinutes",
        header: "Duration",
        cell: ({ row }) => `${row.original.durationMinutes} min`,
      },
      {
        id: "kcal",
        accessorKey: "kcal",
        header: "Calories",
        cell: ({ row }) => `${row.original.kcal} kcal`,
      },
      {
        id: "actions",
        header: "Actions",
        enableSorting: false,
        enableHiding: false,
        cell: ({ row }) => (
          <div className="flex gap-1.5">
            <Button
              variant="ghost"
              size="sm"
              aria-label="Edit day"
              onClick={() => setDayDialog({ open: true, editing: row.original })}
            >
              <Pencil className="h-3.5 w-3.5" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              aria-label="Delete day"
              className="text-danger"
              onClick={() =>
                askDelete("Day", () => workoutService.deleteDay(row.original.id), [
                  "workout-days",
                  crumb.workout?.id,
                ])
              }
            >
              <Trash2 className="h-3.5 w-3.5" />
            </Button>
          </div>
        ),
      },
    ],
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [crumb.workout?.id],
  );

  const exerciseCols = useMemo<ColumnDef<Exercise>[]>(
    () => [
      {
        id: "name",
        accessorKey: "name",
        header: "Exercise",
        enableHiding: false,
        cell: ({ row }) => (
          <span className="font-medium text-foreground">{row.original.name}</span>
        ),
      },
      {
        id: "setsReps",
        header: "Sets × Reps",
        enableSorting: false,
        cell: ({ row }) =>
          row.original.sets || row.original.reps
            ? `${row.original.sets ?? "—"} × ${row.original.reps ?? "—"}`
            : "—",
      },
      {
        id: "duration",
        accessorKey: "duration",
        header: "Seconds",
        cell: ({ row }) => row.original.duration ?? "—",
      },
      {
        id: "rest",
        accessorKey: "rest",
        header: "Rest",
        cell: ({ row }) => (row.original.rest != null ? `${row.original.rest}s` : "—"),
      },
      {
        id: "media",
        header: "Media",
        enableSorting: false,
        cell: ({ row }) => (
          <div className="flex gap-1">
            {row.original.imageUrl && <Badge variant="outline">Image</Badge>}
            {row.original.videoUrl && <Badge variant="info">Video</Badge>}
          </div>
        ),
      },
      {
        id: "actions",
        header: "Actions",
        enableSorting: false,
        enableHiding: false,
        cell: ({ row }) => (
          <div className="flex gap-1.5">
            <Button
              variant="ghost"
              size="sm"
              aria-label="Edit exercise"
              onClick={() => setExDialog({ open: true, editing: row.original })}
            >
              <Pencil className="h-3.5 w-3.5" />
            </Button>
            <Button
              variant="ghost"
              size="sm"
              aria-label="Delete exercise"
              className="text-danger"
              onClick={() =>
                askDelete("Exercise", () => workoutService.deleteExercise(row.original.id), [
                  "day-exercises",
                  crumb.day?.id,
                ])
              }
            >
              <Trash2 className="h-3.5 w-3.5" />
            </Button>
          </div>
        ),
      },
    ],
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [crumb.day?.id],
  );

  const days = daysQ.data ?? [];
  const exercises = exercisesQ.data ?? [];
  const nextDayNumber = days.length ? Math.max(...days.map((d) => d.dayNumber)) + 1 : 1;
  const nextOrder = exercises.length ? Math.max(...exercises.map((e) => e.order ?? 0)) + 1 : 0;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <PageHeader
          title="Workout Management"
          description="Build day-by-day workout plans with exercises."
        />
        {level === "workouts" && (
          <Button onClick={() => setWorkoutDialog({ open: true, editing: null })}>
            + New workout
          </Button>
        )}
        {level === "days" && (
          <Button onClick={() => setDayDialog({ open: true, editing: null })}>
            + Add day {nextDayNumber}
          </Button>
        )}
        {level === "exercises" && (
          <Button onClick={() => setExDialog({ open: true, editing: null })}>
            + Add exercise
          </Button>
        )}
      </div>

      {/* Drill-down trail. Kept in component state rather than the URL so the
          topbar breadcrumb stays about routes, not table depth. */}
      {level !== "workouts" && (
        <nav aria-label="Workout drill-down" className="flex flex-wrap items-center gap-1 text-sm">
          <button
            onClick={() => setCrumb({})}
            className="text-muted-foreground hover:text-foreground"
          >
            Workouts
          </button>
          <ChevronRight className="h-3.5 w-3.5 text-muted-foreground" />
          <button
            onClick={() => setCrumb({ workout: crumb.workout })}
            className={
              level === "days"
                ? "font-semibold text-foreground"
                : "text-muted-foreground hover:text-foreground"
            }
          >
            {crumb.workout?.title}
          </button>
          {crumb.day && (
            <>
              <ChevronRight className="h-3.5 w-3.5 text-muted-foreground" />
              <span className="font-semibold text-foreground">Day {crumb.day.dayNumber}</span>
            </>
          )}
        </nav>
      )}

      {level === "workouts" &&
        (workoutsQ.isLoading ? (
          <TableSkeleton />
        ) : (
          <DataTable
            columns={workoutCols}
            data={workoutsQ.data ?? []}
            manualSorting={false}
            getRowId={(r) => r.id}
            minWidth={760}
            emptyState={
              <EmptyState
                title="No workouts yet"
                description="Create a plan, then add days and exercises to it."
                action={
                  <Button
                    size="sm"
                    onClick={() => setWorkoutDialog({ open: true, editing: null })}
                  >
                    + New workout
                  </Button>
                }
              />
            }
          />
        ))}

      {level === "days" &&
        (daysQ.isLoading ? (
          <TableSkeleton />
        ) : (
          <DataTable
            columns={dayCols}
            data={days}
            manualSorting={false}
            getRowId={(r) => r.id}
            minWidth={760}
            emptyState={
              <EmptyState
                title="No days yet"
                description={`"${crumb.workout?.title}" has no days. Add day 1 to get started.`}
                action={
                  <Button size="sm" onClick={() => setDayDialog({ open: true, editing: null })}>
                    + Add day 1
                  </Button>
                }
              />
            }
          />
        ))}

      {level === "exercises" &&
        (exercisesQ.isLoading ? (
          <TableSkeleton />
        ) : (
          <DataTable
            columns={exerciseCols}
            data={exercises}
            manualSorting={false}
            getRowId={(r) => r.id}
            minWidth={760}
            emptyState={
              <EmptyState
                title="No exercises yet"
                description={`Day ${crumb.day?.dayNumber} has no exercises.`}
                action={
                  <Button size="sm" onClick={() => setExDialog({ open: true, editing: null })}>
                    + Add exercise
                  </Button>
                }
              />
            }
          />
        ))}

      <WorkoutDialog
        open={workoutDialog.open}
        editing={workoutDialog.editing}
        onClose={() => setWorkoutDialog({ open: false, editing: null })}
      />
      {crumb.workout && (
        <DayDialog
          open={dayDialog.open}
          editing={dayDialog.editing}
          workoutId={crumb.workout.id}
          nextDayNumber={nextDayNumber}
          onClose={() => setDayDialog({ open: false, editing: null })}
        />
      )}
      {crumb.day && (
        <ExerciseDialog
          open={exDialog.open}
          editing={exDialog.editing}
          dayId={crumb.day.id}
          nextOrder={nextOrder}
          onClose={() => setExDialog({ open: false, editing: null })}
        />
      )}

      <ConfirmModal
        open={!!confirm}
        title={`Delete ${confirm?.label.toLowerCase() ?? "item"}?`}
        onClose={() => setConfirm(null)}
        onConfirm={() => confirm?.run()}
        confirmLabel="Delete"
      >
        This cannot be undone.
        {confirm?.label === "Day" && " Its exercises will be deleted too."}
        {confirm?.label === "Workout" && " Its days and exercises will be deleted too."}
      </ConfirmModal>
    </div>
  );
}
