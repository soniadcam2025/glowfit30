"use client";

import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Download, ShieldAlert, Trash2 } from "lucide-react";
import { withRoleGuard } from "@/components/auth/with-role-guard";
import { PageHeader } from "@/components/common/page-header";
import { Alert } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import {
  CONFIRM_PHRASE,
  maintenanceService,
  type ResetScope,
  type TableCounts,
} from "@/services/maintenance.service";

type ResetDef = {
  scope: ResetScope;
  title: string;
  description: string;
  /** Everything the delete removes, including cascades. */
  impact: (c: TableCounts) => { label: string; n: number }[];
};

const RESETS: ResetDef[] = [
  {
    scope: "workouts",
    title: "Reset all workouts",
    description: "Deletes every workout plan, its days and its exercises.",
    impact: (c) => [
      { label: "workout plans", n: c.workouts },
      { label: "days", n: c.workoutDays },
      { label: "exercises", n: c.exercises },
      // Progress cascades from WorkoutDay — this is the part that surprises
      // people, so it is listed rather than discovered afterwards.
      { label: "user progress records", n: c.progress },
    ],
  },
  {
    scope: "diet",
    title: "Reset all diet plans",
    description: "Deletes every diet plan and its days.",
    impact: (c) => [
      { label: "diet plans", n: c.dietPlans },
      { label: "plan days", n: c.dietPlanDays },
    ],
  },
  {
    scope: "glow-reads",
    title: "Reset all Glow Reads",
    description: "Deletes every Glow Reads article. Shorts and categories are untouched.",
    impact: (c) => [{ label: "articles", n: c.beautyPosts }],
  },
  {
    scope: "workout-library",
    title: "Reset the Workout Library",
    description:
      "Deletes every library category, item and exercise. The day-by-day workout plans are separate and untouched.",
    impact: (c) => [
      { label: "categories", n: c.libraryCategories },
      { label: "items", n: c.libraryItems },
      { label: "exercises", n: c.libraryExercises },
    ],
  },
  {
    scope: "glow-content",
    title: "Reset Glow Content",
    description:
      "Deletes Explore by Goals categories and every Short / Quick Tip. Glow Reads articles survive but lose their category.",
    impact: (c) => [
      { label: "categories (Explore by Goals)", n: c.glowCategories },
      { label: "shorts & quick tips", n: c.glowShorts },
    ],
  },
];

