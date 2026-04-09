"use client";

import type { PropsWithChildren } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { Button } from "@/components/ui/button";

type Props = PropsWithChildren<{
  open: boolean;
  title: string;
  onClose: () => void;
  onConfirm?: () => void;
  confirmLabel?: string;
}>;

export function ConfirmModal({
  open,
  title,
  onClose,
  onConfirm,
  confirmLabel = "Confirm",
  children,
}: Props) {
  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/35 p-4"
        >
          <motion.div
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 20, opacity: 0 }}
            className="glass-strong w-full max-w-md rounded-2xl p-5"
          >
            <h3 className="text-lg font-semibold">{title}</h3>
            <div className="mt-2 text-sm text-slate-600 dark:text-slate-300">{children}</div>
            <div className="mt-4 flex justify-end gap-2">
              <Button variant="ghost" onClick={onClose}>
                Cancel
              </Button>
              {onConfirm && <Button onClick={onConfirm}>{confirmLabel}</Button>}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
