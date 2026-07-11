"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { PageHeader } from "@/components/common/page-header";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ConfirmModal } from "@/components/ui/modal";
import { ImageUploadField } from "@/components/common/image-upload-field";
import { VideoUploadField } from "@/components/common/video-upload-field";
import { workoutLibraryService } from "@/services/workout-library.service";
import type { WorkoutLibraryExercise, WorkoutLibraryItem, WorkoutLibraryTag } from "@/types";

// ─── Item form ────────────────────────────────────────────────────────────────

type ItemForm = {
  category: string;
  titleLine1: string;
  titleScript: string;
  description: string;
  heroImageUrl: string;
  durationMinutes: string;
  kcalLabel: string;
  focusLabel: string;
  tags: WorkoutLibraryTag[];
  order: string;
};

const emptyTag = (): WorkoutLibraryTag => ({
  emoji: "🔥",
  label: "",
  background: "#FFE0EC",
  foreground: "#C4185A",
});

const empty = (): ItemForm => ({
  category: "",
  titleLine1: "",
  titleScript: "",
  description: "",
  heroImageUrl: "",
  durationMinutes: "15",
  kcalLabel: "120-160",
  focusLabel: "",
  tags: [emptyTag()],
  order: "0",
});

function itemToForm(i: WorkoutLibraryItem): ItemForm {
  return {
    category: i.category,
    titleLine1: i.titleLine1,
    titleScript: i.titleScript,
    description: i.description,
    heroImageUrl: i.heroImageUrl ?? "",
    durationMinutes: String(i.durationMinutes),
    kcalLabel: i.kcalLabel,
    focusLabel: i.focusLabel,
    tags: i.tags.length > 0 ? i.tags : [emptyTag()],
    order: String(i.order),
  };
}

function formToPayload(f: ItemForm) {
  return {
    category: f.category.trim(),
    titleLine1: f.titleLine1.trim(),
    titleScript: f.titleScript.trim(),
    description: f.description.trim(),
    heroImageUrl: f.heroImageUrl.trim() || undefined,
    durationMinutes: parseInt(f.durationMinutes) || 0,
    kcalLabel: f.kcalLabel.trim(),
    focusLabel: f.focusLabel.trim(),
    tags: f.tags.filter((t) => t.label.trim()),
    order: parseInt(f.order) || 0,
  };
}

