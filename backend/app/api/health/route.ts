import { NextResponse } from "next/server";
import { query } from "@/lib/db";

/**
 * Vérifie la connectivité à la base partagée. C'est la seule route
 * garantie correcte à ce stade — les routes métier (profil, dossier,
 * révisions) attendent encore le schéma réel côté web avant d'être écrites.
 */
export async function GET() {
  try {
    await query("SELECT 1");
    return NextResponse.json({ ok: true, db: "connected" });
  } catch (error) {
    return NextResponse.json(
      {
        ok: false,
        db: "unreachable",
        error: error instanceof Error ? error.message : String(error),
      },
      { status: 503 },
    );
  }
}
