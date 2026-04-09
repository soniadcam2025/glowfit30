"use client";

import Lottie from "lottie-react";
import loaderAnimation from "@/assets/lottie/loader.json";

type Props = {
  className?: string;
  label?: string;
};

export function LottieAppLoader({ className, label = "Loading…" }: Props) {
  return (
    <div
      className={`flex flex-col items-center justify-center gap-3 ${className ?? ""}`}
      role="status"
      aria-live="polite"
      aria-busy="true"
    >
      <div className="h-40 w-40 md:h-48 md:w-48">
        <Lottie animationData={loaderAnimation} loop className="h-full w-full" />
      </div>
      {label ? <p className="text-sm text-slate-600 dark:text-slate-400">{label}</p> : null}
    </div>
  );
}
