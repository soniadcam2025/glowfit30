"use client";

import { useRef, useState } from "react";
import { toast } from "sonner";
import { uploadsService } from "@/services/uploads.service";

/** Reads duration from the file locally, before any upload happens, so an
 *  over-length clip is rejected without burning bandwidth or storage. */
function readDuration(file: File): Promise<number> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const v = document.createElement("video");
    v.preload = "metadata";
    v.onloadedmetadata = () => {
      URL.revokeObjectURL(url);
      resolve(v.duration);
    };
    v.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Could not read video metadata"));
    };
    v.src = url;
  });
}

export function VideoUploadField({
  label,
  value,
  onChange,
  maxSeconds,
}: {
  label: string;
  value?: string;
  onChange: (url: string) => void;
  /** Optional hard cap on clip length, enforced client-side before upload. */
  maxSeconds?: number;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);

  async function handleFile(file: File) {
    if (file.type !== "video/mp4") {
      toast.error("Only MP4 videos are allowed");
      return;
    }
    if (file.size > 100 * 1024 * 1024) {
      toast.error("Video must be 100MB or smaller");
      return;
    }
    if (maxSeconds) {
      try {
        const seconds = await readDuration(file);
        if (seconds > maxSeconds + 0.5) {
          toast.error(
            `Clip is ${Math.round(seconds)}s — must be ${maxSeconds}s or shorter`,
          );
          return;
        }
      } catch {
        toast.error("Could not read that video's length");
        return;
      }
    }

    setUploading(true);
    try {
      const url = await uploadsService.uploadVideo(file);
      onChange(url);
      toast.success("Video uploaded");
    } catch {
      toast.error("Video upload failed");
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="space-y-1">
      <label className="text-xs font-semibold text-slate-500">{label}</label>
      <div className="flex items-center gap-3">
        {value ? (
          <video
            src={value}
            className="h-12 w-12 shrink-0 rounded-lg border border-slate-200 object-cover dark:border-slate-700"
            muted
          />
        ) : (
          <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-lg border border-dashed border-slate-300 text-[10px] text-slate-400 dark:border-slate-600">
            No video
          </div>
        )}
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          disabled={uploading}
          className="rounded-xl border border-slate-300 bg-white px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-300"
        >
          {uploading ? "Uploading…" : value ? "Replace" : "Upload MP4"}
        </button>
        {value && (
          <button
            type="button"
            onClick={() => onChange("")}
            className="text-xs text-rose-400 hover:text-rose-600"
          >
            Remove
          </button>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="video/mp4"
        className="hidden"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) void handleFile(file);
          e.target.value = "";
        }}
      />
    </div>
  );
}
