"use client";
import Modal from "@/components/Modal";

export default function ContactDetailDialog({ open, contact, onClose }: { open: boolean; contact: any | null; onClose: () => void }) {
  return (
    <Modal
      open={open}
      onClose={onClose}
      title={contact?.name || "Contact"}
      actions={<button className="btn" onClick={onClose}>Close</button>}
    >
      {contact && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-sm">
          <div><span className="text-gray-500">Email:</span> {contact.email || "-"}</div>
          <div><span className="text-gray-500">Phone:</span> {contact.phone || "-"}</div>
          <div><span className="text-gray-500">Venmo:</span> {contact.venmo || "-"}</div>
          <div><span className="text-gray-500">Cash App:</span> {contact.cashapp || "-"}</div>
        </div>
      )}
    </Modal>
  );
}


