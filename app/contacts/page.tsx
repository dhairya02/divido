"use client";
import { useEffect, useMemo, useState } from "react";
import AddContactDialog from "@/components/AddContactDialog";

type Contact = {
  id: string;
  name: string;
  email?: string;
  phone?: string;
  venmo?: string;
  cashapp?: string;
};

export default function ContactsPage() {
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [form, setForm] = useState<Partial<Contact>>({ name: "" });
  const [dialogOpen, setDialogOpen] = useState(false);
  const [sortBy, setSortBy] = useState<"first" | "last">("first");

  const load = async () => {
    const res = await fetch("/api/contacts");
    setContacts(await res.json());
  };

  useEffect(() => {
    load();
  }, []);

  const submit = async (e: React.FormEvent) => { e.preventDefault(); setDialogOpen(true); };

  const sorted = useMemo(() => {
    const list = [...contacts];
    return list.sort((a, b) => {
      const [af, al] = a.name.split(" ");
      const [bf, bl] = b.name.split(" ");
      const aKey = (sortBy === "first" ? af : (al ?? af))?.toLowerCase() ?? "";
      const bKey = (sortBy === "first" ? bf : (bl ?? bf))?.toLowerCase() ?? "";
      return aKey.localeCompare(bKey);
    });
  }, [contacts, sortBy]);

  return (
    <div className="max-w-3xl mx-auto p-6 space-y-6">
      <h1 className="text-2xl font-semibold">Contacts</h1>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <label className="flex items-center gap-2 text-sm">
            <input type="radio" name="sort" checked={sortBy === "first"} onChange={() => setSortBy("first")} /> Sort by first name
          </label>
          <label className="flex items-center gap-2 text-sm">
            <input type="radio" name="sort" checked={sortBy === "last"} onChange={() => setSortBy("last")} /> Sort by last name
          </label>
        </div>
        <button className="btn-primary" onClick={() => setDialogOpen(true)}>+ New contact</button>
      </div>

      <div className="divide-y border rounded">
        {sorted.map((c) => (
          <details key={c.id} className="group">
            <summary className="flex items-center justify-between px-4 py-3 cursor-pointer select-none">
              <span className="font-medium">{c.name}</span>
              <span className="text-xs text-gray-500 group-open:hidden">Tap to view</span>
              <span className="text-xs text-gray-500 hidden group-open:inline">Hide</span>
            </summary>
            <div className="px-4 pb-3 grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
              {c.email && <div><span className="text-gray-500">Email:</span> {c.email}</div>}
              {c.phone && <div><span className="text-gray-500">Phone:</span> {c.phone}</div>}
              {c.venmo && <div><span className="text-gray-500">Venmo:</span> {c.venmo}</div>}
              {c.cashapp && <div><span className="text-gray-500">Cash App:</span> {c.cashapp}</div>}
            </div>
          </details>
        ))}
      </div>

      <AddContactDialog open={dialogOpen} onClose={() => setDialogOpen(false)} onAdded={load} />
    </div>
  );
}


