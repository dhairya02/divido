"use client";
import { useState } from "react";

export default function Logo({ className }: { className?: string }) {
  const [src, setSrc] = useState<string>("/restaurantsplit-high-resolution-logo.png");
  return (
    <img
      src={src}
      onError={() => setSrc("/favicon.ico")}
      alt="Divido logo"
      className={className}
      aria-hidden
    />
  );
}


