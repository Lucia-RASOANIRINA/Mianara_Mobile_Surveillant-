import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import { hashPassword } from "@/lib/auth";

interface RegisterBody {
  username?: unknown;
  password?: unknown;
  fullName?: unknown;
  phone?: unknown;
  email?: unknown;
}

function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

/**
 * Inscription candidat. Appelle `app.register_candidate_account`, qui est
 * `SECURITY DEFINER` : elle gère elle-même l'insertion dans `users` avec
 * `role = 'candidate'` sans avoir besoin d'un contexte RLS préalable.
 */
export async function POST(request: Request) {
  let body: RegisterBody;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "JSON invalide." }, { status: 400 });
  }

  const { username, password, fullName, phone, email } = body;

  if (!isNonEmptyString(username) || !isNonEmptyString(fullName)) {
    return NextResponse.json(
      { error: "username et fullName sont obligatoires." },
      { status: 400 },
    );
  }
  if (typeof password !== "string" || password.length < 8) {
    return NextResponse.json(
      { error: "Le mot de passe doit contenir au moins 8 caractères." },
      { status: 400 },
    );
  }

  const passwordHash = await hashPassword(password);

  try {
    const rows = await query<{ register_candidate_account: string }>(
      "select app.register_candidate_account($1, $2, $3, $4, $5) as register_candidate_account",
      [
        username,
        passwordHash,
        fullName,
        isNonEmptyString(phone) ? phone : null,
        isNonEmptyString(email) ? email : null,
      ],
    );
    return NextResponse.json(
      { userId: rows[0]?.register_candidate_account },
      { status: 201 },
    );
  } catch (error) {
    const pgError = error as { code?: string; constraint?: string };
    if (pgError.code === "23505") {
      const field = pgError.constraint?.includes("email")
        ? "email"
        : "username";
      return NextResponse.json(
        { error: `Ce ${field === "email" ? "e-mail" : "identifiant"} est déjà utilisé.` },
        { status: 409 },
      );
    }
    console.error("register_candidate_account a échoué", error);
    return NextResponse.json(
      { error: "Inscription impossible pour le moment." },
      { status: 500 },
    );
  }
}
