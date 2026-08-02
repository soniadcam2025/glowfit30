import * as React from "react";
import { cn } from "@/lib/utils";

export type InputProps = React.InputHTMLAttributes<HTMLInputElement>;

/**
 * Styling reacts to `aria-invalid`, so the RHF + Zod work in Phase 6 can mark a
 * field invalid without every form re-implementing error styling.
 */
export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type = "text", ...props }, ref) => (
    <input
      ref={ref}
      type={type}
      className={cn(
        "w-full rounded-lg border border-input bg-surface px-3 py-2 text-sm text-foreground",
        "placeholder:text-muted-foreground",
        "outline-none transition-colors focus-visible:border-ring",
        "disabled:cursor-not-allowed disabled:opacity-50",
        "aria-[invalid=true]:border-danger aria-[invalid=true]:focus-visible:border-danger",
        className,
      )}
      {...props}
    />
  ),
);

Input.displayName = "Input";

export const Textarea = React.forwardRef<
  HTMLTextAreaElement,
  React.TextareaHTMLAttributes<HTMLTextAreaElement>
>(({ className, rows = 3, ...props }, ref) => (
  <textarea
    ref={ref}
    rows={rows}
    className={cn(
      "w-full rounded-lg border border-input bg-surface px-3 py-2 text-sm text-foreground",
      "placeholder:text-muted-foreground",
      "outline-none transition-colors focus-visible:border-ring",
      "disabled:cursor-not-allowed disabled:opacity-50",
      "aria-[invalid=true]:border-danger",
      className,
    )}
    {...props}
  />
));

Textarea.displayName = "Textarea";

export const Label = React.forwardRef<
  HTMLLabelElement,
  React.LabelHTMLAttributes<HTMLLabelElement>
>(({ className, ...props }, ref) => (
  <label
    ref={ref}
    className={cn("text-xs font-semibold text-muted-foreground", className)}
    {...props}
  />
));

Label.displayName = "Label";
