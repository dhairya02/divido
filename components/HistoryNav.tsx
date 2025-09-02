"use client";
import { useRouter } from "next/navigation";

export default function HistoryNav() {
  const router = useRouter();
  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        aria-label="Back"
        className="btn"
        onClick={() => router.back()}
        title="Back"
      >
        <span aria-hidden>←</span>
      </button>
      <button
        type="button"
        aria-label="Forward"
        className="btn"
        onClick={() => router.forward?.()}
        title="Forward"
      >
        <span aria-hidden>→</span>
      </button>
    </div>
  );
}


