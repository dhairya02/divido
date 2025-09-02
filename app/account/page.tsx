"use client";
import { useEffect, useState } from "react";

export default function AccountPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [cur, setCur] = useState("");
  const [next, setNext] = useState("");
  const [msg, setMsg] = useState<string | null>(null);

  useEffect(() => {
    fetch("/api/me/stats").then((r) => r.json()).then((d) => { setName(d.name || ""); setEmail(d.email || ""); });
  }, []);

  const saveProfile = async () => {
    setMsg(null);
    const res = await fetch("/api/me/profile", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name }) });
    const data = await res.json().catch(() => ({}));
    setMsg(res.ok ? "Profile updated" : data?.error || "Failed to update");
  };
  const changePassword = async () => {
    setMsg(null);
    const res = await fetch("/api/me/password", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ current: cur, next }) });
    const data = await res.json().catch(() => ({}));
    setMsg(res.ok ? "Password changed" : data?.error || "Failed to change password");
  };

  return (
    <div className="max-w-xl mx-auto p-6 space-y-6">
      <h1 className="text-2xl font-semibold">Account</h1>
      {msg && <div className="text-sm" style={{ color: msg.includes("Failed") ? "#dc2626" : "#065f46" }}>{msg}</div>}
      <section className="space-y-2">
        <h2 className="font-medium">Profile</h2>
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Name</span>
          <input className="input" value={name} onChange={(e) => setName(e.target.value)} />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Email</span>
          <input className="input" value={email} disabled />
        </label>
        <button className="btn-primary" onClick={saveProfile}>Save profile</button>
      </section>
      <section className="space-y-2">
        <h2 className="font-medium">Change password</h2>
        <input className="input" type="password" placeholder="Current password" value={cur} onChange={(e) => setCur(e.target.value)} />
        <input className="input" type="password" placeholder="New password" value={next} onChange={(e) => setNext(e.target.value)} />
        <button className="btn" onClick={changePassword}>Change password</button>
      </section>
    </div>
  );
}


