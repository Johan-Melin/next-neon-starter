@AGENTS.md

# Project: next-neon-starter

Template for tracker apps. Stack: Next.js 16 (App Router), Neon PostgreSQL, Auth.js v5, Tailwind CSS 4, TypeScript.

## Key conventions

### Auth
- Auth is handled by Auth.js v5 (`auth.ts` at project root).
- Use `getUser()` from `lib/dal.ts` in Server Components to get the current user. It redirects to `/login` if not authenticated and is memoized per request.
- Authenticated pages live inside `app/(dashboard)/` which has a layout that enforces auth.
- Unauthenticated pages (`/login`, `/signup`) live inside `app/(auth)/`.
- Server Actions for auth are in `app/actions/auth.ts`.

### Database
- DB client: `sql` from `lib/db.ts` (Neon serverless tagged-template queries).
- Schema source of truth: `db/schema.sql`. Extend it when adding new tables.
- All queries run server-side only (Server Components or Server Actions).

### Environment variables
- Validated at startup via `lib/env.ts` (Zod). Add new vars there when needed.
- Copy `.env.example` to `.env.local` and fill in values for a new project.

### File structure
```
app/
  (auth)/       # login, signup — no auth required
  (dashboard)/  # protected pages — auth enforced by layout
  actions/      # Server Actions
  api/          # Route handlers
lib/
  db.ts         # Neon SQL client
  dal.ts        # Data Access Layer (getUser)
  env.ts        # Validated env vars
db/
  schema.sql    # Full DB schema
```

### Adding a new feature
1. Add table(s) to `db/schema.sql` and run against Neon.
2. Add page(s) under `app/(dashboard)/` for protected UI.
3. Add Server Actions under `app/actions/` for mutations.
4. Query the DB directly in Server Components using `sql` from `lib/db.ts`.
