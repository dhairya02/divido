"use client";
import { useEffect } from "react";
import { createPortal } from "react-dom";

export default function Modal({
  open,
  title,
  children,
  onClose,
  actions,
}: {
  open: boolean;
  title?: string;
  children?: React.ReactNode;
  onClose: () => void;
  actions?: React.ReactNode;
}) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;
  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="absolute inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white dark:bg-neutral-900 rounded-xl shadow-xl w-full max-w-md mx-4 border border-black/10 dark:border-white/15">
        {title ? (
          <div className="px-5 py-4 border-b border-black/10 dark:border-white/15 text-lg font-semibold">
            {title}
          </div>
        ) : null}
        <div className="px-5 py-4 text-sm">{children}</div>
        <div className="px-5 py-3 flex justify-end gap-2 border-t border-black/10 dark:border-white/15">
          {actions}
        </div>
      </div>
    </div>,
    document.body
  );
}


