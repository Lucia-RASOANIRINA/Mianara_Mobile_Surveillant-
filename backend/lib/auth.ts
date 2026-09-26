import bcrypt from "bcryptjs";
import { randomBytes, createHash } from "node:crypto";

/**
 * Coût bcrypt confirmé par un hash exemple fourni par l'équipe web
 * (`$2b$12$...`). Garder la même valeur ici : un compte doit rester
 * vérifiable des deux côtés (web et mobile) puisqu'ils partagent `users`.
 */
const BCRYPT_COST = 12;

export function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, BCRYPT_COST);
}

export function verifyPassword(
  password: string,
  storedHash: string,
): Promise<boolean> {
  return bcrypt.compare(password, storedHash);
}

/**
 * Jeton de session : haute entropie déjà (32 octets aléatoires), donc hashé
 * avec SHA-256 (rapide) plutôt que bcrypt (délibérément lent, pensé pour des
 * mots de passe à faible entropie choisis par un humain). Seul le hash est
 * stocké en base (`sessions.refresh_token_hash`) ; le jeton brut part au
 * client et ne doit plus jamais être recalculable à partir du hash.
 */
export function generateSessionToken(): string {
  return randomBytes(32).toString("base64url");
}

export function hashSessionToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}
