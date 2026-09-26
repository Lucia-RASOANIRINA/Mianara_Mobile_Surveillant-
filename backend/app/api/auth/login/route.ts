import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import {
  generateSessionToken,
  hashSessionToken,
  verifyPassword,
} from "@/lib/auth";

interface LoginBody {
  username?: unknown;
  password?: unknown;
}

interface VerifyLoginRow {
  user_id: string;
  password_hash: string;
  role: string;
  must_change_password: boolean;
  locked_until: string | null;
}

export async function POST(request: Request) {
  let body: LoginBody;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "JSON invalide." }, { status: 400 });
  }

  const { username, password } = body;
  if (typeof username !== "string" || typeof password !== "string") {
    return NextResponse.json(
      { error: "username et password sont obligatoires." },
      { status: 400 },
    );
  }

  const rows = await query<VerifyLoginRow>(
    "select * from app.verify_login($1)",
    [username],
  );
  const account = rows[0];

  // Compte inexistant : `app.register_login_failure` reste sûr à appeler
  // (elle neutralise déjà ce cas côté base) — on ne révèle jamais si c'est
  // le nom d'utilisateur ou le mot de passe qui est en cause.
  if (!account) {
    await query("select app.register_login_failure($1)", [username]);
    return NextResponse.json(
      { error: "Identifiants invalides." },
      { status: 401 },
    );
  }

  if (account.locked_until && new Date(account.locked_until) > new Date()) {
    return NextResponse.json(
      {
        error: "Compte temporairement verrouillé après plusieurs échecs.",
        retryAt: account.locked_until,
      },
      { status: 423 },
    );
  }

  const passwordOk = await verifyPassword(password, account.password_hash);
  if (!passwordOk) {
    const [failure] = await query<{
      is_locked: boolean;
      retry_at: string | null;
    }>("select * from app.register_login_failure($1)", [username]);
    return NextResponse.json(
      {
        error: failure?.is_locked
          ? "Compte verrouillé après plusieurs échecs."
          : "Identifiants invalides.",
        retryAt: failure?.retry_at ?? undefined,
      },
      { status: failure?.is_locked ? 423 : 401 },
    );
  }

  await query("select app.register_login_success($1)", [username]);

  const token = generateSessionToken();
  const tokenHash = hashSessionToken(token);
  const userAgent = request.headers.get("user-agent");
  const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim();

  const [session] = await query<{ create_session: string }>(
    "select app.create_session($1, $2, $3, $4) as create_session",
    [account.user_id, tokenHash, userAgent ?? null, ip ?? null],
  );

  return NextResponse.json({
    token,
    userId: account.user_id,
    role: account.role,
    mustChangePassword: account.must_change_password,
    expiresAt: session?.create_session,
  });
}
