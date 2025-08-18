"use client";
import { useState } from "react";

export default function Logo({ className }: { className?: string }) {
  const [src, setSrc] = useState<string>("/restaurantsplit-high-resolution-logo.png");
  const fallbacks = [
    "/brand-logo.svg",
    "/logo.svg",
    "/logo.png",
  ];
  return (
    <img
      src={src}
      onError={() => {
        const next = fallbacks.shift?.call(fallbacks);
        if (next) setSrc(next as string);
      }}
      alt="RestaurantSplit logo"
      className={className}
      aria-hidden
    />
  );
}


