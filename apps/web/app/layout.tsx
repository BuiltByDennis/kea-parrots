// Kea Parrot — root layout (Product P0 scaffold only).
// Font slot is TBD (OD-18): no font is loaded in P0.

import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Kea Parrot",
  description: "Kea Parrot — social discovery and micro-entertainment. P0 scaffold.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
