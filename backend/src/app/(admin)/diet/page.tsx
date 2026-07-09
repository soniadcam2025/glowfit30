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
import { dietService } from "@/services/diet.service";
import type { DietDayMeals, DietMealItem, DietPlan, DietPlanDay } from "@/types";

const DIET_STYLES = ["Vegetarian", "Non-Vegetarian", "Vegan", "Balanced"];
const GOALS = ["Loss weight", "Lift & tone", "Lose belly fat", "Build muscles"];

const MEAL_TYPES: { type: string; label: string; time: string }[] = [
  { type: "breakfast",   label: "Breakfast",     time: "7:30 AM" },
  { type: "mid_morning", label: "Mid Morning",   time: "10:30 AM" },
  { type: "lunch",       label: "Lunch",         time: "1:30 PM" },
  { type: "snack",       label: "Evening Snack", time: "4:30 PM" },
  { type: "dinner",      label: "Dinner",        time: "7:30 PM" },
];

const selectCls =
  "w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950";

// ─── Plan form ────────────────────────────────────────────────────────────────

type DietForm = {
  type: string;
  goal: string;
  calories: string;
  imageUrl: string;
};

const empty = (): DietForm => ({
  type: DIET_STYLES[0],
  goal: "",
  calories: "1400",
  imageUrl: "",
});

function planToForm(p: DietPlan): DietForm {
  return {
    type: p.type,
    goal: p.goal ?? "",
    calories: String(p.calories),
    imageUrl: p.imageUrl ?? "",
  };
}

function formToPayload(f: DietForm) {
  return {
    type: f.type,
    goal: f.goal || undefined,
    calories: parseInt(f.calories) || 0,
    meals: {},
    imageUrl: f.imageUrl.trim() || undefined,
  };
}

function DietFormPanel({ initial, onSave, onCancel, loading }: {
  initial: DietForm;
  onSave: (f: DietForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = (k: keyof DietForm, v: string) => setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-4 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="grid gap-3 sm:grid-cols-3">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Diet style *</label>
          <select value={f.type} onChange={(e) => set("type", e.target.value)} className={selectCls}>
            {DIET_STYLES.map((s) => <option key={s}>{s}</option>)}
          </select>
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Goal (optional)</label>
          <select value={f.goal} onChange={(e) => set("goal", e.target.value)} className={selectCls}>
            <option value="">Any goal</option>
            {GOALS.map((g) => <option key={g}>{g}</option>)}
          </select>
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Daily calories</label>
          <Input type="number" value={f.calories} onChange={(e) => set("calories", e.target.value)} placeholder="1400" />
        </div>
      </div>

      <ImageUploadField
        label="Plan image"
        value={f.imageUrl}
        onChange={(url) => set("imageUrl", url)}
        folder="diet"
      />

      <p className="text-xs text-slate-400">
        Meals are configured per day — save the plan, then use &quot;Manage Days&quot; on its card.
      </p>

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading}>
          {loading ? "Saving…" : "Save Plan"}
        </Button>
      </div>
    </div>
  );
}

// ─── Day editor ───────────────────────────────────────────────────────────────

type MealItemForm = {
  type: string;
  label: string;
  time: string;
  desc: string;
  kcal: string;
  image: string;
};

const emptyItem = (preset = MEAL_TYPES[0]): MealItemForm => ({
  type: preset.type,
  label: preset.label,
  time: preset.time,
  desc: "",
  kcal: "",
  image: "",
});

function mealsToItems(meals: DietDayMeals): MealItemForm[] {
  return (meals.items ?? []).map((m) => ({
    type: m.type ?? "breakfast",
    label: m.label ?? "",
    time: m.time ?? "",
    desc: m.desc ?? "",
    kcal: m.kcal != null ? String(m.kcal) : "",
    image: m.image ?? "",
  }));
}

