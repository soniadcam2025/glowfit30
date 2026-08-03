"use client";

import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import type { ColumnDef } from "@tanstack/react-table";
import { toast } from "sonner";
import { ChevronRight, Pencil, Trash2 } from "lucide-react";
import { PageHeader } from "@/components/common/page-header";
import { DataTable } from "@/components/common/data-table";
import { EmptyState, TableSkeleton } from "@/components/common/state";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { ConfirmModal } from "@/components/ui/modal";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ImageUploadField } from "@/components/common/image-upload-field";
import { VideoUploadField } from "@/components/common/video-upload-field";
import { glowContentService } from "@/services/glow-content.service";
import type {
  BeautyPost,
  GlowCategory,
  GlowSectionItem,
  GlowSections,
  GlowShort,
  GlowTopic,
} from "@/types";

/** Surface the API's validation message instead of a generic toast. */
function apiMessage(err: unknown, fallback: string): string {
  const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
  return msg ? `${fallback} — ${msg}` : fallback;
}

const colorInputCls = "h-9 w-full rounded-lg border border-slate-300 dark:border-slate-700";
const textareaCls =
  "focus-ring min-h-[110px] w-full rounded-xl border border-slate-300 bg-white p-3 text-sm dark:border-slate-700 dark:bg-slate-900";
const selectCls =
  "focus-ring h-9 w-full rounded-lg border border-slate-300 bg-white px-2 text-sm dark:border-slate-700 dark:bg-slate-900";

/** Shared category picker used by both the Reads and Shorts forms. */
function CategorySelect({ categories, value, onChange }: {
  categories: GlowCategory[];
  value: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="space-y-1">
      <label className="text-xs font-semibold text-slate-500">Category</label>
      <select className={selectCls} value={value} onChange={(e) => onChange(e.target.value)}>
        <option value="">No category</option>
        {categories.map((c) => (
          <option key={c.id} value={c.id}>{c.emoji} {c.title}</option>
        ))}
      </select>
    </div>
  );
}

/** Editor for GlowCategory.topics ("Popular Topics" chips on the category detail screen). */
/** Generic editor for a `{ emoji, label }[]` field — used for GlowCategory.topics and BeautyPost/GlowShort.chips. */
function TopicEditor({ label, addLabel, topics, onChange }: {
  label: string;
  addLabel: string;
  topics: GlowTopic[];
  onChange: (topics: GlowTopic[]) => void;
}) {
  const patch = (i: number, p: Partial<GlowTopic>) =>
    onChange(topics.map((t, idx) => (idx === i ? { ...t, ...p } : t)));

  return (
    <div className="space-y-2">
      <p className="text-xs font-semibold text-slate-500">{label}</p>
      {topics.map((t, i) => (
        <div key={i} className="flex items-center gap-2">
          <Input className="w-16" value={t.emoji} onChange={(e) => patch(i, { emoji: e.target.value })} placeholder="🌿" />
          <Input value={t.label} onChange={(e) => patch(i, { label: e.target.value })} placeholder="Acne Care" />
          <Button variant="ghost" className="text-xs px-2 py-1" onClick={() => onChange(topics.filter((_, idx) => idx !== i))}>
            Remove
          </Button>
        </div>
      ))}
      <Button variant="secondary" className="text-xs px-3 py-1.5" onClick={() => onChange([...topics, { emoji: "✨", label: "" }])}>
        + {addLabel}
      </Button>
    </div>
  );
}

const emptySectionItem = (): GlowSectionItem => ({ imageUrl: "", videoUrl: "", title: "", description: "" });

/** Max length for a per-tip clip in the Shorts story player. */
const TIP_VIDEO_MAX_SECONDS = 30;
const emptySections = (): GlowSections => ({ problemCause: [], solution: [], tips: [] });

function hasSectionContent(sections?: Partial<GlowSections>): boolean {
  if (!sections) return false;
  return Object.values(sections).some((items) => Array.isArray(items) && items.length > 0);
}

/** Small at-a-glance indicators for the list view — is this item premium-gated, and does it
 * have the tabbed detail-screen content filled in, without opening the edit form to check. */
