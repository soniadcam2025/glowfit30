"use client";

import type { PropsWithChildren } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

type Props = PropsWithChildren<{
  open: boolean;
  title: string;
  onClose: () => void;
  onConfirm?: () => void;
  confirmLabel?: string;
  /** Destructive actions get a red confirm button. Defaults true because every
   *  current call site is a delete confirmation. */
  destructive?: boolean;
}>;

/**
 * Same props as before, so no call site changed — but now built on the Radix
 * Dialog, which brings focus trapping, focus restore, Escape-to-close and
 * background inerting. The previous hand-rolled overlay had none of those, and
 * styled its panel with a `glass-strong` class that was never defined anywhere,
 * so the modal rendered without a background.
 */
export function ConfirmModal({
  open,
  title,
  onClose,
  onConfirm,
  confirmLabel = "Confirm",
  destructive = true,
  children,
}: Props) {
  return (
    <Dialog open={open} onOpenChange={(next) => !next && onClose()}>
      <DialogContent className="max-w-md">
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          {children && (
            <DialogDescription asChild>
              <div>{children}</div>
            </DialogDescription>
          )}
        </DialogHeader>
        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>
            Cancel
          </Button>
          {onConfirm && (
            <Button variant={destructive ? "danger" : "default"} onClick={onConfirm}>
              {confirmLabel}
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
