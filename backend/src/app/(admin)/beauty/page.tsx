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
import { glowContentService } from "@/services/glow-content.service";
import type { BeautyPost, GlowCategory, GlowShort } from "@/types";

/** Surface the API's validation message instead of a generic toast. */
function apiMessage(err: unknown, fallback: string): string {
  const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
  return msg ? `${fallback} — ${msg}` : fallback;
}

const colorInputCls = "h-9 w-full rounded-lg border border-slate-300 dark:border-slate-700";
const textareaCls =
  "focus-ring min-h-[110px] w-full rounded-xl border border-slate-300 bg-white p-3 text-sm dark:border-slate-700 dark:bg-slate-900";

// ─── Glow Reads (BeautyPost) ───────────────────────────────────────────────────

type ReadForm = {
  title: string;
  content: string;
  imageUrl: string;
  tag: string;
  tagColor: string;
  tagBackground: string;
  minutesRead: string;
  order: string;
};

const emptyRead = (): ReadForm => ({
  title: "",
  content: "",
  imageUrl: "",
  tag: "SKINCARE",
  tagColor: "#C4185A",
  tagBackground: "#FCE4EC",
  minutesRead: "4",
  order: "0",
});

function readToForm(r: BeautyPost): ReadForm {
  return {
    title: r.title,
    content: r.content,
    imageUrl: r.imageUrl ?? "",
    tag: r.tag,
    tagColor: r.tagColor,
    tagBackground: r.tagBackground,
    minutesRead: String(r.minutesRead),
    order: String(r.order),
  };
}

function readFormToPayload(f: ReadForm) {
  return {
    title: f.title.trim(),
    content: f.content.trim(),
    imageUrl: f.imageUrl.trim() || undefined,
    tag: f.tag.trim() || "SKINCARE",
    tagColor: f.tagColor.trim() || "#C4185A",
    tagBackground: f.tagBackground.trim() || "#FCE4EC",
    minutesRead: parseInt(f.minutesRead) || 4,
    order: parseInt(f.order) || 0,
  };
}

function readMissing(f: ReadForm): string[] {
  const missing: string[] = [];
  if (!f.title.trim()) missing.push("Title");
  if (!f.content.trim()) missing.push("Content");
  return missing;
}

function ReadFormPanel({ initial, onSave, onCancel, loading }: {
  initial: ReadForm;
  onSave: (f: ReadForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof ReadForm>(k: K, v: ReadForm[K]) => setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-4 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="space-y-1">
        <label className="text-xs font-semibold text-slate-500">Title *</label>
        <Input value={f.title} onChange={(e) => set("title", e.target.value)} placeholder="How to Choose Right Serum" />
      </div>
      <div className="space-y-1">
        <label className="text-xs font-semibold text-slate-500">Content *</label>
        <textarea
          className={textareaCls}
          value={f.content}
          onChange={(e) => set("content", e.target.value)}
          placeholder="Full article body shown when the reader taps in..."
        />
      </div>
      <ImageUploadField label="Card image" value={f.imageUrl} onChange={(url) => set("imageUrl", url)} folder="exercises" />
      <div className="grid gap-3 sm:grid-cols-5">
        <div className="space-y-1 sm:col-span-2">
          <label className="text-xs font-semibold text-slate-500">Tag label *</label>
          <Input value={f.tag} onChange={(e) => set("tag", e.target.value)} placeholder="SKINCARE" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Tag text color</label>
          <input type="color" value={f.tagColor} onChange={(e) => set("tagColor", e.target.value)} className={colorInputCls} />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Tag background</label>
          <input type="color" value={f.tagBackground} onChange={(e) => set("tagBackground", e.target.value)} className={colorInputCls} />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Minutes to read</label>
          <Input type="number" value={f.minutesRead} onChange={(e) => set("minutesRead", e.target.value)} />
        </div>
      </div>
      <div className="space-y-1 sm:w-40">
        <label className="text-xs font-semibold text-slate-500">Sort order</label>
        <Input type="number" value={f.order} onChange={(e) => set("order", e.target.value)} />
      </div>
      <div className="flex items-center justify-end gap-3">
        {readMissing(f).length > 0 && (
          <p className="text-xs font-medium text-amber-600 dark:text-amber-400">Still required: {readMissing(f).join(", ")}</p>
        )}
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading || readMissing(f).length > 0}>
          {loading ? "Saving…" : "Save Read"}
        </Button>
      </div>
    </div>
  );
}

