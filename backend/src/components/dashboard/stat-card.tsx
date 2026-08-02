"use client";

import * as React from "react";
import { motion, useMotionValue, useSpring, useInView } from "framer-motion";
import type { LucideIcon } from "lucide-react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

/**
 * Counts to `value` once the element is in view.
 *
 * Falls back to the plain number when the user prefers reduced motion — an
 * animated counter is decoration, and decoration should not override that
 * preference.
 */
function AnimatedNumber({ value }: { value: number }) {
  const ref = React.useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: "-40px" });
  const motionValue = useMotionValue(0);
  const spring = useSpring(motionValue, { stiffness: 90, damping: 20 });
  const [display, setDisplay] = React.useState(0);

  const reduceMotion =
    typeof window !== "undefined" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  React.useEffect(() => {
    if (reduceMotion) {
      setDisplay(value);
      return;
    }
    if (inView) motionValue.set(value);
  }, [inView, value, motionValue, reduceMotion]);

  React.useEffect(() => {
    if (reduceMotion) return;
    return spring.on("change", (v) => setDisplay(Math.round(v)));
  }, [spring, reduceMotion]);

  return <span ref={ref}>{display.toLocaleString()}</span>;
}

export type StatCardProps = {
  label: string;
  value: number | string;
  sub?: string;
  icon?: LucideIcon;
  tone?: "default" | "primary" | "success" | "warning" | "danger";
  index?: number;
};

const TONE: Record<NonNullable<StatCardProps["tone"]>, string> = {
  default: "text-foreground",
  primary: "text-primary",
  success: "text-success",
  warning: "text-warning",
  danger: "text-danger",
};

const ICON_BG: Record<NonNullable<StatCardProps["tone"]>, string> = {
  default: "bg-muted text-muted-foreground",
  primary: "bg-primary/10 text-primary",
  success: "bg-success/10 text-success",
  warning: "bg-warning/15 text-warning",
  danger: "bg-danger/10 text-danger",
};

export function StatCard({
  label,
  value,
  sub,
  icon: Icon,
  tone = "default",
  index = 0,
}: StatCardProps) {
  const numeric = typeof value === "number";

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25, delay: Math.min(index * 0.04, 0.2) }}
    >
      <Card className="group h-full transition-colors hover:border-primary/40">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="text-xs font-medium text-muted-foreground">{label}</p>
            <p className={cn("mt-1 text-2xl font-bold tracking-tight", TONE[tone])}>
              {numeric ? <AnimatedNumber value={value} /> : value}
            </p>
            {sub && <p className="mt-0.5 text-xs text-muted-foreground">{sub}</p>}
          </div>
          {Icon && (
            <div className={cn("grid h-9 w-9 shrink-0 place-items-center rounded-lg", ICON_BG[tone])}>
              <Icon className="h-4 w-4" />
            </div>
          )}
        </div>
      </Card>
    </motion.div>
  );
}
