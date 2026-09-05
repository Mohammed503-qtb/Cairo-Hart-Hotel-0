import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  typescript: {
    ignoreBuildErrors: true,
  },
  reactStrictMode: false,
  // صور محتوى الموقع المرفوعة: تُقدَّم ثابتة من public/uploads إن وُجدت،
  // وإلا يسقط الطلب لمسار /api/uploads/[name] الذي يقرأها من القرص —
  // ضمان خدمة الصور المرفوعة بعد التشغيل دون إعادة بناء.
  async rewrites() {
    return {
      beforeFiles: [],
      afterFiles: [{ source: "/uploads/:path*", destination: "/api/uploads/:path*" }],
      fallback: [],
    };
  },
};

export default nextConfig;
