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
        style={{ backgroundColor: "#ffffff", color: "#1f2937" }}
        onClick={() => router.back()}
        title="Back"
      >
        <span aria-hidden style={{ fontSize: "1rem", lineHeight: 1 }}>←</span>
      </button>
      <button
        type="button"
        aria-label="Forward"
        className="btn"
        style={{ backgroundColor: "#ffffff", color: "#1f2937" }}
        onClick={() => router.forward?.()}
        title="Forward"
      >
        <span aria-hidden style={{ fontSize: "1rem", lineHeight: 1 }}>→</span>
      </button>
    </div>
  );
}


