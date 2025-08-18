"use client";
import { useRouter } from "next/navigation";

export default function HistoryNav() {
  const router = useRouter();
  return (
    <div className="flex items-center gap-2">
      <button
        type="button"
        aria-label="Fork"
        className="btn"
        onClick={() => router.back()}
        title="Back"
      >
        <span style={{ display: "inline-block", transform: "rotate(-90deg)" }}>🍴</span>
      </button>
      <button
        type="button"
        aria-label="Spoon"
        className="btn"
        onClick={() => router.forward?.()}
        title="Forward"
      >
        <span style={{ display: "inline-block", transform: "rotate(90deg)" }}>🥄</span>
      </button>
    </div>
  );
}