function ContentBadges({ isPremium, sections }: { isPremium?: boolean; sections?: Partial<GlowSections> }) {
  if (!isPremium && !hasSectionContent(sections)) return null;
  return (
    <>
      {isPremium && (
        <span className="rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-bold text-amber-700 dark:bg-amber-900/40 dark:text-amber-400">
          🔒 Premium
        </span>
      )}
      {hasSectionContent(sections) && (
        <span className="rounded-full bg-violet-100 px-2 py-0.5 text-[10px] font-bold text-violet-700 dark:bg-violet-900/40 dark:text-violet-300">
          📑 Has Tabs
        </span>
      )}
    </>
  );
}

/**
 * Edit/delete buttons for a table row.
 *
 * One component for all three content types — Reads, Categories and Shorts
 * previously each had their own near-identical copy. Editing is lifted to the
 * page, which swaps the table for the form; only deletion is owned here.
 */
function RowActions({
  label,
  name,
  onEdit,
  onDelete,
  onDeleted,
}: {
  label: string;
  name: string;
  onEdit: () => void;
  onDelete: () => Promise<unknown>;
  onDeleted: () => void;
}) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const del = useMutation({
    mutationFn: onDelete,
    onSuccess: () => {
      onDeleted();
      toast.success(`${label} deleted`);
    },
    onError: (err) => toast.error(apiMessage(err, `Failed to delete ${label.toLowerCase()}`)),
  });

  return (
    <>
      <div className="flex gap-1.5">
        <Button variant="ghost" size="sm" aria-label={`Edit ${label.toLowerCase()}`} onClick={onEdit}>
          <Pencil className="h-3.5 w-3.5" />
        </Button>
        <Button
          variant="ghost"
          size="sm"
          aria-label={`Delete ${label.toLowerCase()}`}
          className="text-danger"
          onClick={() => setConfirmDelete(true)}
        >
          <Trash2 className="h-3.5 w-3.5" />
        </Button>
      </div>
      <ConfirmModal
        open={confirmDelete}
        title={`Delete ${label.toLowerCase()}?`}
        onClose={() => setConfirmDelete(false)}
        onConfirm={() => {
          del.mutate();
          setConfirmDelete(false);
        }}
        confirmLabel="Delete"
      >
        &quot;{name}&quot; will be permanently deleted.
      </ConfirmModal>
    </>
  );
}

/** Drop incomplete accordion cards (both title and description are required server-side). */
function cleanSections(s: GlowSections): GlowSections {
  const clean = (items: GlowSectionItem[]) => items.filter((i) => i.title.trim() && i.description.trim());
  return { problemCause: clean(s.problemCause), solution: clean(s.solution), tips: clean(s.tips) };
}

const SECTION_TABS: { key: keyof GlowSections; label: string }[] = [
  { key: "problemCause", label: "Problem & Cause" },
  { key: "solution", label: "Solution" },
  { key: "tips", label: "Tips" },
];

/** Editor for the fixed 3-tab detail-screen content (Problem & Cause / Solution / Tips),
 * each an ordered list of expandable image+title+description cards. All optional. */
