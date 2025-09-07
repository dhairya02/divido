"use client";
import { useRef, useState } from "react";
import Tesseract from "tesseract.js";

type ParsedItem = { name: string; price: number };

export default function ReceiptOCR({ onItems }: { onItems: (items: ParsedItem[]) => Promise<void> | void }) {
  const inputRef = useRef<HTMLInputElement | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const parseTextToItems = (text: string): ParsedItem[] => {
    const items: ParsedItem[] = [];
    const lines = text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean);
    // Heuristic: match lines like "Item name .... $12.34" or "$12.34 Item name"
    // Supports thousands separators and optional leading currency symbol
    const money = /(?:\$\s*)?(-?\d{1,3}(?:,\d{3})*(?:\.\d{2})|-?\d+\.\d{2})/;
    for (const line of lines) {
      const upper = line.toUpperCase();
      if (/(TOTAL|SUBTOTAL|TAX|TIP|BALANCE|CHANGE)/.test(upper)) continue;
      const m = line.match(money);
      if (!m) continue;
      const raw = m[1].replace(/[,$\s]/g, "");
      const price = parseFloat(raw);
      if (!isFinite(price)) continue;
      // Name is line without the price token
      const name = line
        .replace(m[0], "")
        .replace(/[^A-Za-z0-9\s\-]/g, " ")
        .replace(/\s+/g, " ")
        .trim();
      if (!name) continue;
      items.push({ name, price });
    }
    return items;
  };

  async function blobToCanvas(blob: Blob): Promise<HTMLCanvasElement> {
    let bitmap: ImageBitmap | HTMLImageElement;
    if (typeof createImageBitmap === "function") {
      bitmap = await createImageBitmap(blob);
    } else {
      // Fallback for environments without createImageBitmap
      const dataUrl = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onerror = () => reject(new Error("Failed to read image"));
        reader.onload = () => resolve(String(reader.result));
        reader.readAsDataURL(blob);
      });
      bitmap = await new Promise<HTMLImageElement>((resolve, reject) => {
        const img = new Image();
        img.onload = () => resolve(img);
        img.onerror = () => reject(new Error("Failed to load image"));
        img.src = dataUrl;
      });
    }
    // Downscale very large images for speed
    const maxDim = 2000;
    const bmpWidth = (bitmap as any).width as number;
    const bmpHeight = (bitmap as any).height as number;
    const scale = Math.min(1, maxDim / Math.max(bmpWidth, bmpHeight));
    const width = Math.max(1, Math.round(bmpWidth * scale));
    const height = Math.max(1, Math.round(bmpHeight * scale));
    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    if (!ctx) throw new Error("Canvas not supported");
    ctx.drawImage(bitmap as any, 0, 0, width, height);
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
        try {
          // Dynamically import to avoid SSR window reference
          const mod = await import("heic2any");
          const heic2any = mod.default as (opts: { blob: Blob; toType: string; quality?: number }) => Promise<Blob>;
          source = (await heic2any({ blob: file, toType: "image/jpeg", quality: 0.92 })) as Blob;
        } catch (convErr: unknown) {
          const msg = convErr instanceof Error ? convErr.message : String(convErr);
          // Known message from libheif when a particular HEIC variant is unsupported
          if (/ERR_LIBHEIF/i.test(msg)) {
            setError(
              "This HEIC photo variant isn’t supported. Please take a new photo with the camera (JPEG) or screenshot the receipt to create a PNG/JPG, then try again. On iOS: Settings → Camera → Formats → Most Compatible."
            );
            setIsProcessing(false);
            return;
          }
          throw convErr;
        }
      }
      const canvas = await blobToCanvas(source);
      const dataUrl = canvas.toDataURL("image/png");
      async function recognizeWith(opts: { worker: string; core: string; langBase: string }) {
        const { data } = await Tesseract.recognize(dataUrl, "eng", {
          logger: () => {},
          // @ts-ignore: tesseract.js runtime options
          workerPath: opts.worker,
          // @ts-ignore: tesseract.js runtime options
          corePath: opts.core,
          // @ts-ignore: tesseract.js runtime options
          langPath: opts.langBase,
          // @ts-ignore - pass through config to worker
          tessedit_char_whitelist: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz$.-, \n",
        } as any);
        return data;
      }

      let data;
      try {
        // Known-good versions from upstream docs
        data = await recognizeWith({
          worker: "https://cdn.jsdelivr.net/npm/tesseract.js@6.0.1/dist/worker.min.js",
          core: "https://cdn.jsdelivr.net/npm/tesseract.js-core@4.0.2/tesseract-core.wasm.js",
          langBase: "https://tessdata.projectnaptha.com/4.0.0",
        });
      } catch (err) {
        const m = err instanceof Error ? err.message : String(err);
        if (/importScripts|failed to load|core\.wasm/i.test(m)) {
          // Retry with alternate CDN
          data = await recognizeWith({
            worker: "https://unpkg.com/tesseract.js@6.0.1/dist/worker.min.js",
            core: "https://unpkg.com/tesseract.js-core@4.0.2/tesseract-core.wasm.js",
            langBase: "https://tessdata.projectnaptha.com/4.0.0",
          });
        } else {
          throw err;
        }
      }
      const parsed = parseTextToItems(data.text);
      if (parsed.length === 0) {
        setError("No line items detected. Try a clearer photo (flat, well lit).");
      } else {
        await onItems(parsed);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : typeof e === "string" ? e : (() => { try { return JSON.stringify(e); } catch { return String(e); } })();
      setError(`OCR failed: ${msg}`);
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
        capture="environment"
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


