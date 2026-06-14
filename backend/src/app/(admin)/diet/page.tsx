"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { PageHeader } from "@/components/common/page-header";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ConfirmModal } from "@/components/ui/modal";
import { dietService } from "@/services/diet.service";
import type { DietPlan } from "@/types";

const GOALS = ["Loss weight", "Lift & tone", "Lose belly fat", "Build muscles"];

type DietForm = {
  type: string;
  calories: string;
  breakfast: string;
  lunch: string;
  dinner: string;
  snacks: string;
};

const empty = (): DietForm => ({
  type: GOALS[0],
  calories: "1400",
  breakfast: "",
  lunch: "",
  dinner: "",
  snacks: "",
});

function planToForm(p: DietPlan): DietForm {
  return {
    type: p.type,
    calories: String(p.calories),
    breakfast: p.meals.breakfast ?? "",
    lunch: p.meals.lunch ?? "",
    dinner: p.meals.dinner ?? "",
    snacks: p.meals.snacks ?? "",
  };
}

function formToPayload(f: DietForm) {
  return {
    type: f.type,
    calories: parseInt(f.calories) || 0,
    meals: {
      breakfast: f.breakfast.trim() || undefined,
      lunch: f.lunch.trim() || undefined,
      dinner: f.dinner.trim() || undefined,
      snacks: f.snacks.trim() || undefined,
    },
  };
}

// ─── Form Panel ───────────────────────────────────────────────────────────────

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
      <div className="grid gap-3 sm:grid-cols-2">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Goal type *</label>
          <select
            value={f.type}
            onChange={(e) => set("type", e.target.value)}
            className="w-full rounded-xl border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-950"
          >
            {GOALS.map((g) => <option key={g}>{g}</option>)}
          </select>
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Daily calories</label>
          <Input type="number" value={f.calories} onChange={(e) => set("calories", e.target.value)} placeholder="1400" />
        </div>
      </div>

      <div className="space-y-2">
        <p className="text-xs font-semibold text-slate-500">Meals</p>
        <div className="grid gap-2 sm:grid-cols-2">
          <div className="space-y-1">
            <label className="text-xs text-slate-400">Breakfast</label>
            <Input value={f.breakfast} onChange={(e) => set("breakfast", e.target.value)} placeholder="e.g. Oats with berries" />
          </div>
          <div className="space-y-1">
            <label className="text-xs text-slate-400">Lunch</label>
            <Input value={f.lunch} onChange={(e) => set("lunch", e.target.value)} placeholder="e.g. Grilled chicken salad" />
          </div>
          <div className="space-y-1">
            <label className="text-xs text-slate-400">Dinner</label>
            <Input value={f.dinner} onChange={(e) => set("dinner", e.target.value)} placeholder="e.g. Salmon with veggies" />
          </div>
          <div className="space-y-1">
            <label className="text-xs text-slate-400">Snacks</label>
            <Input value={f.snacks} onChange={(e) => set("snacks", e.target.value)} placeholder="e.g. Greek yogurt" />
          </div>
        </div>
      </div>

      <div className="flex justify-end gap-2">
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading}>
          {loading ? "Saving…" : "Save Plan"}
        </Button>
      </div>
    </div>
  );
}

// ─── Diet Plan Card ────────────────────────────────────────────────────────────

function DietPlanCard({ plan, onDeleted }: { plan: DietPlan; onDeleted: () => void }) {
  const [editing, setEditing] = useState(false);
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

  return (
    <>
      <Card className="p-4">
        <div className="flex items-start justify-between gap-4">
          <div className="space-y-2 flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className="rounded-full bg-pink-100 px-3 py-0.5 text-xs font-semibold text-pink-700 dark:bg-pink-900/30 dark:text-pink-300">
                {plan.type}
              </span>
              <span className="text-sm font-semibold text-slate-700 dark:text-slate-200">{plan.calories} kcal / day</span>
            </div>
            <div className="grid grid-cols-2 gap-x-6 gap-y-1 text-xs text-slate-600 dark:text-slate-400 sm:grid-cols-4">
              {plan.meals.breakfast && <span>Breakfast: {plan.meals.breakfast}</span>}
              {plan.meals.lunch     && <span>Lunch: {plan.meals.lunch}</span>}
              {plan.meals.dinner    && <span>Dinner: {plan.meals.dinner}</span>}
              {plan.meals.snacks    && <span>Snacks: {plan.meals.snacks}</span>}
            </div>
          </div>
          <div className="flex gap-2 shrink-0">
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
            <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
          </div>
        </div>
      </Card>

      <ConfirmModal
        open={confirmDelete}
        title="Delete Diet Plan?"
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => { del.mutate(); setConfirmDelete(false); }}
        confirmLabel="Delete"
      >
        The &quot;{plan.type}&quot; diet plan will be permanently deleted.
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
        <PageHeader title="Diet Management" description="Assign meal plans to user fitness goals." />
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
