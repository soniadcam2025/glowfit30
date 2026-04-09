"use client";

import { LottieAppLoader } from "@/components/loading/lottie-app-loader";

type Props = {
  label?: string;
};

/** Full-viewport overlay with Lottie — use during auth, route transitions (also see `loading.tsx`). */
export function FullPageLoader({ label }: Props) {
  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center bg-white/90 backdrop-blur-sm dark:bg-zinc-950/90">
      <LottieAppLoader label={label} />
    </div>
  );
}