function ItemFormPanel({ initial, onSave, onCancel, loading }: {
  initial: ItemForm;
  onSave: (f: ItemForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof ItemForm>(k: K, v: ItemForm[K]) =>
    setF((p) => ({ ...p, [k]: v }));

  const setTag = (i: number, patch: Partial<WorkoutLibraryTag>) =>
    setF((p) => ({
      ...p,
      tags: p.tags.map((t, idx) => (idx === i ? { ...t, ...patch } : t)),
    }));

  return (
    <div className="space-y-4 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="grid gap-3 sm:grid-cols-3">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Category tag *</label>
          <Input value={f.category} onChange={(e) => set("category", e.target.value)} placeholder="Abs" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Title (bold part) *</label>
          <Input value={f.titleLine1} onChange={(e) => set("titleLine1", e.target.value)} placeholder="Belly Fat" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Title (script part) *</label>
          <Input value={f.titleScript} onChange={(e) => set("titleScript", e.target.value)} placeholder="Blast" />
        </div>
      </div>

      <div className="space-y-1">
        <label className="text-xs font-semibold text-slate-500">Description *</label>
        <Input
          value={f.description}
          onChange={(e) => set("description", e.target.value)}
          placeholder="A fat-burning core workout to flatten your stomach and strengthen your abs."
        />
      </div>

      <div className="grid gap-3 sm:grid-cols-4">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Duration (min) *</label>
          <Input type="number" value={f.durationMinutes} onChange={(e) => set("durationMinutes", e.target.value)} />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Kcal label *</label>
          <Input value={f.kcalLabel} onChange={(e) => set("kcalLabel", e.target.value)} placeholder="120-160" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Focus label *</label>
          <Input value={f.focusLabel} onChange={(e) => set("focusLabel", e.target.value)} placeholder="Core Focus" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Sort order</label>
          <Input type="number" value={f.order} onChange={(e) => set("order", e.target.value)} />
        </div>
      </div>

      <ImageUploadField
        label="Hero image"
        value={f.heroImageUrl}
        onChange={(url) => set("heroImageUrl", url)}
        folder="exercises"
      />

      <div className="space-y-2">
        <p className="text-xs font-semibold text-slate-500">Tags (e.g. Fat Burn, Core Focus, No Equipment)</p>
        {f.tags.map((t, i) => (
          <div key={i} className="grid grid-cols-[56px_1fr_90px_90px_auto] items-center gap-2">
            <Input value={t.emoji} onChange={(e) => setTag(i, { emoji: e.target.value })} placeholder="🔥" />
            <Input value={t.label} onChange={(e) => setTag(i, { label: e.target.value })} placeholder="Fat Burn" />
            <input
              type="color"
              value={t.background}
              onChange={(e) => setTag(i, { background: e.target.value })}
              className="h-9 w-full rounded-lg border border-slate-300 dark:border-slate-700"
              title="Background color"
            />
            <input
              type="color"
              value={t.foreground}
              onChange={(e) => setTag(i, { foreground: e.target.value })}
              className="h-9 w-full rounded-lg border border-slate-300 dark:border-slate-700"
              title="Text color"
            />
            <Button
              variant="ghost"
              className="text-xs px-2 py-2 text-red-500"
              onClick={() => setF((p) => ({ ...p, tags: p.tags.filter((_, idx) => idx !== i) }))}
            >
              Remove
            </Button>
          </div>
        ))}
        <Button
          variant="secondary"
          className="text-xs px-3 py-1.5"
          onClick={() => setF((p) => ({ ...p, tags: [...p.tags, emptyTag()] }))}
        >
          + Add Tag
        </Button>
      </div>

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading}>
          {loading ? "Saving…" : "Save Workout"}
        </Button>
      </div>
    </div>
  );
}

// ─── Exercise manager ───────────────────────────────────────────────────────

type ExForm = {
  name: string;
  durationSeconds: string;
  imageUrl: string;
  videoUrl: string;
};

const emptyEx = (): ExForm => ({ name: "", durationSeconds: "45", imageUrl: "", videoUrl: "" });

function ExerciseRow({ itemId, exercise, order, onSaved, onDeleted }: {
  itemId: string;
  exercise?: WorkoutLibraryExercise;
  order: number;
  onSaved: () => void;
  onDeleted: () => void;
}) {
  const [editing, setEditing] = useState(!exercise);
  const [f, setF] = useState<ExForm>(
    exercise
      ? {
          name: exercise.name,
          durationSeconds: String(exercise.durationSeconds),
          imageUrl: exercise.imageUrl ?? "",
          videoUrl: exercise.videoUrl ?? "",
        }
      : emptyEx(),
  );
  const [confirmDelete, setConfirmDelete] = useState(false);
  const set = <K extends keyof ExForm>(k: K, v: ExForm[K]) => setF((p) => ({ ...p, [k]: v }));

  const save = useMutation({
    mutationFn: () => {
      const payload = {
        name: f.name.trim(),
        durationSeconds: parseInt(f.durationSeconds) || 0,
        imageUrl: f.imageUrl.trim() || undefined,
        videoUrl: f.videoUrl.trim() || undefined,
        order,
      };
      return exercise
        ? workoutLibraryService.updateExercise(exercise.id, payload)
        : workoutLibraryService.createExercise(itemId, payload);
    },
    onSuccess: () => { setEditing(false); onSaved(); toast.success("Exercise saved"); },
    onError: () => toast.error("Failed to save exercise"),
  });

  const del = useMutation({
    mutationFn: () => workoutLibraryService.deleteExercise(exercise!.id),
    onSuccess: () => { onDeleted(); toast.success("Exercise removed"); },
    onError: () => toast.error("Failed to remove exercise"),
  });

  if (!editing && exercise) {
    return (
      <div className="flex items-center justify-between gap-3 rounded-lg border border-slate-200 bg-white p-3 dark:border-slate-700 dark:bg-slate-900">
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold text-slate-700 dark:text-slate-200">{exercise.name}</p>
          <p className="text-xs text-slate-400">{exercise.durationSeconds} sec</p>
        </div>
        <div className="flex shrink-0 gap-2">
          <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
          <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
        </div>
        <ConfirmModal
          open={confirmDelete}
          title="Remove exercise?"
          onClose={() => setConfirmDelete(false)}
          onConfirm={() => { del.mutate(); setConfirmDelete(false); }}
          confirmLabel="Remove"
        >
          &quot;{exercise.name}&quot; will be permanently removed.
        </ConfirmModal>
      </div>
    );
  }

  return (
    <div className="space-y-2 rounded-lg border border-slate-200 bg-white p-3 dark:border-slate-700 dark:bg-slate-900">
      <div className="grid gap-2 sm:grid-cols-2">
        <div className="space-y-1">
          <label className="text-xs text-slate-400">Name</label>
          <Input value={f.name} onChange={(e) => set("name", e.target.value)} placeholder="Bicycle Crunches" />
        </div>
        <div className="space-y-1">
          <label className="text-xs text-slate-400">Duration (sec)</label>
          <Input type="number" value={f.durationSeconds} onChange={(e) => set("durationSeconds", e.target.value)} />
        </div>
      </div>
      <ImageUploadField label="Thumbnail (optional)" value={f.imageUrl} onChange={(url) => set("imageUrl", url)} folder="exercises" />
      <VideoUploadField label="Video (optional)" value={f.videoUrl} onChange={(url) => set("videoUrl", url)} />
      <div className="flex justify-end gap-2">
        {exercise && (
          <Button variant="ghost" onClick={() => setEditing(false)}>Cancel</Button>
        )}
        <Button onClick={() => save.mutate()} disabled={save.isPending || !f.name.trim()}>
          {save.isPending ? "Saving…" : "Save Exercise"}
        </Button>
      </div>
    </div>
  );
}

function ExerciseManager({ item }: { item: WorkoutLibraryItem }) {
  const qc = useQueryClient();
  const [adding, setAdding] = useState(false);

  const { data: exercises = [], isLoading } = useQuery({
    queryKey: ["workout-library-exercises", item.id],
    queryFn: () => workoutLibraryService.listExercises(item.id),
  });

  const refresh = () => {
    void qc.invalidateQueries({ queryKey: ["workout-library-exercises", item.id] });
    void qc.invalidateQueries({ queryKey: ["workout-library"] });
    setAdding(false);
  };

  return (
    <div className="mt-3 space-y-2 border-t border-slate-100 pt-3 dark:border-slate-800">
      {isLoading ? (
        <p className="text-xs text-slate-400">Loading exercises…</p>
      ) : (
        <>
          {exercises.length === 0 && !adding && (
            <p className="text-xs text-slate-400">
              No exercises yet — add at least one below.
            </p>
          )}
          {exercises.map((ex) => (
            <ExerciseRow key={ex.id} itemId={item.id} exercise={ex} order={ex.order} onSaved={refresh} onDeleted={refresh} />
          ))}
        </>
      )}

      {adding ? (
        <ExerciseRow itemId={item.id} order={exercises.length} onSaved={refresh} onDeleted={refresh} />
      ) : (
        <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setAdding(true)}>
          + Add Exercise
        </Button>
      )}
    </div>
  );
}

