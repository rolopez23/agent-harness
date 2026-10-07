import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Scope Turbopack to frontend/ so it doesn't pick up the repo root.
  turbopack: { root: __dirname },
};

export default nextConfig;