function DayEditor({ planId, dayNumber, initial, onClose, onSaved, onDeleted }: {
  planId: string;
  dayNumber: number;
  initial: DietDayMeals;
  onClose: () => void;
  onSaved: () => void;
  onDeleted: () => void;
}) {
  const configured = (initial.items ?? []).length > 0;
  const [items, setItems] = useState<MealItemForm[]>(() => {
    const list = mealsToItems(initial);
    return list.length > 0 ? list : MEAL_TYPES.map((t) => emptyItem(t));
  });
  const [tags, setTags] = useState((initial.tags ?? []).join(", "));
  const [water, setWater] = useState(initial.waterTarget != null ? String(initial.waterTarget) : "3");
  const [confirmDelete, setConfirmDelete] = useState(false);

  const setItem = (i: number, patch: Partial<MealItemForm>) =>
    setItems((prev) => prev.map((it, idx) => (idx === i ? { ...it, ...patch } : it)));

  const setItemType = (i: number, type: string) => {
    const preset = MEAL_TYPES.find((t) => t.type === type);
    setItems((prev) =>
      prev.map((it, idx) => {
        if (idx !== i) return it;
        const labelIsPreset = MEAL_TYPES.some((t) => t.label === it.label) || it.label === "";
        const timeIsPreset = MEAL_TYPES.some((t) => t.time === it.time) || it.time === "";
        return {
          ...it,
          type,
          label: labelIsPreset && preset ? preset.label : it.label,
          time: timeIsPreset && preset ? preset.time : it.time,
        };
      }),
    );
  };

  const save = useMutation({
    mutationFn: () => {
      const payload: DietDayMeals = {
        items: items
          .filter((it) => it.label.trim() || it.desc.trim())
          .map<DietMealItem>((it) => ({
            type: it.type,
            label: it.label.trim(),
            time: it.time.trim() || undefined,
            desc: it.desc.trim() || undefined,
            kcal: parseInt(it.kcal) || 0,
            image: it.image.trim() || undefined,
          })),
        tags: tags.split(",").map((t) => t.trim()).filter(Boolean),
        waterTarget: parseFloat(water) || undefined,
      };
      return dietService.upsertDay(planId, dayNumber, payload);
    },
    onSuccess: () => { onSaved(); toast.success(`Day ${dayNumber} saved`); },
    onError: () => toast.error("Failed to save day"),
  });

  const del = useMutation({
    mutationFn: () => dietService.deleteDay(planId, dayNumber),
    onSuccess: () => { onDeleted(); toast.success(`Day ${dayNumber} removed`); },
    onError: () => toast.error("Failed to remove day"),
  });

  return (
    <div className="space-y-4 rounded-xl border border-pink-200 bg-pink-50/40 p-4 dark:border-pink-900/40 dark:bg-pink-950/10">
      <div className="flex items-center justify-between">
        <p className="text-sm font-bold text-slate-700 dark:text-slate-200">Day {dayNumber} meals</p>
        {configured && (
          <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>
            Remove Day
          </Button>
        )}
      </div>

      <div className="space-y-3">
        {items.map((it, i) => (
          <div key={i} className="space-y-2 rounded-lg border border-slate-200 bg-white p-3 dark:border-slate-700 dark:bg-slate-900">
            <div className="grid gap-2 sm:grid-cols-4">
              <div className="space-y-1">
                <label className="text-xs text-slate-400">Meal</label>
                <select value={it.type} onChange={(e) => setItemType(i, e.target.value)} className={selectCls}>
                  {MEAL_TYPES.map((t) => <option key={t.type} value={t.type}>{t.label}</option>)}
                </select>
              </div>
              <div className="space-y-1">
                <label className="text-xs text-slate-400">Label</label>
                <Input value={it.label} onChange={(e) => setItem(i, { label: e.target.value })} placeholder="Breakfast" />
              </div>
              <div className="space-y-1">
                <label className="text-xs text-slate-400">Time</label>
                <Input value={it.time} onChange={(e) => setItem(i, { time: e.target.value })} placeholder="7:30 AM" />
              </div>
              <div className="space-y-1">
                <label className="text-xs text-slate-400">Kcal</label>
                <Input type="number" value={it.kcal} onChange={(e) => setItem(i, { kcal: e.target.value })} placeholder="320" />
              </div>
            </div>
            <div className="flex items-end gap-2">
              <div className="flex-1 space-y-1">
                <label className="text-xs text-slate-400">Description</label>
                <Input
                  value={it.desc}
                  onChange={(e) => setItem(i, { desc: e.target.value })}
                  placeholder="e.g. Oats with chia seeds, banana, berries & almonds"
                />
              </div>
              <Button
                variant="ghost"
                className="text-xs px-3 py-2 text-red-500"
                onClick={() => setItems((prev) => prev.filter((_, idx) => idx !== i))}
              >
                Remove
              </Button>
            </div>
          </div>
        ))}
      </div>

      <Button
        variant="secondary"
        className="text-xs px-3 py-1.5"
        onClick={() => setItems((prev) => [...prev, emptyItem()])}
      >
        + Add Meal
      </Button>

      <div className="grid gap-3 sm:grid-cols-2">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Focus tags (comma separated)</label>
          <Input value={tags} onChange={(e) => setTags(e.target.value)} placeholder="1350 kcal Target, High Protein Focus" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Water target (litres)</label>
          <Input type="number" step="0.5" value={water} onChange={(e) => setWater(e.target.value)} placeholder="3" />
        </div>
      </div>

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onClose}>Close</Button>
        <Button onClick={() => save.mutate()} disabled={save.isPending}>
          {save.isPending ? "Saving…" : `Save Day ${dayNumber}`}
        </Button>
      </div>

      <ConfirmModal
        open={confirmDelete}
        title={`Remove Day ${dayNumber}?`}
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => { del.mutate(); setConfirmDelete(false); }}
        confirmLabel="Remove"
      >
        Day {dayNumber}&apos;s meals will be removed. Users will fall back to the day rotation.
      </ConfirmModal>
    </div>
  );
}