function DeleteResetPage() {
  const qc = useQueryClient();
  // Session-scoped on purpose: a backup from last week is not evidence that
  // today's data is safe, and this resets on reload.
  const [backedUp, setBackedUp] = useState(false);
  const [pending, setPending] = useState<ResetDef | null>(null);
  const [typed, setTyped] = useState("");
  const [selected, setSelected] = useState<string[]>([]);
  // Deleting the rows but keeping the files would leave objects in the bucket
  // that nothing references, so this defaults on.
  const [deleteMedia, setDeleteMedia] = useState(true);

  const { data: counts, isLoading } = useQuery({
    queryKey: ["maintenance-counts"],
    queryFn: () => maintenanceService.counts(),
  });

  const allTables = counts?.tables ?? [];

  const backup = useMutation({
    mutationFn: (tables: string[]) => maintenanceService.downloadBackup(tables),
    onSuccess: (filename) => {
      setBackedUp(true);
      toast.success(`Backup downloaded — ${filename}`);
    },
    onError: () => toast.error("Backup failed. Reset stays locked."),
  });

  const reset = useMutation({
    mutationFn: (scope: ResetScope) => maintenanceService.reset(scope, deleteMedia),
    onSuccess: (result) => {
      void qc.invalidateQueries({ queryKey: ["maintenance-counts"] });
      const summary = Object.entries(result)
        .map(([k, v]) => `${v} ${k}`)
        .join(", ");
      toast.success(`Deleted ${summary}`);
      closeDialog();
    },
    onError: () => toast.error("Reset failed. Nothing was deleted."),
  });

  const closeDialog = () => {
    setPending(null);
    setTyped("");
  };

  const phrase = pending ? CONFIRM_PHRASE[pending.scope] : "";
  const phraseMatches = typed === phrase;

  return (
    <div className="space-y-4">
      <PageHeader
        title="Delete / Reset"
        description="Bulk deletion and full-database export."
      />

      <Alert variant="danger" title="These deletions cannot be undone">
        There is no automated database backup on the server. Download the export below
        first — it is the only copy you will have.
      </Alert>

      {/* ── Backup ── */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Download className="h-4 w-4" />
            Database backup
          </CardTitle>
          <CardDescription>
            One Excel workbook, a sheet per table, in dependency order so a restore can
            be inserted top to bottom. Password hashes are redacted.
          </CardDescription>
        </CardHeader>

        <div className="mb-3">
          <div className="mb-2 flex flex-wrap items-center gap-2">
            <span className="text-xs font-semibold text-muted-foreground">
              Tables to include
            </span>
            <Button variant="ghost" size="sm" onClick={() => setSelected(allTables)}>
              Select all
            </Button>
            <Button variant="ghost" size="sm" onClick={() => setSelected([])}>
              Clear
            </Button>
          </div>
          <div className="flex flex-wrap gap-1.5">
            {allTables.map((t) => {
              const on = selected.includes(t);
              return (
                <button
                  key={t}
                  type="button"
                  aria-pressed={on}
                  onClick={() =>
                    setSelected((prev) =>
                      prev.includes(t) ? prev.filter((x) => x !== t) : [...prev, t],
                    )
                  }
                  className={
                    on
                      ? "rounded-full bg-primary px-2.5 py-1 text-xs font-medium text-primary-foreground"
                      : "rounded-full border border-border px-2.5 py-1 text-xs text-muted-foreground hover:bg-muted"
                  }
                >
                  {t}
                </button>
              );
            })}
          </div>
          <p className="mt-2 text-xs text-muted-foreground">
            {selected.length === 0
              ? "Nothing selected — the download will include every table."
              : `${selected.length} of ${allTables.length} tables selected.`}
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <Button onClick={() => backup.mutate(selected)} disabled={backup.isPending}>
            <Download className="h-4 w-4" />
            {backup.isPending ? "Generating…" : "Download backup (.xlsx)"}
          </Button>
          {backedUp && <Badge variant="success">Downloaded this session</Badge>}
        </div>
      </Card>

      {/* ── Resets ──
          Grid rather than a stack: five full-width cards is a lot of scrolling
          for what is really a menu of one-click actions. Cards stretch to equal
          height so the buttons line up across a row. */}
      <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        {RESETS.map((def) => {
          const impact = counts ? def.impact(counts) : [];
          const total = impact.reduce((sum, i) => sum + i.n, 0);
          const nothingToDelete = !isLoading && total === 0;

          return (
            <Card key={def.scope} className="flex h-full flex-col">
              <CardHeader>
                <CardTitle className="flex items-start gap-2">
                  <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0 text-danger" />
                  <span>{def.title}</span>
                </CardTitle>
                <CardDescription>{def.description}</CardDescription>
              </CardHeader>

              <div className="mb-3 flex flex-wrap gap-1.5">
                {isLoading ? (
                  <span className="text-xs text-muted-foreground">Counting…</span>
                ) : (
                  impact.map((i) => (
                    <Badge key={i.label} variant={i.n > 0 ? "danger" : "outline"}>
                      {i.n} {i.label}
                    </Badge>
                  ))
                )}
              </div>

              {/* mt-auto pins the action to the bottom regardless of how much
                  description or how many badges the card above it carries. */}
              <div className="mt-auto">
                <Button
                  variant="danger"
                  className="w-full"
                  disabled={nothingToDelete}
                  onClick={() => {
                    setPending(def);
                    setTyped("");
                  }}
                >
                  <Trash2 className="h-4 w-4" />
                  <span className="truncate">{def.title}</span>
                </Button>
                {nothingToDelete && (
                  <p className="mt-2 text-xs text-muted-foreground">Nothing to delete.</p>
                )}
              </div>
            </Card>
          );
        })}
      </div>

      {/* ── Type-to-confirm ── */}
      <Dialog open={!!pending} onOpenChange={(open) => !open && closeDialog()}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{pending?.title}</DialogTitle>
            <DialogDescription>
              This permanently deletes data from the live database.
            </DialogDescription>
          </DialogHeader>

          {pending && counts && (
            <div className="space-y-3">
              <Alert variant="danger" title="What will be deleted">
                <ul className="mt-1 list-inside list-disc">
                  {pending.impact(counts).map((i) => (
                    <li key={i.label}>
                      <strong>{i.n}</strong> {i.label}
                    </li>
                  ))}
                </ul>
              </Alert>

              {/* A backup is no longer required, but its absence is worth saying
                  out loud at the moment of deletion rather than never. */}
              {!backedUp && (
                <Alert variant="warning" title="No backup downloaded this session">
                  The server has no automated database backup. If this is wrong, there is
                  nothing to restore from.
                </Alert>
              )}

              <label className="flex items-start gap-2 rounded-lg border border-border p-3">
                <input
                  type="checkbox"
                  className="mt-0.5"
                  checked={deleteMedia}
                  onChange={(e) => setDeleteMedia(e.target.checked)}
                />
                <span className="text-xs">
                  <span className="font-semibold text-foreground">
                    Also delete media from the media server
                  </span>
                  <span className="block text-muted-foreground">
                    Removes the images and videos these rows point at from Vultr Object
                    Storage. Unchecking leaves them in the bucket, costing storage with
                    nothing referencing them.
                  </span>
                </span>
              </label>

              <div className="space-y-1.5">
                <label className="text-xs font-semibold text-muted-foreground">
                  Type <span className="font-mono text-danger">{phrase}</span> to confirm
                </label>
                <Input
                  value={typed}
                  onChange={(e) => setTyped(e.target.value)}
                  placeholder={phrase}
                  autoComplete="off"
                  aria-invalid={typed.length > 0 && !phraseMatches}
                />
              </div>
            </div>
          )}

          <DialogFooter>
            <Button variant="ghost" onClick={closeDialog}>
              Cancel
            </Button>
            <Button
              variant="danger"
              disabled={!phraseMatches || reset.isPending}
              onClick={() => pending && reset.mutate(pending.scope)}
            >
              {reset.isPending ? "Deleting…" : "Delete permanently"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}

export default withRoleGuard(DeleteResetPage, ["super_admin"]);
