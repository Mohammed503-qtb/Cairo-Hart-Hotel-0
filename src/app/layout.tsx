import type { Metadata, Viewport } from "next";
import { Cairo } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
import { ThemeProvider } from "@/components/theme-provider";

const cairo = Cairo({
  variable: "--font-cairo",
  subsets: ["arabic", "latin"],
  weight: ["400", "500", "600", "700", "800", "900"],
});

export const metadata: Metadata = {
  title: "فندق قلب القاهرة — عدن | حجز فوري وتجربة إقامة راقية",
  description:
    "فندق قلب القاهرة في قلب عدن — غرف عصرية، محرك حجز فوري بأسعار شفافة، وتطبيق إقامة متكامل للضيوف والاستقبال والإدارة.",
  keywords: ["فندق عدن", "حجز فندق", "قلب القاهرة", "عدن", "فندق", "إقامة"],
  icons: {
    icon: "/logo-hotel.svg",
  },
  openGraph: {
    title: "فندق قلب القاهرة — عدن",
    description: "ضيافة راقية في قلب عدن — احجز غرفتك الآن بأسعار شفافة وتأكيد فوري.",
    siteName: "فندق قلب القاهرة",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#1A3C6E",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ar" dir="rtl" suppressHydrationWarning>
      <body className={`${cairo.variable} font-sans antialiased bg-background text-foreground`}>
        <ThemeProvider>
          {children}
          <Toaster />
        </ThemeProvider>
      </body>
    </html>
  );
}
