# Mianara — backend mobile

API Next.js pour l'application mobile Mianara. Elle lit et écrit dans la
même base Postgres (Neon) que le site web de l'équipe, mais c'est un
service séparé : aucun code, aucune dépendance et aucun secret ne sont
partagés avec le dépôt web, à l'exception de la base de données elle-même.

## Pourquoi un backend séparé plutôt qu'un accès direct depuis le mobile

Le mobile ne doit jamais embarquer d'identifiants de connexion à la base :
un binaire distribué peut être décompilé, et une chaîne de connexion qu'il
contient devient immédiatement exploitable par n'importe qui, RLS ou non.
Ce backend est le seul composant autorisé à détenir `DATABASE_URL_APP` ; le
mobile lui parlera en HTTP.

## Rôle Postgres utilisé

Uniquement `mianara_app` (RLS active, sans `BYPASSRLS`), via
`DATABASE_URL_APP`. Ce dépôt ne gère ni migrations ni création de rôle —
`neondb_owner`/`DATABASE_URL_OWNER` restent la responsabilité du dépôt web,
qui possède déjà le schéma, `app.register_candidate_account` et les
politiques RLS.

## Démarrer

```sh
cd backend
npm install
cp .env.example .env.local
# renseigner DATABASE_URL_APP dans .env.local (à demander à l'équipe web)
npm run dev
```

Vérifier la connexion :

```sh
curl http://localhost:3000/api/health
```

## État vérifié (lecture seule, base de production)

Connexion testée en réel le 26/09/2026 via `mianara_app`. Confirmé par
introspection directe du schéma — pas supposé :

- **36 tables** en `public` : système complet (candidats, documents,
  examens, notes, résultats, paiements, cours/QCM, orientation, scans de
  présence, utilisateurs/sessions...).
- **RLS bien active et restrictive par défaut** : `select count(*) from
  candidates` sans contexte renvoie `0`. Les tables de référence marquées
  "public read" (`series`, `orientation_domains`, `subjects`, `regions`...)
  restent lisibles sans authentification, comme prévu par leurs policies.
- **Contexte RLS confirmé** — les fonctions `app.current_user_id()`,
  `app.current_office_id()`, `app.current_school_id()`, `app.current_role()`
  lisent respectivement `current_setting('app.user_id'|'app.office_id'|
  'app.school_id'|'app.user_role', true)`. `withRlsContext()` dans
  `lib/db.ts` pose exactement ces clés.
- **Auth applicative, pas Postgres-native** : `app.verify_login(username)`
  renvoie le hash stocké (comparaison à faire côté backend, pas en base),
  `app.create_session(...)` enregistre une session avec `refresh_token_hash`
  (7 jours), `app.resolve_session(token_hash)` la résout en
  `user_id/role/office_id/school_id`. `app.register_candidate_account(...)`
  crée un `users` avec `role='candidate'` (paramètres : `p_username,
  p_password_hash, p_full_name, p_phone, p_email` — le hash doit donc être
  calculé par ce backend, pas par la base).
- **`series` (L/S/OSE) est vide** en production pour l'instant — à signaler
  à l'équipe web si le mobile doit un jour lire les séries depuis la base
  plutôt que la liste codée en dur côté Flutter.
- **`orientation_domains` déjà peuplée** (7 filières : Agronomie, Droit,
  Économie, Informatique, Ingénierie, Lettres, Santé) — exploitable dès
  maintenant pour enrichir le module d'orientation de l'assistant mobile.

## Authentification (implémentée et testée)

- **Algorithme confirmé par l'équipe web** : bcrypt, coût 12 (`$2b$12$...`).
  `lib/auth.ts` utilise exactement ce coût — un compte créé par le mobile
  est vérifiable par le web et inversement, puisqu'ils partagent `users`.
- **Jetons de session** : générés côté backend (32 octets aléatoires,
  `base64url`), hashés en SHA-256 avant stockage (`sessions.refresh_token_hash`)
  — pas de bcrypt ici, volontairement lent pour des mots de passe humains,
  pas pour un jeton déjà à haute entropie. Le jeton brut n'est renvoyé
  qu'une fois, au client.
- **Routes** : `POST /api/auth/register`, `POST /api/auth/login`,
  `POST /api/auth/logout` (`Authorization: Bearer <token>`).
- **Test complet effectué** : hash → `register_candidate_account` →
  `verify_login` → `bcrypt.compare` → `register_login_failure` (verrouillage
  à 5 échecs) → `register_login_success` → `create_session` →
  `resolve_session` → `revoke_session`, tout dans une transaction terminée
  par `ROLLBACK` — donc contre la vraie base de production, sans y laisser
  de compte de test. Résultat : chaque étape s'est comportée comme attendu.
- **Non résolu** : si le mobile doit partager `AUTH_SECRET` avec le web
  pour des sessions interopérables, ou si `app.create_session`/
  `resolve_session` suffisent en gérant les siennes séparément (choix actuel
  de ce backend — pas de JWT, pas d'`AUTH_SECRET` utilisé ici).

## Ce qui manque avant d'aller plus loin

- **Contrat HTTP pour le reste** : `/api/auth/*` est la seule surface
  couverte. Profil candidat, dossier, révisions restent à définir avec
  l'équipe web pour éviter deux API incompatibles sur le même schéma.
- **`series` (L/S/OSE) vide en production** : à signaler si le mobile doit
  un jour lire les séries depuis la base plutôt que la liste codée en dur
  côté Flutter.
