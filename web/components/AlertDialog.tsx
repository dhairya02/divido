"use client";
import Modal from "./Modal";

export default function AlertDialog({
  open,
  title = "Notice",
  message,
  onClose,
  buttonText = "OK",
}: {
  open: boolean;
  title?: string;
  message?: string;
  onClose: () => void;
  buttonText?: string;
}) {
  return (
    <Modal
      open={open}
      title={title}
      onClose={onClose}
      actions={<button className="btn-primary" onClick={onClose}>{buttonText}</button>}
    >
      <div className="text-sm whitespace-pre-line">{message}</div>
    </Modal>
  );
}


