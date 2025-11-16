"use client";
import { useEffect, useState } from "react";

type Stats = { bills: number; contacts: number; name?: string; email?: string };

export default function AccountMenu() {
  const [open, setOpen] = useState(false);
  const [stats, setStats] = useState<Stats | null>(null);

  useEffect(() => {
    fetch("/api/me/stats").then((r) => r.json()).then((d) => setStats(d)).catch(() => {});
  }, []);

  return (
    <div className="relative">
      <button
        type="button"
        className="inline-flex items-center justify-center h-8 w-8 rounded-full border border-black/10 bg-white text-black"
        onClick={() => setOpen((v) => !v)}
        aria-label="Account"
      >
        {(stats?.name?.[0] || "U").toUpperCase()}
      </button>
      {open && (
        <div className="absolute right-0 mt-2 w-64 rounded border bg-white text-black shadow z-50">
          <div className="px-4 py-3 border-b">
            <div className="font-semibold">{stats?.name || "Account"}</div>
            <div className="text-xs text-gray-600">{stats?.email}</div>
          </div>
          <div className="px-4 py-3 text-sm space-y-1">
            <div>Bills: <strong>{stats?.bills ?? 0}</strong></div>
            <div>Contacts: <strong>{stats?.contacts ?? 0}</strong></div>
          </div>
          <div className="px-4 py-3 border-t text-sm flex gap-2">
            <a className="btn" href="/account">Account</a>
            <a className="btn" href="/api/auth/signout">Logout</a>
          </div>
        </div>
      )}
    </div>
  );
}