// ─── Item card ────────────────────────────────────────────────────────────────

function ItemCard({ item, onDeleted }: { item: WorkoutLibraryItem; onDeleted: () => void }) {
  const [editing, setEditing] = useState(false);
  const [managingExercises, setManagingExercises] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const qc = useQueryClient();

  const update = useMutation({
    mutationFn: (f: ItemForm) => workoutLibraryService.update(item.id, formToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workout-library"] });
      setEditing(false);
      toast.success("Workout updated");
    },
    onError: () => toast.error("Failed to update"),
  });

  const del = useMutation({
    mutationFn: () => workoutLibraryService.delete(item.id),
    onSuccess: () => { onDeleted(); toast.success("Workout deleted"); },
    onError: () => toast.error("Failed to delete"),
  });

  if (editing) {
    return (
      <ItemFormPanel
        initial={itemToForm(item)}
        onSave={(f) => update.mutate(f)}
        onCancel={() => setEditing(false)}
        loading={update.isPending}
      />
    );
  }

  const exerciseCount = item._count?.exercises ?? 0;

  return (
    <>
      <Card className="p-4">
        <div className="flex items-start justify-between gap-4">
          {item.heroImageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={item.heroImageUrl} alt="" className="h-14 w-14 shrink-0 rounded-lg object-cover" />
          )}
          <div className="min-w-0 flex-1 space-y-2">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full bg-pink-100 px-3 py-0.5 text-xs font-semibold text-pink-700 dark:bg-pink-900/30 dark:text-pink-300">
                {item.category}
              </span>
              <span className="text-sm font-semibold text-slate-700 dark:text-slate-200">
                {item.titleLine1} {item.titleScript}
              </span>
              <span className="text-xs text-slate-400">
                {item.durationMinutes} min · {item.kcalLabel} kcal · {exerciseCount} exercise{exerciseCount === 1 ? "" : "s"}
              </span>
            </div>
            <p className="line-clamp-1 text-xs text-slate-500 dark:text-slate-400">{item.description}</p>
          </div>
          <div className="flex shrink-0 gap-2">
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setManagingExercises((v) => !v)}>
              {managingExercises ? "Hide Exercises" : "Manage Exercises"}
            </Button>
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
            <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
          </div>
        </div>

        {managingExercises && <ExerciseManager item={item} />}
      </Card>

      <ConfirmModal
        open={confirmDelete}
        title="Delete Workout?"
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => { del.mutate(); setConfirmDelete(false); }}
        confirmLabel="Delete"
      >
        &quot;{item.titleLine1} {item.titleScript}&quot; and all its exercises will be permanently deleted.
      </ConfirmModal>
    </>
  );
}