// ─── Day manager (per plan) ───────────────────────────────────────────────────

function DayManager({ plan }: { plan: DietPlan }) {
  const qc = useQueryClient();
  const [selectedDay, setSelectedDay] = useState<number | null>(null);
  const [newDay, setNewDay] = useState("");

  const { data: days = [], isLoading } = useQuery({
    queryKey: ["diet-days", plan.id],
    queryFn: () => dietService.listDays(plan.id),
  });

  const refresh = () => {
    void qc.invalidateQueries({ queryKey: ["diet-days", plan.id] });
    void qc.invalidateQueries({ queryKey: ["diet"] });
  };

  const configuredNumbers = days.map((d) => d.dayNumber);
  const nextFree = (() => {
    let n = 1;
    while (configuredNumbers.includes(n)) n++;
    return n;
  })();

  const openDay = (n: number) => setSelectedDay(n);
  const selected: DietPlanDay | undefined = days.find((d) => d.dayNumber === selectedDay);

  return (
    <div className="mt-3 space-y-3 border-t border-slate-100 pt-3 dark:border-slate-800">
      {isLoading ? (
        <p className="text-xs text-slate-400">Loading days…</p>
      ) : (
        <div className="flex flex-wrap items-center gap-2">
          {days.map((d) => (
            <button
              key={d.id}
              onClick={() => openDay(d.dayNumber)}
              className={`rounded-full px-3 py-1 text-xs font-semibold transition ${
                selectedDay === d.dayNumber
                  ? "bg-pink-600 text-white"
                  : "bg-pink-100 text-pink-700 hover:bg-pink-200 dark:bg-pink-900/30 dark:text-pink-300"
              }`}
            >
              Day {d.dayNumber}
            </button>
          ))}
          <div className="flex items-center gap-1">
            <Input
              type="number"
              min={1}
              value={newDay}
              onChange={(e) => setNewDay(e.target.value)}
              placeholder={`${nextFree}`}
              className="w-20"
            />
            <Button
              variant="secondary"
              className="text-xs px-3 py-1.5"
              onClick={() => {
                const n = parseInt(newDay) || nextFree;
                if (n < 1) return;
                setSelectedDay(n);
                setNewDay("");
              }}
            >
              + Add Day
            </Button>
          </div>
        </div>
      )}

      {days.length === 0 && !isLoading && selectedDay === null && (
        <p className="text-xs text-slate-400">
          No days configured yet — the app will fall back to default meals. Add Day 1 to start.
        </p>
      )}

      {selectedDay !== null && (
        <DayEditor
          key={`${plan.id}-${selectedDay}-${selected?.id ?? "new"}`}
          planId={plan.id}
          dayNumber={selectedDay}
          initial={selected?.meals ?? {}}
          onClose={() => setSelectedDay(null)}
          onSaved={refresh}
          onDeleted={() => { setSelectedDay(null); refresh(); }}
        />
      )}
    </div>
  );
}

