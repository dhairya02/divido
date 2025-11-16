"use client";
import { useEffect, useState } from "react";
import Modal from "@/components/Modal";

type Contact = { id: string; name: string; email?: string; phone?: string; venmo?: string; cashapp?: string };

export default function EditContactDialog({ open, contact, onClose, onSaved }: { open: boolean; contact: Contact | null; onClose: () => void; onSaved: () => Promise<void> | void }) {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [venmo, setVenmo] = useState("");
  const [cashapp, setCashapp] = useState("");
  const [saving, setSaving] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    if (!contact) return;
    setName(contact.name || "");
    setEmail(contact.email || "");
    setPhone(contact.phone || "");
    setVenmo(contact.venmo || "");
    setCashapp(contact.cashapp || "");
  }, [contact]);

  const save = async () => {
    if (!contact) return;
    setSaving(true);
    setErrorMsg(null);
    try {
      const res = await fetch(`/api/contacts/${contact.id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name, email, phone, venmo, cashapp }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) throw new Error(data?.error || "Failed to save contact");
      await onSaved();
      onClose();
    } catch (err) {
      setErrorMsg(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="Edit contact"
      actions={
        <>
          <button className="btn" onClick={onClose}>Cancel</button>
          <button className="btn-primary" onClick={save} disabled={saving}>{saving ? "Saving..." : "Save"}</button>
        </>
      }
    >
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <input className="input sm:col-span-2" placeholder="Full name" value={name} onChange={(e) => setName(e.target.value)} />
        <input className="input sm:col-span-2" placeholder="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input className="input sm:col-span-2" placeholder="Phone" value={phone} onChange={(e) => setPhone(e.target.value)} />
        <input className="input" placeholder="Venmo" value={venmo} onChange={(e) => setVenmo(e.target.value)} />
        <input className="input" placeholder="Cash App" value={cashapp} onChange={(e) => setCashapp(e.target.value)} />
        {errorMsg && <div className="text-red-600 text-sm sm:col-span-2">{errorMsg}</div>}
      </div>
    </Modal>
  );
}


