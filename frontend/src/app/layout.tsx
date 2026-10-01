import type { Metadata } from "next";
import "./globals.css";
import QueryProvider from "@/components/shared/QueryProvider";
import { AuthProvider } from "@/components/shared/AuthProvider";
import { DirManager } from "@/components/shared/DirManager";
import { SpeedInsights } from "@vercel/speed-insights/next";
import { inter, cairo, poppins, baloo2 } from "./fonts";

export const metadata: Metadata = {
  title: "School Management",
  description: "Next-generation school management platform for modern educational institutions.",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning className={`${inter.variable} ${cairo.variable} ${poppins.variable} ${baloo2.variable}`}>
      <body suppressHydrationWarning>
        <QueryProvider>
          <AuthProvider>
            <DirManager />
            {children}
            <SpeedInsights />
          </AuthProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
