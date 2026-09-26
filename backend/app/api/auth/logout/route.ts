import { NextResponse } from "next/server";
import { query } from "@/lib/db";
import { hashSessionToken } from "@/lib/auth";

export async function POST(request: Request) {
  const authHeader = request.headers.get("authorization") ?? "";
  const token = authHeader.startsWith("Bearer ")
    ? authHeader.slice("Bearer ".length).trim()
    : "";

  if (!token) {
    return NextResponse.json(
      { error: "En-tête Authorization: Bearer <token> requis." },
      { status: 400 },
    );
  }

  const rows = await query<{ revoke_session: boolean }>(
    "select app.revoke_session($1) as revoke_session",
    [hashSessionToken(token)],
  );

  return NextResponse.json({ revoked: rows[0]?.revoke_session === true });
}