function SectionsEditor({ sections, onChange, variant = "read" }: {
  sections: Partial<GlowSections>;
  onChange: (sections: GlowSections) => void;
  /** Shorts render the "Tips" cards as a full-screen story pager, Reads render
   *  all three groups as tabs. The copy below has to say which, or authors
   *  can't tell why cards appear where they do. */
  variant?: "read" | "short";
}) {
  const full: GlowSections = { ...emptySections(), ...sections };
  const isShort = variant === "short";

  const setTab = (key: keyof GlowSections, items: GlowSectionItem[]) =>
    onChange({ ...full, [key]: items });

  const patchItem = (key: keyof GlowSections, i: number, p: Partial<GlowSectionItem>) =>
    setTab(key, full[key].map((it, idx) => (idx === i ? { ...it, ...p } : it)));

  return (
    <div className="space-y-4">
      {isShort ? (
        <p className="text-xs font-semibold text-slate-500">
          Each <strong>Tips</strong> card below becomes one swipeable step in the full-screen
          player — 5 cards means 5 progress segments and &quot;Tip 1 of 5&quot;. Add none and the
          short opens the plain detail screen instead.
        </p>
      ) : (
        <p className="text-xs font-semibold text-slate-500">
          Detail screen tabs (optional — leave empty to just show the plain content/description above)
        </p>
      )}
      {SECTION_TABS.map(({ key, label }) => (
        <div key={key} className="space-y-2 rounded-lg border border-slate-200 p-3 dark:border-slate-700">
          <p className="text-xs font-bold text-slate-600 dark:text-slate-300">
            {label}
            {isShort && key === "tips" && (
              <span className="ml-2 font-medium text-pink-600 dark:text-pink-400">
                → drives the full-screen player
              </span>
            )}
            {isShort && key !== "tips" && (
              <span className="ml-2 font-medium text-slate-400">
                → only shown via &quot;View full details&quot;
              </span>
            )}
          </p>
          {full[key].map((item, i) => (
            <div key={i} className="space-y-2 rounded-lg bg-slate-100 p-3 dark:bg-slate-900">
              <div className="grid gap-2 sm:grid-cols-2">
                <Input
                  value={item.title}
                  onChange={(e) => patchItem(key, i, { title: e.target.value })}
                  placeholder="Why Do Pimples Happen?"
                />
                <ImageUploadField
                  label=""
                  value={item.imageUrl ?? ""}
                  onChange={(url) => patchItem(key, i, { imageUrl: url })}
                  folder="exercises"
                />
              </div>
              <textarea
                className={textareaCls}
                value={item.description}
                onChange={(e) => patchItem(key, i, { description: e.target.value })}
                placeholder="Excess oil, bacteria, dead skin cells..."
              />
              {isShort && key === "tips" && (
                <VideoUploadField
                  label={`Clip for this step (optional, MP4, max ${TIP_VIDEO_MAX_SECONDS}s) — plays instead of the image`}
                  value={item.videoUrl ?? ""}
                  onChange={(url) => patchItem(key, i, { videoUrl: url })}
                  maxSeconds={TIP_VIDEO_MAX_SECONDS}
                />
              )}
              {/* Cards missing either field are dropped by cleanSections() on
                  save. That used to happen silently, which looked exactly like
                  an uploaded clip vanishing on its own. */}
              {(!item.title.trim() || !item.description.trim()) && (
                <p className="rounded-md bg-amber-100 px-2 py-1.5 text-xs font-semibold text-amber-800 dark:bg-amber-900/40 dark:text-amber-300">
                  ⚠ This card needs both a title and a description — otherwise it is discarded when you save, along with any image or clip you uploaded to it.
                </p>
              )}
              <Button
                variant="ghost"
                className="text-xs px-2 py-1"
                onClick={() => setTab(key, full[key].filter((_, idx) => idx !== i))}
              >
                Remove card
              </Button>
            </div>
          ))}
          <Button
            variant="secondary"
            className="text-xs px-3 py-1.5"
            onClick={() => setTab(key, [...full[key], emptySectionItem()])}
          >
            + Add card to &quot;{label}&quot;
          </Button>
        </div>
      ))}
    </div>
  );
}

// ─── Glow Reads (BeautyPost) ───────────────────────────────────────────────────

type ReadForm = {
  title: string;
  content: string;
  imageUrl: string;
  tag: string;
  tagColor: string;
  tagBackground: string;
  minutesRead: string;
  categoryId: string;
  resultBadge: string;
  chips: GlowTopic[];
  sections: GlowSections;
  isPremium: boolean;
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
  categoryId: "",
  resultBadge: "",
  chips: [],
  sections: emptySections(),
  isPremium: false,
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
    categoryId: r.categoryId ?? "",
    resultBadge: r.resultBadge ?? "",
    chips: r.chips ?? [],
    sections: { ...emptySections(), ...r.sections },
    isPremium: r.isPremium ?? false,
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
    categoryId: f.categoryId || "",
    resultBadge: f.resultBadge.trim(),
    chips: f.chips.filter((c) => c.label.trim()),
    sections: cleanSections(f.sections),
    isPremium: f.isPremium,
    order: parseInt(f.order) || 0,
  };
}

function readMissing(f: ReadForm): string[] {
  const missing: string[] = [];
  if (!f.title.trim()) missing.push("Title");
  if (!f.content.trim()) missing.push("Content");
  return missing;
}