// ─── Page ──────────────────────────────────────────────────────────────────────

export default function WorkoutLibraryPage() {
  const [creating, setCreating] = useState(false);
  const qc = useQueryClient();

  const { data: items = [], isLoading } = useQuery({
    queryKey: ["workout-library"],
    queryFn: () => workoutLibraryService.list(),
  });

  const create = useMutation({
    mutationFn: (f: ItemForm) => workoutLibraryService.create(formToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workout-library"] });
      setCreating(false);
      toast.success("Workout created");
    },
    onError: () => toast.error("Failed to create workout"),
  });

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <PageHeader
          title="Workout Library"
          description="Standalone browsable workouts (e.g. Belly Fat Blast) shown in the app's Workout Library screen."
        />
        {!creating && <Button onClick={() => setCreating(true)}>+ New Workout</Button>}
      </div>

      {creating && (
        <ItemFormPanel
          initial={empty()}
          onSave={(f) => create.mutate(f)}
          onCancel={() => setCreating(false)}
          loading={create.isPending}
        />
      )}

      {isLoading ? (
        <Card><p className="text-sm text-slate-400">Loading workouts…</p></Card>
      ) : items.length === 0 ? (
        <Card><p className="text-sm text-slate-400">No library workouts yet. Create one above.</p></Card>
      ) : (
        <div className="space-y-3">
          {items.map((item) => (
            <ItemCard
              key={item.id}
              item={item}
              onDeleted={() => void qc.invalidateQueries({ queryKey: ["workout-library"] })}
            />
          ))}
        </div>
      )}
    </div>
  );
}