function ReadCard({ read, onDeleted }: { read: BeautyPost; onDeleted: () => void }) {
  const [editing, setEditing] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const qc = useQueryClient();

  const update = useMutation({
    mutationFn: (f: ReadForm) => glowContentService.updateRead(read.id, readFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-reads"] });
      setEditing(false);
      toast.success("Read updated");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to update read")),
  });

  const del = useMutation({
    mutationFn: () => glowContentService.deleteRead(read.id),
    onSuccess: () => { onDeleted(); toast.success("Read deleted"); },
    onError: (err) => toast.error(apiMessage(err, "Failed to delete read")),
  });

  if (editing) {
    return (
      <ReadFormPanel initial={readToForm(read)} onSave={(f) => update.mutate(f)} onCancel={() => setEditing(false)} loading={update.isPending} />
    );
  }

  return (
    <>
      <Card className="p-4">
        <div className="flex items-center justify-between gap-4">
          {read.imageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={read.imageUrl} alt="" className="h-14 w-14 shrink-0 rounded-lg object-cover" />
          )}
          <div className="min-w-0 flex-1 space-y-1">
            <div className="flex flex-wrap items-center gap-2">
              <span
                className="rounded-full px-3 py-0.5 text-xs font-semibold"
                style={{ backgroundColor: read.tagBackground, color: read.tagColor }}
              >
                {read.tag}
              </span>
              <span className="text-sm font-semibold text-slate-700 dark:text-slate-200">{read.title}</span>
              <span className="text-xs text-slate-400">{read.minutesRead} min read</span>
            </div>
            <p className="line-clamp-1 text-xs text-slate-500 dark:text-slate-400">{read.content}</p>
          </div>
          <div className="flex shrink-0 gap-2">
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
            <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
          </div>
        </div>
      </Card>
      <ConfirmModal open={confirmDelete} title="Delete Read?" onClose={() => setConfirmDelete(false)} onConfirm={() => { del.mutate(); setConfirmDelete(false); }} confirmLabel="Delete">
        &quot;{read.title}&quot; will be permanently deleted.
      </ConfirmModal>
    </>
  );
}

// ─── Explore by Goals (GlowCategory) ────────────────────────────────────────────

type CategoryForm = { emoji: string; title: string; subtitle: string; background: string; order: string };

const emptyGlowCategory = (): CategoryForm => ({ emoji: "🧖‍♀️", title: "", subtitle: "", background: "#FCE4EC", order: "0" });

function glowCategoryToForm(c: GlowCategory): CategoryForm {
  return { emoji: c.emoji, title: c.title, subtitle: c.subtitle, background: c.background, order: String(c.order) };
}

function glowCategoryFormToPayload(f: CategoryForm) {
  return {
    emoji: f.emoji.trim() || "✨",
    title: f.title.trim(),
    subtitle: f.subtitle.trim(),
    background: f.background.trim() || "#FCE4EC",
    order: parseInt(f.order) || 0,
  };
}

function glowCategoryMissing(f: CategoryForm): string[] {
  const missing: string[] = [];
  if (!f.title.trim()) missing.push("Title");
  if (!f.subtitle.trim()) missing.push("Subtitle");
  return missing;
}

