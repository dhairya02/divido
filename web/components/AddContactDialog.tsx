"use client";
import { useEffect, useState } from "react";
import Modal from "@/components/Modal";
import { useSession } from "next-auth/react";

type Props = {
  open: boolean;
  onClose: () => void;
  onAdded: () => Promise<void> | void;
};

export default function AddContactDialog({ open, onClose, onAdded }: Props) {
  const { data: session } = useSession();
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [venmo, setVenmo] = useState("");
  const [cashapp, setCashapp] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [guestContacts, setGuestContacts] = useState<any[]>([]);

  const reset = () => {
    setFirstName("");
    setLastName("");
    setEmail("");
    setPhone("");
    setVenmo("");
    setCashapp("");
  };

  const submit = async () => {
    setSubmitting(true);
    setErrorMsg(null);
    try {
      const fullName = `${firstName} ${lastName}`.trim();
      if (session) {
        const res = await fetch("/api/contacts", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ name: fullName, email, phone, venmo, cashapp }),
        });
        const data = await res.json().catch(() => ({}));
        if (!res.ok) throw new Error(data?.error || "Failed to add contact");
        reset();
        await onAdded();
        onClose();
      } else {
        // guest mode: store locally in memory and sessionStorage
        const next = [...guestContacts, { id: crypto.randomUUID(), name: fullName, email, phone, venmo, cashapp }];
        setGuestContacts(next);
        sessionStorage.setItem("guestContacts", JSON.stringify(next));
        reset();
        onClose();
      }
    } catch (err) {
      setErrorMsg(err instanceof Error ? err.message : "Something went wrong");
    } finally {
      setSubmitting(false);
    }
  };

  useEffect(() => {
    if (!session) {
      const raw = sessionStorage.getItem("guestContacts");
      setGuestContacts(raw ? JSON.parse(raw) : []);
    }
  }, [session]);

  return (
    <Modal
      open={open}
      onClose={onClose}
      title="New contact"
      actions={
        <>
          <button className="btn" onClick={onClose}>Cancel</button>
          <button className="btn-primary" onClick={submit} disabled={submitting}>
            {submitting ? "Adding..." : "Add"}
          </button>
        </>
      }
    >
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <input className="input" placeholder="First name" value={firstName} onChange={(e) => setFirstName(e.target.value)} />
        <input className="input" placeholder="Last name" value={lastName} onChange={(e) => setLastName(e.target.value)} />
        <input className="input sm:col-span-2" placeholder="Email (optional)" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input className="input sm:col-span-2" placeholder="Phone (optional)" value={phone} onChange={(e) => setPhone(e.target.value)} />
        <input className="input" placeholder="Venmo (optional)" value={venmo} onChange={(e) => setVenmo(e.target.value)} />
        <input className="input" placeholder="Cash App (optional)" value={cashapp} onChange={(e) => setCashapp(e.target.value)} />
        {errorMsg && <div className="text-red-600 text-sm sm:col-span-2">{errorMsg}</div>}
        {!session && <div className="text-xs text-gray-500 sm:col-span-2">Guest contact (not saved to server).</div>}
      </div>
    </Modal>
  );
}


