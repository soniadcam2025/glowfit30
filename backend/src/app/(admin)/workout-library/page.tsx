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
import type {
  WorkoutLibraryCategory,
  WorkoutLibraryDifficulty,
  WorkoutLibraryExercise,
  WorkoutLibraryItem,
  WorkoutLibraryTag,
} from "@/types";

const DIFFICULTIES: WorkoutLibraryDifficulty[] = ["Beginner", "Intermediate", "Advanced"];

const selectCls =
  "h-9 w-full rounded-lg border border-slate-300 bg-white px-3 text-sm text-slate-700 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200";

// ─── Tag editor (shared by item + category forms) ────────────────────────────

function TagEditor({ tags, onChange }: {
  tags: WorkoutLibraryTag[];
  onChange: (tags: WorkoutLibraryTag[]) => void;
}) {
  const setTag = (i: number, patch: Partial<WorkoutLibraryTag>) =>
    onChange(tags.map((t, idx) => (idx === i ? { ...t, ...patch } : t)));

  return (
    <div className="space-y-2">
      <p className="text-xs font-semibold text-slate-500">Tags (e.g. Fat Burn, Core Focus, No Equipment)</p>
      {tags.map((t, i) => (
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
            onClick={() => onChange(tags.filter((_, idx) => idx !== i))}
          >
            Remove
          </Button>
        </div>
      ))}
      <Button
        variant="secondary"
        className="text-xs px-3 py-1.5"
        onClick={() => onChange([...tags, emptyTag()])}
      >
        + Add Tag
      </Button>
    </div>
  );
}

// ─── Item form ────────────────────────────────────────────────────────────────

