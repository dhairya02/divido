import type { Metadata } from "next";
import { EB_Garamond } from "next/font/google";
import "./globals.css";
import HistoryNav from "@/components/HistoryNav";
import Link from "next/link";
import Logo from "@/components/Logo";

const garamond = EB_Garamond({
  variable: "--font-body",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Divido",
  description: "Fair, precise bill splitting",
  icons: {
    icon: "/restaurantsplit-high-resolution-logo.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className={`${garamond.variable} antialiased`}>
        <div className="min-h-screen">
          <header className="sticky top-0 text-white border-b border-black/10" style={{ backgroundColor: "var(--color-primary)" }}>
            <div className="max-w-5xl mx-auto px-4 sm:px-6 py-2.5 flex items-center justify-between">
              <Link href="/" className="flex items-center gap-2 font-semibold text-lg" aria-label="Divido Home">
                <Logo className="h-10 w-auto" />
                <span className="hidden sm:inline text-[#E6FDA3] font-bold text-2xl">Divido</span>
              </Link>
              <HistoryNav />
            </div>
          </header>
          <main>
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
