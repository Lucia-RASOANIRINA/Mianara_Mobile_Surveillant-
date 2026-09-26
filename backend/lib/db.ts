import { Pool, type PoolClient } from "@neondatabase/serverless";

/**
 * Connexion applicative à la base Postgres partagée avec le site web.
 *
 * Ce service n'utilise QUE le rôle `mianara_app` (RLS active, sans
 * BYPASSRLS) via `DATABASE_URL_APP`. Les migrations et le rôle
 * `neondb_owner` restent la responsabilité du dépôt web — ce backend ne
 * doit jamais recevoir `DATABASE_URL_OWNER`.
 */
function requireDatabaseUrl(): string {
  const url = process.env.DATABASE_URL_APP;
  if (!url) {
    throw new Error(
      "DATABASE_URL_APP est manquant. Copiez .env.example vers .env.local " +
        "et renseignez la chaîne de connexion applicative (rôle mianara_app, via le pooler).",
    );
  }
  return url;
}

let pool: Pool | undefined;

function getPool(): Pool {
  pool ??= new Pool({ connectionString: requireDatabaseUrl() });
  return pool;
}

/** Requête simple, hors contexte RLS particulier. */
export async function query<T = Record<string, unknown>>(
  text: string,
  params: unknown[] = [],
): Promise<T[]> {
  const result = await getPool().query(text, params);
  return result.rows as T[];
}

/**
 * Identité posée comme contexte RLS pour une requête. Les noms et le
 * comportement sont confirmés par lecture directe des fonctions `app.*` en
 * base (`current_user_id`, `current_office_id`, `current_school_id`,
 * `current_role`, toutes `STABLE`, lisant `current_setting('app.xxx', true)`) :
 * ce ne sont pas des suppositions.
 */
export interface RlsIdentity {
  userId?: string;
  role?: "candidate" | "school" | "office" | "admin";
  officeId?: number;
  schoolId?: number;
}

/**
 * Exécute `fn` dans une transaction où le contexte RLS est posé via
 * `set_config(..., true)` — donc local à la transaction, sûr avec une
 * connexion recyclée par le pooler. Un champ omis n'est pas posé : les
 * fonctions `app.current_*` renvoient alors NULL pour lui, comme pour une
 * requête anonyme.
 */
export async function withRlsContext<T>(
  identity: RlsIdentity,
  fn: (client: PoolClient) => Promise<T>,
): Promise<T> {
  const client = await getPool().connect();
  try {
    await client.query("BEGIN");
    if (identity.userId !== undefined) {
      await client.query("SELECT set_config('app.user_id', $1, true)", [
        identity.userId,
      ]);
    }
    if (identity.role !== undefined) {
      await client.query("SELECT set_config('app.user_role', $1, true)", [
        identity.role,
      ]);
    }
    if (identity.officeId !== undefined) {
      await client.query("SELECT set_config('app.office_id', $1, true)", [
        String(identity.officeId),
      ]);
    }
    if (identity.schoolId !== undefined) {
      await client.query("SELECT set_config('app.school_id', $1, true)", [
        String(identity.schoolId),
      ]);
    }
    const result = await fn(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}
