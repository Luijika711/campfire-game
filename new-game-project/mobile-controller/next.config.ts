import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'standalone',
  async redirects() {
    return [
      {
        source: '/',
        destination: '/qrcode?ip=localhost&port=8080&nextPort=3000',
        permanent: false,
      },
    ];
  },
};

export default nextConfig;