type ItemForm = {
  category: string;
  difficulty: WorkoutLibraryDifficulty;
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
  difficulty: "Beginner",
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
    difficulty: i.difficulty ?? "Beginner",
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
    difficulty: f.difficulty,
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

function ItemFormPanel({ initial, categoryNames, onSave, onCancel, loading }: {
  initial: ItemForm;
  categoryNames: string[];
  onSave: (f: ItemForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof ItemForm>(k: K, v: ItemForm[K]) =>
    setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-4 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="grid gap-3 sm:grid-cols-4">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Category *</label>
          <Input
            value={f.category}
            onChange={(e) => set("category", e.target.value)}
            placeholder="Abs"
            list="wl-category-names"
          />
          <datalist id="wl-category-names">
            {categoryNames.map((n) => <option key={n} value={n} />)}
          </datalist>
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Difficulty *</label>
          <select
            className={selectCls}
            value={f.difficulty}
            onChange={(e) => set("difficulty", e.target.value as WorkoutLibraryDifficulty)}
          >
            {DIFFICULTIES.map((d) => <option key={d} value={d}>{d}</option>)}
          </select>
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

      <TagEditor tags={f.tags} onChange={(tags) => setF((p) => ({ ...p, tags }))} />

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading}>
          {loading ? "Saving…" : "Save Workout"}
        </Button>
      </div>
    </div>
  );
}

// ─── Category form + card ─────────────────────────────────────────────────────

type CategoryForm = {
  name: string;
  headingLine1: string;
  headingLine2: string;
  description: string;
  heroImageUrl: string;
  tags: WorkoutLibraryTag[];
  order: string;
};

const emptyCategory = (): CategoryForm => ({
  name: "",
  headingLine1: "",
  headingLine2: "WORKOUTS",
  description: "",
  heroImageUrl: "",
  tags: [emptyTag()],
  order: "0",
});

function categoryToForm(c: WorkoutLibraryCategory): CategoryForm {
  return {
    name: c.name,
    headingLine1: c.headingLine1,
    headingLine2: c.headingLine2,
    description: c.description,
    heroImageUrl: c.heroImageUrl ?? "",
    tags: c.tags.length > 0 ? c.tags : [emptyTag()],
    order: String(c.order),
  };
}

function categoryFormToPayload(f: CategoryForm) {
  return {
    name: f.name.trim(),
    headingLine1: f.headingLine1.trim(),
    headingLine2: f.headingLine2.trim(),
    description: f.description.trim(),
    heroImageUrl: f.heroImageUrl.trim() || undefined,
    tags: f.tags.filter((t) => t.label.trim()),
    order: parseInt(f.order) || 0,
  };
}

function CategoryFormPanel({ initial, onSave, onCancel, loading }: {
  initial: CategoryForm;
  onSave: (f: CategoryForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof CategoryForm>(k: K, v: CategoryForm[K]) =>
    setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-4 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="grid gap-3 sm:grid-cols-4">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Name (must match app card) *</label>
          <Input value={f.name} onChange={(e) => set("name", e.target.value)} placeholder="Abs" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Heading line 1 (pink) *</label>
          <Input value={f.headingLine1} onChange={(e) => set("headingLine1", e.target.value)} placeholder="ABS" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Heading line 2 (dark) *</label>
          <Input value={f.headingLine2} onChange={(e) => set("headingLine2", e.target.value)} placeholder="WORKOUTS" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Sort order</label>
          <Input type="number" value={f.order} onChange={(e) => set("order", e.target.value)} />
        </div>
      </div>

      <div className="space-y-1">
        <label className="text-xs font-semibold text-slate-500">Description *</label>
        <Input
          value={f.description}
          onChange={(e) => set("description", e.target.value)}
          placeholder="Stronger core. Flatter stomach. Confident you."
        />
      </div>

      <ImageUploadField
        label="Header image (optional — app falls back to its built-in category art)"
        value={f.heroImageUrl}
        onChange={(url) => set("heroImageUrl", url)}
        folder="exercises"
      />

      <TagEditor tags={f.tags} onChange={(tags) => setF((p) => ({ ...p, tags }))} />

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading || !f.name.trim()}>
          {loading ? "Saving…" : "Save Category"}
        </Button>
      </div>
    </div>
  );
}

function CategoryCard({ category, workoutCount, onDeleted }: {
  category: WorkoutLibraryCategory;
  workoutCount: number;
  onDeleted: () => void;
}) {
  const [editing, setEditing] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const qc = useQueryClient();

  const update = useMutation({
    mutationFn: (f: CategoryForm) =>
      workoutLibraryService.updateCategory(category.id, categoryFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workout-library-categories"] });
      setEditing(false);
      toast.success("Category updated");
    },
    onError: () => toast.error("Failed to update category"),
  });

  const del = useMutation({
    mutationFn: () => workoutLibraryService.deleteCategory(category.id),
    onSuccess: () => { onDeleted(); toast.success("Category deleted"); },
    onError: () => toast.error("Failed to delete category"),
  });

  if (editing) {
    return (
      <CategoryFormPanel
        initial={categoryToForm(category)}
        onSave={(f) => update.mutate(f)}
        onCancel={() => setEditing(false)}
        loading={update.isPending}
      />
    );
  }

  return (
    <>
      <Card className="p-4">
        <div className="flex items-center justify-between gap-4">
          {category.heroImageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={category.heroImageUrl} alt="" className="h-12 w-12 shrink-0 rounded-lg object-cover" />
          )}
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full bg-violet-100 px-3 py-0.5 text-xs font-semibold text-violet-700 dark:bg-violet-900/30 dark:text-violet-300">
                {category.name}
              </span>
              <span className="text-sm font-semibold text-slate-700 dark:text-slate-200">
                {category.headingLine1} {category.headingLine2}
              </span>
              <span className="text-xs text-slate-400">
                {workoutCount} workout{workoutCount === 1 ? "" : "s"}
              </span>
            </div>
            <p className="line-clamp-1 text-xs text-slate-500 dark:text-slate-400">{category.description}</p>
          </div>
          <div className="flex shrink-0 gap-2">
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
            <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
          </div>
        </div>
      </Card>

      <ConfirmModal
        open={confirmDelete}
        title="Delete Category?"
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => { del.mutate(); setConfirmDelete(false); }}
        confirmLabel="Delete"
      >
        &quot;{category.name}&quot; will be deleted. Workouts tagged with it are kept but the app
        will show a generic header for this category.
      </ConfirmModal>
    </>
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

const difficultyBadgeCls: Record<WorkoutLibraryDifficulty, string> = {
  Beginner: "bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300",
  Intermediate: "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300",
  Advanced: "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300",
};

function ItemCard({ item, categoryNames, onDeleted }: {
  item: WorkoutLibraryItem;
  categoryNames: string[];
  onDeleted: () => void;
}) {
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
        categoryNames={categoryNames}
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
              <span className={`rounded-full px-3 py-0.5 text-xs font-semibold ${difficultyBadgeCls[item.difficulty] ?? difficultyBadgeCls.Beginner}`}>
                {item.difficulty}
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
  const [creatingCategory, setCreatingCategory] = useState(false);
  const qc = useQueryClient();

  const { data: items = [], isLoading } = useQuery({
    queryKey: ["workout-library"],
    queryFn: () => workoutLibraryService.list(),
  });

  const { data: categories = [], isLoading: categoriesLoading } = useQuery({
    queryKey: ["workout-library-categories"],
    queryFn: () => workoutLibraryService.listCategories(),
  });

  const categoryNames = categories.map((c) => c.name);

  const create = useMutation({
    mutationFn: (f: ItemForm) => workoutLibraryService.create(formToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workout-library"] });
      setCreating(false);
      toast.success("Workout created");
    },
    onError: () => toast.error("Failed to create workout"),
  });

  const createCategory = useMutation({
    mutationFn: (f: CategoryForm) => workoutLibraryService.createCategory(categoryFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["workout-library-categories"] });
      setCreatingCategory(false);
      toast.success("Category created");
    },
    onError: () => toast.error("Failed to create category"),
  });

  const workoutCountFor = (name: string) =>
    items.filter((i) => i.category === name).length;

  return (
    <div className="space-y-5">
      <PageHeader
        title="Workout Library"
        description="Standalone browsable workouts (e.g. Belly Fat Blast) shown in the app's Workout Library screen."
      />

      {/* ── Categories ── */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-bold text-slate-700 dark:text-slate-200">Categories</h2>
          <p className="text-xs text-slate-400">
            Header content for each category browse screen (Abs, Full Body, …). The name must
            match the category tag used on workouts below.
          </p>
        </div>
        {!creatingCategory && (
          <Button variant="secondary" onClick={() => setCreatingCategory(true)}>+ New Category</Button>
        )}
      </div>

      {creatingCategory && (
        <CategoryFormPanel
          initial={emptyCategory()}
          onSave={(f) => createCategory.mutate(f)}
          onCancel={() => setCreatingCategory(false)}
          loading={createCategory.isPending}
        />
      )}

      {categoriesLoading ? (
        <Card><p className="text-sm text-slate-400">Loading categories…</p></Card>
      ) : categories.length === 0 ? (
        <Card><p className="text-sm text-slate-400">No categories yet. Create one above so the app can show a proper category header.</p></Card>
      ) : (
        <div className="space-y-3">
          {categories.map((c) => (
            <CategoryCard
              key={c.id}
              category={c}
              workoutCount={workoutCountFor(c.name)}
              onDeleted={() => void qc.invalidateQueries({ queryKey: ["workout-library-categories"] })}
            />
          ))}
        </div>
      )}

      {/* ── Workouts ── */}
      <div className="flex items-center justify-between pt-2">
        <div>
          <h2 className="text-base font-bold text-slate-700 dark:text-slate-200">Workouts</h2>
          <p className="text-xs text-slate-400">
            Individual workouts. The first one (lowest sort order) is featured on the library hero card.
          </p>
        </div>
        {!creating && <Button onClick={() => setCreating(true)}>+ New Workout</Button>}
      </div>

      {creating && (
        <ItemFormPanel
          initial={empty()}
          categoryNames={categoryNames}
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
              categoryNames={categoryNames}
              onDeleted={() => void qc.invalidateQueries({ queryKey: ["workout-library"] })}
            />
          ))}
        </div>
      )}
    </div>
  );
}
