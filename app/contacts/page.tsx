"use client";
import { useEffect, useMemo, useState } from "react";
import AddContactDialog from "@/components/AddContactDialog";
import EditContactDialog from "@/components/EditContactDialog";
import ConfirmDialog from "@/components/ConfirmDialog";
import ContactDetailDialog from "@/components/ContactDetailDialog";

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
  const [editOpen, setEditOpen] = useState(false);
  const [selectedContact, setSelectedContact] = useState<Contact | null>(null);
  const [deleteId, setDeleteId] = useState<string | null>(null);
  const [bulk, setBulk] = useState<Record<string, boolean>>({});
  const [detailOpen, setDetailOpen] = useState(false);

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
              <div className="flex items-center gap-3">
                <input type="checkbox" checked={!!bulk[c.id]} onChange={(e) => setBulk((b) => ({ ...b, [c.id]: e.target.checked }))} onClick={(e) => e.stopPropagation()} />
                <button className="font-medium hover:underline" onClick={(e) => { e.preventDefault(); e.stopPropagation(); setSelectedContact(c); setDetailOpen(true); }}> {c.name} </button>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  className="btn"
                  onClick={(e) => { e.preventDefault(); e.stopPropagation(); setSelectedContact(c); setEditOpen(true); }}
                >Edit</button>
                <button
                  type="button"
                  className="btn"
                  onClick={(e) => { e.preventDefault(); e.stopPropagation(); setDeleteId(c.id); }}
                >Delete</button>
              </div>
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
      <EditContactDialog open={editOpen} contact={selectedContact} onClose={() => setEditOpen(false)} onSaved={load} />
      <ContactDetailDialog open={detailOpen} contact={selectedContact} onClose={() => setDetailOpen(false)} />
      <ConfirmDialog
        open={deleteId !== null}
        title="Delete contact"
        message="This will remove the contact and any bill participations. Continue?"
        confirmText="Delete"
        cancelText="Cancel"
        onCancel={() => setDeleteId(null)}
        onConfirm={async () => {
          if (!deleteId) return;
          await fetch(`/api/contacts/${deleteId}`, { method: "DELETE" });
          setDeleteId(null);
          await load();
        }}
      />
      {Object.values(bulk).some(Boolean) && (
        <div className="fixed bottom-4 left-1/2 -translate-x-1/2 bg-white dark:bg-neutral-900 border rounded shadow px-4 py-2 flex items-center gap-3">
          <span className="text-sm">{Object.values(bulk).filter(Boolean).length} selected</span>
          <button
            className="btn"
            onClick={async () => {
              const ids = Object.entries(bulk).filter(([, v]) => v).map(([id]) => id);
              await fetch('/api/contacts/bulk-delete', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ids }) });
              setBulk({});
              await load();
            }}
          >Delete selected</button>
        </div>
      )}
    </div>
  );
}