function GlowCategoryFormPanel({ initial, onSave, onCancel, loading }: {
  initial: CategoryForm;
  onSave: (f: CategoryForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof CategoryForm>(k: K, v: CategoryForm[K]) => setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-3 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="grid grid-cols-[70px_1fr_1fr_90px_80px] items-end gap-3">
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Emoji</label>
          <Input value={f.emoji} onChange={(e) => set("emoji", e.target.value)} placeholder="🧖‍♀️" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Title *</label>
          <Input value={f.title} onChange={(e) => set("title", e.target.value)} placeholder="Skin Care" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Subtitle *</label>
          <Input value={f.subtitle} onChange={(e) => set("subtitle", e.target.value)} placeholder="Healthy Skin" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Background</label>
          <input type="color" value={f.background} onChange={(e) => set("background", e.target.value)} className={colorInputCls} />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Order</label>
          <Input type="number" value={f.order} onChange={(e) => set("order", e.target.value)} />
        </div>
      </div>
      <div className="flex items-center justify-end gap-3">
        {glowCategoryMissing(f).length > 0 && (
          <p className="text-xs font-medium text-amber-600 dark:text-amber-400">Still required: {glowCategoryMissing(f).join(", ")}</p>
        )}
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading || glowCategoryMissing(f).length > 0}>
          {loading ? "Saving…" : "Save Category"}
        </Button>
      </div>
    </div>
  );
}

