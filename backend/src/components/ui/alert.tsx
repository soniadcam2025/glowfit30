import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { AlertTriangle, CheckCircle2, Info, XCircle } from "lucide-react";
import { cn } from "@/lib/utils";

const alertVariants = cva("flex gap-3 rounded-lg border p-3 text-sm", {
  variants: {
    variant: {
      info: "border-info/30 bg-info/5 text-foreground",
      success: "border-success/30 bg-success/5 text-foreground",
      warning: "border-warning/40 bg-warning/5 text-foreground",
      danger: "border-danger/30 bg-danger/5 text-foreground",
    },
  },
  defaultVariants: { variant: "info" },
});

const ICONS = {
  info: Info,
  success: CheckCircle2,
  warning: AlertTriangle,
  danger: XCircle,
} as const;

const ICON_TONE = {
  info: "text-info",
  success: "text-success",
  warning: "text-warning",
  danger: "text-danger",
} as const;

export interface AlertProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof alertVariants> {
  title?: string;
}

export function Alert({ className, variant = "info", title, children, ...props }: AlertProps) {
  const key = variant ?? "info";
  const Icon = ICONS[key];
  return (
    <div
      // `status` rather than `alert` — these are informational panels, not
      // interruptions, so screen readers should not preempt the user.
      role="status"
      className={cn(alertVariants({ variant }), className)}
      {...props}
    >
      <Icon className={cn("mt-0.5 h-4 w-4 shrink-0", ICON_TONE[key])} />
      <div className="min-w-0">
        {title && <p className="font-semibold">{title}</p>}
        {children && <div className="text-muted-foreground">{children}</div>}
      </div>
    </div>
  );
}
