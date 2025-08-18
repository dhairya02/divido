"use client";
import { useEffect, useState } from "react";

type Contact = { id: string; name: string } & Partial<{ venmo: string; cashapp: string }>;

export default function ParticipantPicker({
  selectedIds,
  onToggle,
}: {
  selectedIds: string[];
  onToggle: (contactId: string) => void;
}) {
  const [contacts, setContacts] = useState<Contact[]>([]);

  useEffect(() => {
    fetch("/api/contacts").then((r) => r.json()).then((data) => {
      setContacts(data);
    });
  }, []);

  return (
    <div className="flex flex-wrap gap-2">
      {contacts.map((c) => {
        const sel = selectedIds.includes(c.id);
        return (
          <button
            key={c.id}
            type="button"
            className={`chip ${sel ? "chip-selected" : ""}`}
            onClick={() => onToggle(c.id)}
          >
            {c.name}
          </button>
        );
      })}
    </div>
  );
}