// ─── Diet Plan Card ────────────────────────────────────────────────────────────

function DietPlanCard({ plan, onDeleted }: { plan: DietPlan; onDeleted: () => void }) {
  const [editing, setEditing] = useState(false);
  const [managingDays, setManagingDays] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const qc = useQueryClient();

  const update = useMutation({
    mutationFn: (f: DietForm) => dietService.update(plan.id, formToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["diet"] });
      setEditing(false);
      toast.success("Plan updated");
    },
    onError: () => toast.error("Failed to update"),
  });

  const del = useMutation({
    mutationFn: () => dietService.delete(plan.id),
    onSuccess: () => { onDeleted(); toast.success("Plan deleted"); },
    onError: () => toast.error("Failed to delete"),
  });

  if (editing) {
    return (
      <DietFormPanel
        initial={planToForm(plan)}
        onSave={(f) => update.mutate(f)}
        onCancel={() => setEditing(false)}
        loading={update.isPending}
      />
    );
  }

  const daysCount = plan._count?.days ?? 0;

  return (
    <>
      <Card className="p-4">
        <div className="flex items-start justify-between gap-4">
          {plan.imageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={plan.imageUrl}
              alt=""
              className="h-14 w-14 shrink-0 rounded-lg object-cover"
            />
          )}
          <div className="space-y-2 flex-1 min-w-0">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full bg-pink-100 px-3 py-0.5 text-xs font-semibold text-pink-700 dark:bg-pink-900/30 dark:text-pink-300">
                {plan.type}
              </span>
              {plan.goal && (
                <span className="rounded-full bg-indigo-100 px-3 py-0.5 text-xs font-semibold text-indigo-700 dark:bg-indigo-900/30 dark:text-indigo-300">
                  {plan.goal}
                </span>
              )}
              <span className="text-sm font-semibold text-slate-700 dark:text-slate-200">{plan.calories} kcal / day</span>
              <span className="text-xs text-slate-400">
                {daysCount > 0 ? `${daysCount} day${daysCount > 1 ? "s" : ""} configured` : "no days configured"}
              </span>
            </div>
          </div>
          <div className="flex gap-2 shrink-0">
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setManagingDays((v) => !v)}>
              {managingDays ? "Hide Days" : "Manage Days"}
            </Button>
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
            <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
          </div>
        </div>

        {managingDays && <DayManager plan={plan} />}
      </Card>

      <ConfirmModal
        open={confirmDelete}
        title="Delete Diet Plan?"
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => { del.mutate(); setConfirmDelete(false); }}
        confirmLabel="Delete"
      >
        The &quot;{plan.type}&quot; diet plan and all its configured days will be permanently deleted.
      </ConfirmModal>
    </>
  );
}

// ─── Page ──────────────────────────────────────────────────────────────────────

export default function DietPage() {
  const [creating, setCreating] = useState(false);
  const qc = useQueryClient();

  const { data: plans = [], isLoading } = useQuery({
    queryKey: ["diet"],
    queryFn: () => dietService.list(),
  });

  const create = useMutation({
    mutationFn: (f: DietForm) => dietService.create(formToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["diet"] });
      setCreating(false);
      toast.success("Diet plan created");
    },
    onError: () => toast.error("Failed to create plan"),
  });

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <PageHeader title="Diet Management" description="One plan per diet style, with day-by-day meals." />
        {!creating && (
          <Button onClick={() => setCreating(true)}>+ New Plan</Button>
        )}
      </div>

      {creating && (
        <DietFormPanel
          initial={empty()}
          onSave={(f) => create.mutate(f)}
          onCancel={() => setCreating(false)}
          loading={create.isPending}
        />
      )}

      {isLoading ? (
        <Card><p className="text-sm text-slate-400">Loading diet plans…</p></Card>
      ) : plans.length === 0 ? (
        <Card><p className="text-sm text-slate-400">No diet plans yet. Create one above.</p></Card>
      ) : (
        <div className="space-y-3">
          {plans.map((p) => (
            <DietPlanCard
              key={p.id}
              plan={p}
              onDeleted={() => void qc.invalidateQueries({ queryKey: ["diet"] })}
            />
          ))}
        </div>
      )}
    </div>
  );
}
