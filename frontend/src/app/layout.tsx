import type { Metadata } from "next";
import "./globals.css";
import QueryProvider from "@/components/shared/QueryProvider";
import { AuthProvider } from "@/components/shared/AuthProvider";
import { DirManager } from "@/components/shared/DirManager";
import { SpeedInsights } from "@vercel/speed-insights/next";

export const metadata: Metadata = {
  title: "School Management",
  description: "Next-generation school management platform for modern educational institutions.",
  icons: {
    icon: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
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
