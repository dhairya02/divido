"use client";
import { useRef, useState } from "react";
import Tesseract from "tesseract.js";

type ParsedItem = { name: string; price: number };

export default function ReceiptOCR({ onItems }: { onItems: (items: ParsedItem[]) => void }) {
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const parseTextToItems = (text: string): ParsedItem[] => {
    const items: ParsedItem[] = [];
    const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
    // Heuristic: match lines like "Item name .... 12.34" or "12.34 Item name"
    const money = /(-?\d+[\.,]\d{2})/;
    for (const line of lines) {
      const upper = line.toUpperCase();
      if (/(TOTAL|SUBTOTAL|TAX|TIP|BALANCE|CHANGE)/.test(upper)) continue;
      const m = line.match(money);
      if (!m) continue;
      const raw = m[1].replace(",", ".");
      const price = parseFloat(raw);
      if (!isFinite(price)) continue;
      // Name is line without the price token
      const name = line.replace(m[1], "").replace(/[^A-Za-z0-9\s\-]/g, " ").replace(/\s+/g, " ").trim();
      if (!name) continue;
      items.push({ name, price });
    }
    return items;
  };

  async function blobToCanvas(blob: Blob): Promise<HTMLCanvasElement> {
    const bitmap = await createImageBitmap(blob);
    // Downscale very large images for speed
    const maxDim = 2000;
    const scale = Math.min(1, maxDim / Math.max(bitmap.width, bitmap.height));
    const width = Math.max(1, Math.round(bitmap.width * scale));
    const height = Math.max(1, Math.round(bitmap.height * scale));
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("Canvas not supported");
    ctx.drawImage(bitmap, 0, 0, width, height);
    return canvas;
  }

  const handleFile = async (file: File) => {
    setIsProcessing(true);
    setError(null);
    try {
      let source: Blob | File = file;
      const name = file.name?.toLowerCase?.() ?? "";
      const isHeic = file.type.includes("heic") || file.type.includes("heif") || name.endsWith(".heic") || name.endsWith(".heif");
      if (isHeic) {
        // Dynamically import to avoid SSR window reference
        const mod = await import("heic2any");
        const heic2any = mod.default as (opts: { blob: Blob; toType: string; quality?: number }) => Promise<Blob>;
        source = (await heic2any({ blob: file, toType: "image/jpeg", quality: 0.92 })) as Blob;
      }
      const canvas = await blobToCanvas(source);
      const { data } = await Tesseract.recognize(canvas, "eng", { logger: () => {} });
      const parsed = parseTextToItems(data.text);
      if (parsed.length === 0) {
        setError("No line items detected. Try a clearer photo (flat, well lit).");
      } else {
        onItems(parsed);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "OCR failed");
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="flex items-center gap-2">
      <input
        ref={inputRef}
        type="file"
        accept="image/*,.heic,.HEIC,.heif,.HEIF"
        className="hidden"
        onChange={(e) => {
          const f = e.target.files?.[0];
          if (f) void handleFile(f);
        }}
      />
      <button className="btn" type="button" onClick={() => inputRef.current?.click()} disabled={isProcessing}>
        {isProcessing ? "Scanning…" : "Upload receipt (OCR)"}
      </button>
      {error && <span className="text-xs text-red-500">{error}</span>}
    </div>
  );
}


