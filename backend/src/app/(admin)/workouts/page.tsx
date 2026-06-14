"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { PageHeader } from "@/components/common/page-header";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ConfirmModal } from "@/components/ui/modal";
import { workoutService } from "@/services/workout.service";
import type { Workout, WorkoutDay, Exercise } from "@/types";

const GOALS = ["Loss weight", "Lift & tone", "Lose belly fat", "Build muscles"];
const LEVELS = ["Beginner", "Intermediate", "Advanced"];

// ─── Workout Form ─────────────────────────────────────────────────────────────

type WorkoutForm = { title: string; level: string; duration: string; goal: string; description: string };

const emptyWorkout = (): WorkoutForm => ({ title: "", level: "Beginner", duration: "30", goal: GOALS[0], description: "" });

function WorkoutFormPanel({ initial, onSave, onCancel, loading }: {
  initial: WorkoutForm;
  onSave: (f: WorkoutForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = (k: keyof WorkoutForm, v: string) => setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-3 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="grid gap-3 sm:grid-cols-2">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Title *</label>
          <Input value={f.title} onChange={(e) => set("title", e.target.value)} placeholder="Full Body Fat Burn" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Level</label>
          <select
            value={f.level}
            onChange={(e) => set("level", e.target.value)}
            className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950"
          >
            {LEVELS.map((l) => <option key={l}>{l}</option>)}
          </select>
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Goal</label>
          <select
            value={f.goal}
            onChange={(e) => set("goal", e.target.value)}
            className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950"
          >
            {GOALS.map((g) => <option key={g}>{g}</option>)}
          </select>
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Duration (days)</label>
          <Input type="number" value={f.duration} onChange={(e) => set("duration", e.target.value)} placeholder="30" />
        </div>
        <div className="space-y-1 sm:col-span-2">
          <label className="text-xs font-semibold text-slate-500">Description</label>
          <Input value={f.description} onChange={(e) => set("description", e.target.value)} placeholder="Short description..." />
        </div>
      </div>
      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={!f.title.trim() || loading}>
          {loading ? "Saving…" : "Save Workout"}
        </Button>
      </div>
    </div>
  );
}

// ─── Exercise Row ──────────────────────────────────────────────────────────────

function ExerciseRow({ ex, onDelete }: { ex: Exercise; onDelete: () => void }) {
  return (
    <div className="flex items-center gap-3 rounded-lg border border-slate-100 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900">
      <span className="w-5 text-center text-xs text-slate-400">{ex.order + 1}</span>
      <span className="flex-1 font-medium text-slate-800 dark:text-slate-100">{ex.name}</span>
      {ex.sets && <span className="text-xs text-slate-500">{ex.sets}×{ex.reps ?? "—"} reps</span>}
      {ex.duration && <span className="text-xs text-slate-500">{ex.duration}s</span>}
      {ex.rest && <span className="text-xs text-slate-400">rest {ex.rest}s</span>}
      <button onClick={onDelete} className="text-rose-400 hover:text-rose-600 text-xs">✕</button>
    </div>
  );
}

// ─── Add Exercise Form ─────────────────────────────────────────────────────────

type ExForm = { name: string; sets: string; reps: string; duration: string; rest: string };
const emptyEx = (): ExForm => ({ name: "", sets: "3", reps: "12", duration: "", rest: "30" });

function AddExerciseForm({ dayId, order, onAdded }: { dayId: string; order: number; onAdded: () => void }) {
  const [f, setF] = useState<ExForm>(emptyEx());
  const [loading, setLoading] = useState(false);
  const set = (k: keyof ExForm, v: string) => setF((p) => ({ ...p, [k]: v }));

  const save = async () => {
    if (!f.name.trim()) return;
    setLoading(true);
    try {
      await workoutService.createExercise(dayId, {
        name: f.name.trim(),
        sets: f.sets ? parseInt(f.sets) : undefined,
        reps: f.reps ? parseInt(f.reps) : undefined,
        duration: f.duration ? parseInt(f.duration) : undefined,
        rest: f.rest ? parseInt(f.rest) : undefined,
        order,
      });
      setF(emptyEx());
      onAdded();
      toast.success("Exercise added");
    } catch {
      toast.error("Failed to add exercise");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="grid grid-cols-2 gap-2 rounded-lg border border-dashed border-blue-300 bg-blue-50/50 p-3 sm:grid-cols-5 dark:border-blue-700 dark:bg-blue-950/20">
      <Input className="sm:col-span-2" value={f.name} onChange={(e) => set("name", e.target.value)} placeholder="Exercise name *" />
      <Input type="number" value={f.sets} onChange={(e) => set("sets", e.target.value)} placeholder="Sets" />
      <Input type="number" value={f.reps} onChange={(e) => set("reps", e.target.value)} placeholder="Reps" />
      <Input type="number" value={f.duration} onChange={(e) => set("duration", e.target.value)} placeholder="Sec (alt)" />
      <Input type="number" value={f.rest} onChange={(e) => set("rest", e.target.value)} placeholder="Rest sec" />
      <Button className="sm:col-span-4" onClick={save} disabled={!f.name.trim() || loading}>
        {loading ? "Adding…" : "+ Add Exercise"}
      </Button>
    </div>
  );
}

// ─── Day Panel ─────────────────────────────────────────────────────────────────

function DayPanel({ day, workoutId, onDeleted }: { day: WorkoutDay; workoutId: string; onDeleted: () => void }) {
  const [expanded, setExpanded] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const qc = useQueryClient();
  const exKey = ["exercises", day.id];

  const { data: exercises = [], refetch } = useQuery({
    queryKey: exKey,
    queryFn: () => workoutService.getExercises(day.id),
    enabled: expanded,
  });

  const deleteEx = useMutation({
    mutationFn: (id: string) => workoutService.deleteExercise(id),
    onSuccess: () => { void qc.invalidateQueries({ queryKey: exKey }); toast.success("Exercise deleted"); },
    onError: () => toast.error("Failed to delete"),
  });

  const deleteDay = useMutation({
    mutationFn: () => workoutService.deleteDay(day.id),
    onSuccess: () => { onDeleted(); toast.success("Day deleted"); },
    onError: () => toast.error("Failed to delete day"),
  });

  return (
    <>
      <div className="rounded-xl border border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-900">
        <button
          className="flex w-full items-center gap-3 px-4 py-3 text-left"
          onClick={() => setExpanded((v) => !v)}
        >
          <span className="flex h-7 w-7 items-center justify-center rounded-full bg-pink-100 text-xs font-bold text-pink-600 dark:bg-pink-900/40">
            {day.dayNumber}
          </span>
          <span className="flex-1 font-medium text-slate-800 dark:text-slate-100">{day.title}</span>
          {day.focus && <span className="text-xs text-slate-400">{day.focus}</span>}
          <button
            className="ml-2 text-rose-400 hover:text-rose-600 text-xs"
            onClick={(e) => { e.stopPropagation(); setConfirmDelete(true); }}
          >
            Delete
          </button>
          <span className="text-slate-400">{expanded ? "▲" : "▼"}</span>
        </button>

        {expanded && (
          <div className="border-t border-slate-100 px-4 py-3 space-y-2 dark:border-slate-700">
            {exercises.map((ex) => (
              <ExerciseRow
                key={ex.id}
                ex={ex}
                onDelete={() => deleteEx.mutate(ex.id)}
              />
            ))}
            <AddExerciseForm
              dayId={day.id}
              order={exercises.length}
              onAdded={() => void refetch()}
            />
          </div>
        )}
      </div>

      <ConfirmModal
        open={confirmDelete}
        title="Delete Day?"
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => { deleteDay.mutate(); setConfirmDelete(false); }}
        confirmLabel="Delete"
      >
        This will also delete all exercises in Day {day.dayNumber}. This cannot be undone.
      </ConfirmModal>
    </>
  );
}

// ─── Add Day Form ──────────────────────────────────────────────────────────────

function AddDayForm({ workoutId, nextDay, onAdded }: { workoutId: string; nextDay: number; onAdded: () => void }) {
  const [title, setTitle] = useState("");
  const [focus, setFocus] = useState("");
  const [loading, setLoading] = useState(false);

  const save = async () => {
    if (!title.trim()) return;
    setLoading(true);
    try {
      await workoutService.createDay(workoutId, { title: title.trim(), focus: focus.trim() || undefined, dayNumber: nextDay });
      setTitle(""); setFocus("");
      onAdded();
      toast.success(`Day ${nextDay} added`);
    } catch {
      toast.error("Failed to add day");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex gap-2 rounded-xl border border-dashed border-slate-300 bg-slate-50 p-3 dark:border-slate-600 dark:bg-slate-800/50">
      <Input value={title} onChange={(e) => setTitle(e.target.value)} placeholder={`Day ${nextDay} title (e.g. Upper Body)`} />
      <Input value={focus} onChange={(e) => setFocus(e.target.value)} placeholder="Focus (optional)" className="max-w-[180px]" />
      <Button onClick={save} disabled={!title.trim() || loading}>{loading ? "…" : `+ Day ${nextDay}`}</Button>
    </div>
  );
}

// ─── Workout Row ───────────────────────────────────────────────────────────────

function WorkoutRow({ workout, onDeleted }: { workout: Workout; onDeleted: () => void }) {
  const [expanded, setExpanded] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const qc = useQueryClient();
  const daysKey = ["days", workout.id];

  const { data: days = [], refetch } = useQuery({
    queryKey: daysKey,
    queryFn: () => workoutService.getDays(workout.id),
    enabled: expanded,
  });

  const deleteWorkout = useMutation({
    mutationFn: () => workoutService.delete(workout.id),
    onSuccess: () => { onDeleted(); toast.success("Workout deleted"); },
    onError: () => toast.error("Failed to delete"),
  });

  return (
    <>
      <Card className="p-0 overflow-hidden">
        <button
          className="flex w-full items-center gap-4 px-5 py-4 text-left hover:bg-slate-50 dark:hover:bg-slate-800/50"
          onClick={() => setExpanded((v) => !v)}
        >
          <div className="flex-1 min-w-0">
            <p className="font-semibold text-slate-800 dark:text-slate-100">{workout.title}</p>
            <p className="text-xs text-slate-500 mt-0.5">
              {workout.level} · {workout.duration} days · {workout.goal ?? "—"}
            </p>
          </div>
          {workout.description && (
            <p className="hidden text-xs text-slate-400 max-w-xs truncate sm:block">{workout.description}</p>
          )}
          <button
            className="text-xs text-rose-400 hover:text-rose-600 shrink-0"
            onClick={(e) => { e.stopPropagation(); setConfirmDelete(true); }}
          >
            Delete
          </button>
          <span className="text-slate-400 text-sm">{expanded ? "▲" : "▼"}</span>
        </button>

        {expanded && (
          <div className="border-t border-slate-100 px-5 py-4 space-y-3 dark:border-slate-700">
            {days.map((d) => (
              <DayPanel
                key={d.id}
                day={d}
                workoutId={workout.id}
                onDeleted={() => { void qc.invalidateQueries({ queryKey: daysKey }); }}
              />
            ))}
            <AddDayForm workoutId={workout.id} nextDay={days.length + 1} onAdded={() => void refetch()} />
          </div>
        )}
      </Card>

      <ConfirmModal
        open={confirmDelete}
        title="Delete Workout?"
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => { deleteWorkout.mutate(); setConfirmDelete(false); }}
        confirmLabel="Delete"
      >
        "{workout.title}" and all its days and exercises will be permanently deleted.
      </ConfirmModal>
    </>
  );
}

// ─── Page ──────────────────────────────────────────────────────────────────────

export default function WorkoutsPage() {
  const [creating, setCreating] = useState(false);
  const qc = useQueryClient();

  const { data: workouts = [], isLoading } = useQuery({
    queryKey: ["workouts"],
    queryFn: () => workoutService.list(),
  });

  const createWorkout = useMutation({
    mutationFn: (f: WorkoutForm) =>
      workoutService.create({
        title: f.title.trim(),
        level: f.level,
        duration: parseInt(f.duration) || 30,
        goal: f.goal,
        description: f.description.trim() || undefined,
      }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workouts"] });
      setCreating(false);
      toast.success("Workout created");
    },
    onError: () => toast.error("Failed to create workout"),
  });

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <PageHeader
          title="Workout Management"
          description="Build day-by-day workout plans with exercises."
        />
        {!creating && (
          <Button onClick={() => setCreating(true)}>+ New Workout</Button>
        )}
      </div>

      {creating && (
        <WorkoutFormPanel
          initial={emptyWorkout()}
          onSave={(f) => createWorkout.mutate(f)}
          onCancel={() => setCreating(false)}
          loading={createWorkout.isPending}
        />
      )}

      {isLoading ? (
        <Card><p className="text-sm text-slate-400">Loading workouts…</p></Card>
      ) : workouts.length === 0 ? (
        <Card><p className="text-sm text-slate-400">No workouts yet. Create your first one above.</p></Card>
      ) : (
        <div className="space-y-3">
          {workouts.map((w) => (
            <WorkoutRow
              key={w.id}
              workout={w}
              onDeleted={() => void qc.invalidateQueries({ queryKey: ["workouts"] })}
            />
          ))}
        </div>
      )}
    </div>
  );
}
