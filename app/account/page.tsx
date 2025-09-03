"use client";
import { useEffect, useState } from "react";
import ConfirmDialog from "@/components/ConfirmDialog";

export default function AccountPage() {
  const [first, setFirst] = useState("");
  const [last, setLast] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [venmo, setVenmo] = useState("");
  const [cashapp, setCashapp] = useState("");
  const [cur, setCur] = useState("");
  const [next, setNext] = useState("");
  const [msg, setMsg] = useState<string | null>(null);
  const [confirmOpen, setConfirmOpen] = useState(false);

  useEffect(() => {
    // Load both user and self-contact details for harmonized fields
    Promise.all([
      fetch("/api/me/stats").then((r) => r.json()).catch(() => ({})),
      fetch("/api/me/contact").then((r) => r.json()).catch(() => null),
    ]).then(([stats, contact]) => {
      const fullName = (stats?.name || contact?.name || "").trim();
      const [f, ...rest] = fullName.split(" ");
      setFirst(f || "");
      setLast(rest.join(" ") || "");
      setEmail(stats?.email || contact?.email || "");
      setPhone(contact?.phone || "");
      setVenmo(contact?.venmo || "");
      setCashapp(contact?.cashapp || "");
    });
  }, []);

  const saveProfile = async () => {
    setMsg(null);
    const name = [first, last].filter(Boolean).join(" ");
    const res = await fetch("/api/me/profile", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name }) });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) { setMsg(data?.error || "Failed to update"); return; }
    // Persist contact fields too (email is immutable here)
    const cRes = await fetch("/api/me/contact", { method: "PATCH", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ name, phone, venmo, cashapp }) });
    const cData = await cRes.json().catch(() => ({}));
    setMsg(cRes.ok ? "Profile updated" : cData?.error || "Failed to update contact");
  };
  const changePassword = async () => {
    setMsg(null);
    const res = await fetch("/api/me/password", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ current: cur, next }) });
    const data = await res.json().catch(() => ({}));
    setMsg(res.ok ? "Password changed" : data?.error || "Failed to change password");
  };

  const deleteAccount = async () => {
    setMsg(null);
    const res = await fetch("/api/me", { method: "DELETE" });
    const data = await res.json().catch(() => ({}));
    if (res.ok) {
      // Redirect to signout which clears session cookies and returns home
      window.location.href = "/api/auth/signout";
    } else {
      setMsg(data?.error || "Failed to delete account");
    }
  };

  return (
    <div className="max-w-xl mx-auto p-6 space-y-6">
      <h1 className="text-2xl font-semibold">Account</h1>
      {msg && <div className="text-sm" style={{ color: msg.includes("Failed") ? "#dc2626" : "#065f46" }}>{msg}</div>}
      <section className="space-y-2">
        <h2 className="font-medium">Profile</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">First name</span>
            <input className="input" value={first} onChange={(e) => setFirst(e.target.value)} />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Last name</span>
            <input className="input" value={last} onChange={(e) => setLast(e.target.value)} />
          </label>
        </div>
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Email</span>
          <input className="input" value={email} disabled />
        </label>
        <label className="flex flex-col gap-1">
          <span className="text-sm text-gray-400">Phone</span>
          <input className="input" value={phone} onChange={(e) => setPhone(e.target.value)} />
        </label>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Venmo</span>
            <input className="input" value={venmo} onChange={(e) => setVenmo(e.target.value)} />
          </label>
          <label className="flex flex-col gap-1">
            <span className="text-sm text-gray-400">Cash App</span>
            <input className="input" value={cashapp} onChange={(e) => setCashapp(e.target.value)} />
          </label>
        </div>
        <button className="btn-primary" onClick={saveProfile}>Save profile</button>
      </section>
      <section className="space-y-2">
        <h2 className="font-medium">Change password</h2>
        <input className="input" type="password" placeholder="Current password" value={cur} onChange={(e) => setCur(e.target.value)} />
        <input className="input" type="password" placeholder="New password" value={next} onChange={(e) => setNext(e.target.value)} />
        <button className="btn" onClick={changePassword}>Change password</button>
      </section>

      <section className="space-y-2">
        <h2 className="font-medium">Danger zone</h2>
        <button className="btn" style={{ borderColor: "#dc2626", color: "#dc2626" }} onClick={() => setConfirmOpen(true)}>Delete account…</button>
      </section>

      <ConfirmDialog
        open={confirmOpen}
        title="Delete account"
        message="This will permanently delete your account, bills and contacts. This action cannot be undone."
        confirmText="Delete"
        cancelText="Cancel"
        onConfirm={deleteAccount}
        onCancel={() => setConfirmOpen(false)}
      />
    </div>
  );
}


