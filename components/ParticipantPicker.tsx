"use client";
/**
 * ParticipantPicker
 * - Searchable contact selector used on the New Bill page.
 * - Filters contacts client-side by name and renders a scrollable list of chips.
 * - Clicking a chip toggles selection and visually marks the chip.
 */
import { useEffect, useMemo, useState } from "react";

type Contact = { id: string; name: string } & Partial<{ venmo: string; cashapp: string }>;

export default function ParticipantPicker({
  selectedIds,
  onToggle,
}: {
  selectedIds: string[];
  onToggle: (contactId: string) => void;
}) {
  const [contacts, setContacts] = useState<Contact[]>([]);
  const [query, setQuery] = useState("");

  useEffect(() => {
    fetch("/api/contacts").then((r) => r.json()).then((data) => {
      setContacts(data);
    });
  }, []);

  const filtered = useMemo(() => {
    const q = query.toLowerCase();
    return contacts.filter((c) => c.name.toLowerCase().includes(q));
  }, [contacts, query]);

  return (
    <div className="flex flex-col gap-2">
      <input
        className="input w-full max-w-sm"
        placeholder="Search contacts..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />
      <div className="flex flex-wrap gap-2 max-h-40 overflow-auto border rounded p-2">
        {filtered.map((c) => {
          const sel = selectedIds.includes(c.id);
          return (
            <button
              key={c.id}
              type="button"
              className={`chip ${sel ? "chip-selected" : ""}`}
              onClick={() => onToggle(c.id)}
            >
              {sel ? "✓ " : "+ "}{c.name}
            </button>
          );
        })}
      </div>
    </div>
  );
}