function GlowCategoryCard({ category, onDeleted }: { category: GlowCategory; onDeleted: () => void }) {
  const [editing, setEditing] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const qc = useQueryClient();

  const update = useMutation({
    mutationFn: (f: CategoryForm) => glowContentService.updateCategory(category.id, glowCategoryFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-categories"] });
      setEditing(false);
      toast.success("Category updated");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to update category")),
  });

  const del = useMutation({
    mutationFn: () => glowContentService.deleteCategory(category.id),
    onSuccess: () => { onDeleted(); toast.success("Category deleted"); },
    onError: (err) => toast.error(apiMessage(err, "Failed to delete category")),
  });

  if (editing) {
    return <GlowCategoryFormPanel initial={glowCategoryToForm(category)} onSave={(f) => update.mutate(f)} onCancel={() => setEditing(false)} loading={update.isPending} />;
  }

  return (
    <>
      <Card className="p-3">
        <div className="flex items-center justify-between gap-3">
          <div className="flex min-w-0 flex-1 items-center gap-3">
            <div
              className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full text-lg"
              style={{ backgroundColor: category.background }}
            >
              {category.emoji}
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-slate-700 dark:text-slate-200">{category.title}</p>
              <p className="truncate text-xs text-slate-400">{category.subtitle}</p>
            </div>
          </div>
          <div className="flex shrink-0 gap-2">
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
            <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
          </div>
        </div>
      </Card>
      <ConfirmModal open={confirmDelete} title="Delete Category?" onClose={() => setConfirmDelete(false)} onConfirm={() => { del.mutate(); setConfirmDelete(false); }} confirmLabel="Delete">
        &quot;{category.title}&quot; will be permanently deleted.
      </ConfirmModal>
    </>
  );
}

// ─── Shorts & Quick Tips (GlowShort) ────────────────────────────────────────────

type ShortForm = { imageUrl: string; duration: string; title: string; views: string; order: string };

const emptyShort = (): ShortForm => ({ imageUrl: "", duration: "0:30", title: "", views: "0 views", order: "0" });

function shortToForm(s: GlowShort): ShortForm {
  return { imageUrl: s.imageUrl ?? "", duration: s.duration, title: s.title, views: s.views, order: String(s.order) };
}

function shortFormToPayload(f: ShortForm) {
  return {
    imageUrl: f.imageUrl.trim() || undefined,
    duration: f.duration.trim() || "0:30",
    title: f.title.trim(),
    views: f.views.trim() || "0 views",
    order: parseInt(f.order) || 0,
  };
}

function shortMissing(f: ShortForm): string[] {
  const missing: string[] = [];
  if (!f.title.trim()) missing.push("Title");
  if (!f.duration.trim()) missing.push("Duration");
  return missing;
}

function ShortFormPanel({ initial, onSave, onCancel, loading }: {
  initial: ShortForm;
  onSave: (f: ShortForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof ShortForm>(k: K, v: ShortForm[K]) => setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-3 rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800">
      <div className="grid gap-3 sm:grid-cols-3">
        <div className="space-y-1 sm:col-span-2">
          <label className="text-xs font-semibold text-slate-500">Title *</label>
          <Input value={f.title} onChange={(e) => set("title", e.target.value)} placeholder="Morning Detox for Energy Boost" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Duration *</label>
          <Input value={f.duration} onChange={(e) => set("duration", e.target.value)} placeholder="0:45" />
        </div>
      </div>
      <div className="grid gap-3 sm:grid-cols-2">
        <ImageUploadField label="Video thumbnail" value={f.imageUrl} onChange={(url) => set("imageUrl", url)} folder="exercises" />
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Views label (display only)</label>
          <Input value={f.views} onChange={(e) => set("views", e.target.value)} placeholder="10.2k views" />
        </div>
      </div>
      <div className="space-y-1 sm:w-40">
        <label className="text-xs font-semibold text-slate-500">Sort order</label>
        <Input type="number" value={f.order} onChange={(e) => set("order", e.target.value)} />
      </div>
      <div className="flex items-center justify-end gap-3">
        {shortMissing(f).length > 0 && (
          <p className="text-xs font-medium text-amber-600 dark:text-amber-400">Still required: {shortMissing(f).join(", ")}</p>
        )}
        <Button variant="ghost" onClick={onCancel}>Cancel</Button>
        <Button onClick={() => onSave(f)} disabled={loading || shortMissing(f).length > 0}>
          {loading ? "Saving…" : "Save Short"}
        </Button>
      </div>
    </div>
  );
}

function ShortCard({ short, onDeleted }: { short: GlowShort; onDeleted: () => void }) {
  const [editing, setEditing] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const qc = useQueryClient();

  const update = useMutation({
    mutationFn: (f: ShortForm) => glowContentService.updateShort(short.id, shortFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-shorts"] });
      setEditing(false);
      toast.success("Short updated");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to update short")),
  });

  const del = useMutation({
    mutationFn: () => glowContentService.deleteShort(short.id),
    onSuccess: () => { onDeleted(); toast.success("Short deleted"); },
    onError: (err) => toast.error(apiMessage(err, "Failed to delete short")),
  });

  if (editing) {
    return <ShortFormPanel initial={shortToForm(short)} onSave={(f) => update.mutate(f)} onCancel={() => setEditing(false)} loading={update.isPending} />;
  }

  return (
    <>
      <Card className="p-4">
        <div className="flex items-center justify-between gap-4">
          {short.imageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={short.imageUrl} alt="" className="h-14 w-14 shrink-0 rounded-lg object-cover" />
          )}
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <span className="rounded-full bg-slate-800 px-2 py-0.5 text-xs font-semibold text-white">{short.duration}</span>
              <span className="text-sm font-semibold text-slate-700 dark:text-slate-200">{short.title}</span>
              <span className="text-xs text-slate-400">{short.views}</span>
            </div>
          </div>
          <div className="flex shrink-0 gap-2">
            <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => setEditing(true)}>Edit</Button>
            <Button variant="danger" className="text-xs px-3 py-1.5" onClick={() => setConfirmDelete(true)}>Delete</Button>
          </div>
        </div>
      </Card>
      <ConfirmModal open={confirmDelete} title="Delete Short?" onClose={() => setConfirmDelete(false)} onConfirm={() => { del.mutate(); setConfirmDelete(false); }} confirmLabel="Delete">
        &quot;{short.title}&quot; will be permanently deleted.
      </ConfirmModal>
    </>
  );
}

// ─── Page ──────────────────────────────────────────────────────────────────────

export default function GlowContentPage() {
  const [creatingRead, setCreatingRead] = useState(false);
  const [creatingCategory, setCreatingCategory] = useState(false);
  const [creatingShort, setCreatingShort] = useState(false);
  const qc = useQueryClient();

  const { data: reads = [], isLoading: readsLoading } = useQuery({
    queryKey: ["glow-reads"],
    queryFn: () => glowContentService.listReads(),
  });
  const { data: categories = [], isLoading: categoriesLoading } = useQuery({
    queryKey: ["glow-categories"],
    queryFn: () => glowContentService.listCategories(),
  });
  const { data: shorts = [], isLoading: shortsLoading } = useQuery({
    queryKey: ["glow-shorts"],
    queryFn: () => glowContentService.listShorts(),
  });

  const createRead = useMutation({
    mutationFn: (f: ReadForm) => glowContentService.createRead(readFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-reads"] });
      setCreatingRead(false);
      toast.success("Read created");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to create read")),
  });

  const createCategory = useMutation({
    mutationFn: (f: CategoryForm) => glowContentService.createCategory(glowCategoryFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-categories"] });
      setCreatingCategory(false);
      toast.success("Category created");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to create category")),
  });

  const createShort = useMutation({
    mutationFn: (f: ShortForm) => glowContentService.createShort(shortFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-shorts"] });
      setCreatingShort(false);
      toast.success("Short created");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to create short")),
  });

  return (
    <div className="space-y-5">
      <PageHeader
        title="Glow Content"
        description="Everything shown on the app's Glow screen: category tiles, articles, and short videos."
      />

      {/* ── 1. Explore by Goals ── */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-base font-bold text-slate-700 dark:text-slate-200">1 · Explore by Goals</h2>
          <p className="text-xs text-slate-400">The row of round category tiles near the top of the Glow screen.</p>
        </div>
        {!creatingCategory && <Button onClick={() => setCreatingCategory(true)}>+ New Category</Button>}
      </div>
      {creatingCategory && (
        <GlowCategoryFormPanel initial={emptyGlowCategory()} onSave={(f) => createCategory.mutate(f)} onCancel={() => setCreatingCategory(false)} loading={createCategory.isPending} />
      )}
      {categoriesLoading ? (
        <Card><p className="text-sm text-slate-400">Loading categories…</p></Card>
      ) : categories.length === 0 ? (
        <Card><p className="text-sm text-slate-400">No categories yet — the app shows its built-in defaults until you add some.</p></Card>
      ) : (
        <div className="space-y-2">
          {categories.map((c) => (
            <GlowCategoryCard key={c.id} category={c} onDeleted={() => void qc.invalidateQueries({ queryKey: ["glow-categories"] })} />
          ))}
        </div>
      )}

      {/* ── 2. Glow Reads ── */}
      <div className="flex items-center justify-between pt-2">
        <div>
          <h2 className="text-base font-bold text-slate-700 dark:text-slate-200">2 · Glow Reads</h2>
          <p className="text-xs text-slate-400">Article cards in the horizontally-scrolling Glow Reads row.</p>
        </div>
        {!creatingRead && <Button onClick={() => setCreatingRead(true)}>+ New Read</Button>}
      </div>
      {creatingRead && (
        <ReadFormPanel initial={emptyRead()} onSave={(f) => createRead.mutate(f)} onCancel={() => setCreatingRead(false)} loading={createRead.isPending} />
      )}
      {readsLoading ? (
        <Card><p className="text-sm text-slate-400">Loading reads…</p></Card>
      ) : reads.length === 0 ? (
        <Card><p className="text-sm text-slate-400">No reads yet — the app shows placeholder cards until you add some.</p></Card>
      ) : (
        <div className="space-y-3">
          {reads.map((r) => (
            <ReadCard key={r.id} read={r} onDeleted={() => void qc.invalidateQueries({ queryKey: ["glow-reads"] })} />
          ))}
        </div>
      )}

      {/* ── 3. Shorts & Quick Tips ── */}
      <div className="flex items-center justify-between pt-2">
        <div>
          <h2 className="text-base font-bold text-slate-700 dark:text-slate-200">3 · Shorts & Quick Tips</h2>
          <p className="text-xs text-slate-400">
            Short video tiles. The first one (lowest sort order) is featured as the big tile.
          </p>
        </div>
        {!creatingShort && <Button onClick={() => setCreatingShort(true)}>+ New Short</Button>}
      </div>
      {creatingShort && (
        <ShortFormPanel initial={emptyShort()} onSave={(f) => createShort.mutate(f)} onCancel={() => setCreatingShort(false)} loading={createShort.isPending} />
      )}
      {shortsLoading ? (
        <Card><p className="text-sm text-slate-400">Loading shorts…</p></Card>
      ) : shorts.length === 0 ? (
        <Card><p className="text-sm text-slate-400">No shorts yet — the app shows placeholder tiles until you add some.</p></Card>
      ) : (
        <div className="space-y-3">
          {shorts.map((s) => (
            <ShortCard key={s.id} short={s} onDeleted={() => void qc.invalidateQueries({ queryKey: ["glow-shorts"] })} />
          ))}
        </div>
      )}
    </div>
  );
}
