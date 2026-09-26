import type { ReactNode } from "react";

export const metadata = {
  title: "Mianara API",
  description: "API backend pour l'application mobile Mianara.",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