function ReadFormPanel({ initial, categories, onSave, onCancel, loading }: {
  initial: ReadForm;
  categories: GlowCategory[];
  onSave: (f: ReadForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof ReadForm>(k: K, v: ReadForm[K]) => setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-4">
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
      <div className="grid gap-3 sm:grid-cols-3">
        <CategorySelect categories={categories} value={f.categoryId} onChange={(v) => set("categoryId", v)} />
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Result badge</label>
          <Input value={f.resultBadge} onChange={(e) => set("resultBadge", e.target.value)} placeholder="5 Days Result" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Sort order</label>
          <Input type="number" value={f.order} onChange={(e) => set("order", e.target.value)} />
        </div>
      </div>
      <label className="flex items-center gap-2 text-xs font-semibold text-slate-500">
        <input type="checkbox" checked={f.isPremium} onChange={(e) => set("isPremium", e.target.checked)} />
        Premium content (shows a lock badge + Watch Ad / Go Premium on the detail screen)
      </label>
      <TopicEditor
        label="Detail screen chips (e.g. Natural Remedy, 5 Days Result)"
        addLabel="Add Chip"
        topics={f.chips}
        onChange={(chips) => set("chips", chips)}
      />
      <SectionsEditor sections={f.sections} onChange={(sections) => set("sections", sections)} />
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


// ─── Explore by Goals (GlowCategory) ────────────────────────────────────────────

type CategoryForm = {
  emoji: string;
  title: string;
  subtitle: string;
  background: string;
  heroImageUrl: string;
  topics: GlowTopic[];
  order: string;
};

const emptyGlowCategory = (): CategoryForm => ({
  emoji: "🧖‍♀️",
  title: "",
  subtitle: "",
  background: "#FCE4EC",
  heroImageUrl: "",
  topics: [],
  order: "0",
});

function glowCategoryToForm(c: GlowCategory): CategoryForm {
  return {
    emoji: c.emoji,
    title: c.title,
    subtitle: c.subtitle,
    background: c.background,
    heroImageUrl: c.heroImageUrl ?? "",
    topics: c.topics ?? [],
    order: String(c.order),
  };
}

function glowCategoryFormToPayload(f: CategoryForm) {
  return {
    emoji: f.emoji.trim() || "✨",
    title: f.title.trim(),
    subtitle: f.subtitle.trim(),
    background: f.background.trim() || "#FCE4EC",
    heroImageUrl: f.heroImageUrl.trim() || undefined,
    topics: f.topics.filter((t) => t.label.trim()),
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
    <div className="space-y-3">
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
      <ImageUploadField
        label="Category detail hero photo (shown at the top of the category detail screen)"
        value={f.heroImageUrl}
        onChange={(url) => set("heroImageUrl", url)}
        folder="exercises"
      />
      <TopicEditor
        label="Popular Topics (e.g. Acne Care, Glowing Skin)"
        addLabel="Add Topic"
        topics={f.topics}
        onChange={(topics) => set("topics", topics)}
      />
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


// ─── Shorts & Quick Tips (GlowShort) ────────────────────────────────────────────

type ShortForm = {
  imageUrl: string;
  duration: string;
  title: string;
  views: string;
  categoryId: string;
  content: string;
  resultBadge: string;
  chips: GlowTopic[];
  sections: GlowSections;
  isPremium: boolean;
  isFeatured: boolean;
  isTrending: boolean;
  isQuickTip: boolean;
  order: string;
};

const emptyShort = (): ShortForm => ({
  imageUrl: "",
  duration: "0:30",
  title: "",
  views: "0 views",
  categoryId: "",
  content: "",
  resultBadge: "",
  chips: [],
  sections: emptySections(),
  isPremium: false,
  isFeatured: false,
  isTrending: false,
  isQuickTip: false,
  order: "0",
});

function shortToForm(s: GlowShort): ShortForm {
  return {
    imageUrl: s.imageUrl ?? "",
    duration: s.duration,
    title: s.title,
    views: s.views,
    categoryId: s.categoryId ?? "",
    content: s.content ?? "",
    resultBadge: s.resultBadge ?? "",
    chips: s.chips ?? [],
    sections: { ...emptySections(), ...s.sections },
    isPremium: s.isPremium ?? false,
    isFeatured: s.isFeatured ?? false,
    isTrending: s.isTrending ?? false,
    isQuickTip: s.isQuickTip ?? false,
    order: String(s.order),
  };
}

function shortFormToPayload(f: ShortForm) {
  return {
    imageUrl: f.imageUrl.trim() || undefined,
    duration: f.duration.trim() || "0:30",
    title: f.title.trim(),
    views: f.views.trim() || "0 views",
    categoryId: f.categoryId || "",
    content: f.content.trim(),
    resultBadge: f.resultBadge.trim(),
    chips: f.chips.filter((c) => c.label.trim()),
    sections: cleanSections(f.sections),
    isPremium: f.isPremium,
    isFeatured: f.isFeatured,
    isTrending: f.isTrending,
    isQuickTip: f.isQuickTip,
    order: parseInt(f.order) || 0,
  };
}

function shortMissing(f: ShortForm): string[] {
  const missing: string[] = [];
  if (!f.title.trim()) missing.push("Title");
  if (!f.duration.trim()) missing.push("Duration");
  return missing;
}

function ShortFormPanel({ initial, categories, onSave, onCancel, loading }: {
  initial: ShortForm;
  categories: GlowCategory[];
  onSave: (f: ShortForm) => void;
  onCancel: () => void;
  loading?: boolean;
}) {
  const [f, setF] = useState(initial);
  const set = <K extends keyof ShortForm>(k: K, v: ShortForm[K]) => setF((p) => ({ ...p, [k]: v }));

  return (
    <div className="space-y-3">
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
        {/* Named "cover image" deliberately: shorts have no video field in the
            schema, so calling this a video thumbnail implied an upload that
            does not exist. This image is the full-screen background. */}
        <ImageUploadField label="Cover image (full-screen background)" value={f.imageUrl} onChange={(url) => set("imageUrl", url)} folder="exercises" />
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Views label (display only)</label>
          <Input value={f.views} onChange={(e) => set("views", e.target.value)} placeholder="10.2k views" />
        </div>
      </div>
      <div className="space-y-1">
        <label className="text-xs font-semibold text-slate-500">Description (shown on the detail screen if no tabs below are filled in)</label>
        <textarea
          className={textareaCls}
          value={f.content}
          onChange={(e) => set("content", e.target.value)}
          placeholder="Short description of this video..."
        />
      </div>
      <div className="grid gap-3 sm:grid-cols-3">
        <CategorySelect categories={categories} value={f.categoryId} onChange={(v) => set("categoryId", v)} />
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Result badge</label>
          <Input value={f.resultBadge} onChange={(e) => set("resultBadge", e.target.value)} placeholder="5 Days Result" />
        </div>
        <div className="space-y-1">
          <label className="text-xs font-semibold text-slate-500">Sort order</label>
          <Input type="number" value={f.order} onChange={(e) => set("order", e.target.value)} />
        </div>
      </div>
      <label className="flex items-center gap-2 text-xs font-semibold text-slate-500">
        <input type="checkbox" checked={f.isPremium} onChange={(e) => set("isPremium", e.target.checked)} />
        Premium content (first tip plays as a free preview, then locks behind Watch Ad / Go Premium)
      </label>

      {/* Placement on the app's "Shorts & Quick Tips" hub. Deliberately explicit
          flags rather than deriving from order/views/duration, so featuring is an
          editorial choice. */}
      <div className="space-y-2 rounded-lg border border-slate-200 p-3 dark:border-slate-700">
        <p className="text-xs font-bold text-slate-600 dark:text-slate-300">
          Placement on &quot;Shorts &amp; Quick Tips&quot;
        </p>
        <label className="flex items-center gap-2 text-xs font-semibold text-slate-500">
          <input type="checkbox" checked={f.isFeatured} onChange={(e) => set("isFeatured", e.target.checked)} />
          Featured — shows as the large hero card at the top of the screen
        </label>
        <label className="flex items-center gap-2 text-xs font-semibold text-slate-500">
          <input type="checkbox" checked={f.isTrending} onChange={(e) => set("isTrending", e.target.checked)} />
          Trending Now — appears in the 🔥 Trending row
        </label>
        <label className="flex items-center gap-2 text-xs font-semibold text-slate-500">
          <input type="checkbox" checked={f.isQuickTip} onChange={(e) => set("isQuickTip", e.target.checked)} />
          Quick Tip — appears in the ⚡ Quick Tips row (best for very short clips)
        </label>
      </div>

      <TopicEditor
        label="Detail screen chips (e.g. Natural Remedy, 5 Days Result)"
        addLabel="Add Chip"
        topics={f.chips}
        onChange={(chips) => set("chips", chips)}
      />
      <SectionsEditor variant="short" sections={f.sections} onChange={(sections) => set("sections", sections)} />
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


// ─── Page ──────────────────────────────────────────────────────────────────────

/**
 * Which form, if any, is open. `item: null` means create.
 *
 * Declared outside the component so the create mutations below can close the
 * form without depending on declaration order inside it.
 */
type Editing =
  | { kind: "category"; item: GlowCategory | null }
  | { kind: "read"; item: BeautyPost | null }
  | { kind: "short"; item: GlowShort | null }
  | null;

export default function GlowContentPage() {
  const [editing, setEditing] = useState<Editing>(null);
  const close = () => setEditing(null);
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
      setEditing(null);
      toast.success("Read created");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to create read")),
  });

  const createCategory = useMutation({
    mutationFn: (f: CategoryForm) => glowContentService.createCategory(glowCategoryFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-categories"] });
      setEditing(null);
      toast.success("Category created");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to create category")),
  });

  const createShort = useMutation({
    mutationFn: (f: ShortForm) => glowContentService.createShort(shortFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-shorts"] });
      setEditing(null);
      toast.success("Short created");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to create short")),
  });

  const updateCategory = useMutation({
    mutationFn: (f: CategoryForm) =>
      glowContentService.updateCategory(
        (editing?.item as GlowCategory).id,
        glowCategoryFormToPayload(f),
      ),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-categories"] });
      close();
      toast.success("Category updated");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to update category")),
  });

  const updateRead = useMutation({
    mutationFn: (f: ReadForm) =>
      glowContentService.updateRead((editing?.item as BeautyPost).id, readFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-reads"] });
      close();
      toast.success("Read updated");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to update read")),
  });

  const updateShort = useMutation({
    mutationFn: (f: ShortForm) =>
      glowContentService.updateShort((editing?.item as GlowShort).id, shortFormToPayload(f)),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ["glow-shorts"] });
      close();
      toast.success("Short updated");
    },
    onError: (err) => toast.error(apiMessage(err, "Failed to update short")),
  });

  const categoryCols = useMemo<ColumnDef<GlowCategory>[]>(
    () => [
      {
        id: "title",
        accessorKey: "title",
        header: "Category",
        enableHiding: false,
        cell: ({ row }) => (
          <div className="flex min-w-0 items-center gap-3">
            <div
              className="grid h-9 w-9 shrink-0 place-items-center rounded-full text-lg"
              style={{ backgroundColor: row.original.background }}
            >
              {row.original.emoji}
            </div>
            <span className="truncate font-medium text-foreground">{row.original.title}</span>
          </div>
        ),
      },
      {
        id: "subtitle",
        accessorKey: "subtitle",
        header: "Subtitle",
        cell: ({ row }) => <span className="text-muted-foreground">{row.original.subtitle}</span>,
      },
      {
        id: "topics",
        header: "Topics",
        enableSorting: false,
        cell: ({ row }) =>
          row.original.topics?.length ? (
            <Badge variant="outline">{row.original.topics.length} topics</Badge>
          ) : (
            <span className="text-xs text-muted-foreground">&mdash;</span>
          ),
      },
      { id: "order", accessorKey: "order", header: "Order" },
      {
        id: "actions",
        header: "Actions",
        enableSorting: false,
        enableHiding: false,
        cell: ({ row }) => (
          <RowActions
            label="Category"
            name={row.original.title}
            onEdit={() => setEditing({ kind: "category", item: row.original })}
            onDelete={() => glowContentService.deleteCategory(row.original.id)}
            onDeleted={() => void qc.invalidateQueries({ queryKey: ["glow-categories"] })}
          />
        ),
      },
    ],
    [qc],
  );

  const readCols = useMemo<ColumnDef<BeautyPost>[]>(
    () => [
      {
        id: "title",
        accessorKey: "title",
        header: "Read",
        enableHiding: false,
        cell: ({ row }) => (
          <div className="flex min-w-0 items-center gap-3">
            {row.original.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={row.original.imageUrl}
                alt=""
                className="h-9 w-9 shrink-0 rounded-lg object-cover"
              />
            ) : (
              <div className="h-9 w-9 shrink-0 rounded-lg bg-muted" />
            )}
            <span className="truncate font-medium text-foreground">{row.original.title}</span>
          </div>
        ),
      },
      {
        id: "tag",
        accessorKey: "tag",
        header: "Tag",
        cell: ({ row }) => (
          <span
            className="rounded-full px-2.5 py-0.5 text-xs font-semibold"
            style={{
              backgroundColor: row.original.tagBackground,
              color: row.original.tagColor,
            }}
          >
            {row.original.tag}
          </span>
        ),
      },
      {
        id: "minutesRead",
        accessorKey: "minutesRead",
        header: "Read time",
        cell: ({ row }) => `${row.original.minutesRead} min`,
      },
      {
        id: "flags",
        header: "Flags",
        enableSorting: false,
        cell: ({ row }) => (
          <div className="flex flex-wrap gap-1">
            <ContentBadges isPremium={row.original.isPremium} sections={row.original.sections} />
          </div>
        ),
      },
      {
        id: "actions",
        header: "Actions",
        enableSorting: false,
        enableHiding: false,
        cell: ({ row }) => (
          <RowActions
            label="Read"
            name={row.original.title}
            onEdit={() => setEditing({ kind: "read", item: row.original })}
            onDelete={() => glowContentService.deleteRead(row.original.id)}
            onDeleted={() => void qc.invalidateQueries({ queryKey: ["glow-reads"] })}
          />
        ),
      },
    ],
    [qc],
  );

  const shortCols = useMemo<ColumnDef<GlowShort>[]>(
    () => [
      {
        id: "title",
        accessorKey: "title",
        header: "Short",
        enableHiding: false,
        cell: ({ row }) => (
          <div className="flex min-w-0 items-center gap-3">
            {row.original.imageUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={row.original.imageUrl}
                alt=""
                className="h-9 w-9 shrink-0 rounded-lg object-cover"
              />
            ) : (
              <div className="h-9 w-9 shrink-0 rounded-lg bg-muted" />
            )}
            <span className="truncate font-medium text-foreground">{row.original.title}</span>
          </div>
        ),
      },
      {
        id: "duration",
        accessorKey: "duration",
        header: "Duration",
        cell: ({ row }) => <Badge>{row.original.duration}</Badge>,
      },
      {
        id: "views",
        accessorKey: "views",
        header: "Views",
        cell: ({ row }) => <span className="text-muted-foreground">{row.original.views}</span>,
      },
      {
        id: "placement",
        header: "Placement",
        enableSorting: false,
        cell: ({ row }) => (
          <div className="flex flex-wrap gap-1">
            {row.original.isFeatured && <Badge variant="primary">Featured</Badge>}
            {row.original.isTrending && <Badge variant="warning">Trending</Badge>}
            {row.original.isQuickTip && <Badge variant="info">Quick Tip</Badge>}
            <ContentBadges isPremium={row.original.isPremium} sections={row.original.sections} />
          </div>
        ),
      },
      {
        id: "actions",
        header: "Actions",
        enableSorting: false,
        enableHiding: false,
        cell: ({ row }) => (
          <RowActions
            label="Short"
            name={row.original.title}
            onEdit={() => setEditing({ kind: "short", item: row.original })}
            onDelete={() => glowContentService.deleteShort(row.original.id)}
            onDeleted={() => void qc.invalidateQueries({ queryKey: ["glow-shorts"] })}
          />
        ),
      },
    ],
    [qc],
  );

  const featuredCount = shorts.filter((s) => s.isFeatured).length;

  const SECTION_LABEL: Record<string, string> = {
    category: "category",
    read: "read",
    short: "short",
  };

  // ── Form view: replaces the table in place, with a trail back to the list ──
  if (editing) {
    const isNew = editing.item === null;
    return (
      <div className="space-y-4">
        <PageHeader
          title={`${isNew ? "New" : "Edit"} ${SECTION_LABEL[editing.kind]}`}
          description="Changes are saved to the live app."
        />

        <nav aria-label="Breadcrumb" className="flex items-center gap-1.5 text-sm">
          <button onClick={close} className="text-muted-foreground hover:text-foreground">
            Glow Content
          </button>
          <ChevronRight className="h-3.5 w-3.5 text-muted-foreground" />
          <span className="font-semibold text-foreground">
            {isNew ? "New" : "Edit"} {SECTION_LABEL[editing.kind]}
          </span>
        </nav>

        <Card>
          {editing.kind === "category" && (
            <GlowCategoryFormPanel
              initial={editing.item ? glowCategoryToForm(editing.item) : emptyGlowCategory()}
              onSave={(f) => (editing.item ? updateCategory.mutate(f) : createCategory.mutate(f))}
              onCancel={close}
              loading={updateCategory.isPending || createCategory.isPending}
            />
          )}
          {editing.kind === "read" && (
            <ReadFormPanel
              initial={editing.item ? readToForm(editing.item) : emptyRead()}
              categories={categories}
              onSave={(f) => (editing.item ? updateRead.mutate(f) : createRead.mutate(f))}
              onCancel={close}
              loading={updateRead.isPending || createRead.isPending}
            />
          )}
          {editing.kind === "short" && (
            <ShortFormPanel
              initial={editing.item ? shortToForm(editing.item) : emptyShort()}
              categories={categories}
              onSave={(f) => (editing.item ? updateShort.mutate(f) : createShort.mutate(f))}
              onCancel={close}
              loading={updateShort.isPending || createShort.isPending}
            />
          )}
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <PageHeader
        title="Glow Content"
        description="Everything shown on the app's Glow screen: category tiles, articles, and short videos."
      />

      {/* Tabs rather than three stacked tables: these are sibling content types,
          not a hierarchy, and stacking three full tables buries the last one. */}
      <Tabs defaultValue="categories">
        <TabsList>
          <TabsTrigger value="categories">Explore by Goals</TabsTrigger>
          <TabsTrigger value="reads">Glow Reads</TabsTrigger>
          <TabsTrigger value="shorts">Shorts &amp; Quick Tips</TabsTrigger>
        </TabsList>

        <TabsContent value="categories" className="space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <p className="text-xs text-muted-foreground">
              The row of round category tiles near the top of the Glow screen.
            </p>
            <Button onClick={() => setEditing({ kind: "category", item: null })}>
              + New category
            </Button>
          </div>
          {categoriesLoading ? (
            <TableSkeleton rows={5} />
          ) : (
            <DataTable
              columns={categoryCols}
              data={categories}
              manualSorting={false}
              getRowId={(r) => r.id}
              minWidth={720}
              emptyState={
                <EmptyState
                  title="No categories yet"
                  description="The app shows its built-in defaults until you add some."
                  action={
                    <Button size="sm" onClick={() => setEditing({ kind: "category", item: null })}>
                      + New category
                    </Button>
                  }
                />
              }
            />
          )}
        </TabsContent>

        <TabsContent value="reads" className="space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <p className="text-xs text-muted-foreground">
              Article cards in the Glow Reads row, and everything on its View All hub.
            </p>
            <Button onClick={() => setEditing({ kind: "read", item: null })}>+ New read</Button>
          </div>
          {readsLoading ? (
            <TableSkeleton rows={5} />
          ) : (
            <DataTable
              columns={readCols}
              data={reads}
              manualSorting={false}
              getRowId={(r) => r.id}
              minWidth={820}
              emptyState={
                <EmptyState
                  title="No reads yet"
                  description="The app shows placeholder cards until you add some."
                  action={
                    <Button size="sm" onClick={() => setEditing({ kind: "read", item: null })}>
                      + New read
                    </Button>
                  }
                />
              }
            />
          )}
        </TabsContent>

        <TabsContent value="shorts" className="space-y-3">
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div className="min-w-0">
              <p className="text-xs text-muted-foreground">
                Short video tiles on the Glow screen, and everything on the View All hub. Use each
                short&apos;s <strong>Placement</strong> checkboxes to control the hub&apos;s
                Featured card, Trending row and Quick Tips row.
              </p>
              {featuredCount > 1 && (
                <p className="mt-1 text-xs font-semibold text-warning">
                  {featuredCount} shorts are marked Featured &mdash; the app shows only the first,
                  so the others will not appear as the hero card.
                </p>
              )}
            </div>
            <Button onClick={() => setEditing({ kind: "short", item: null })}>+ New short</Button>
          </div>
          {shortsLoading ? (
            <TableSkeleton rows={5} />
          ) : (
            <DataTable
              columns={shortCols}
              data={shorts}
              manualSorting={false}
              getRowId={(r) => r.id}
              minWidth={860}
              emptyState={
                <EmptyState
                  title="No shorts yet"
                  description="The app shows placeholder tiles until you add some."
                  action={
                    <Button size="sm" onClick={() => setEditing({ kind: "short", item: null })}>
                      + New short
                    </Button>
                  }
                />
              }
            />
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
