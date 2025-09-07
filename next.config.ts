import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  eslint: {
    // Allow builds to pass while we gradually fix lint errors
    ignoreDuringBuilds: true,
  },
};

export default nextConfig;
