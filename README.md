# next-neon-starter

A template for building tracker apps with Claude Code.

**Stack:** Next.js 16 (App Router) · Neon PostgreSQL · Auth.js v5 · Tailwind CSS 4 · TypeScript

## What's included

- Email/password authentication (signup, login, session management)
- Protected dashboard layout — any page inside `app/(dashboard)/` requires auth
- Neon serverless DB client with a typed `sql` helper
- Zod-validated environment variables that fail loudly on startup
- Global error, not-found, and loading pages
- `CLAUDE.md` with project conventions so Claude Code understands the codebase

## Using this template

### 1. Create a new repo from this template

On GitHub, click **Use this template → Create a new repository**, clone it, then install dependencies:

```bash
npm install
```

### 2. Set up Neon

1. Create a new project at [neon.tech](https://neon.tech)
2. Copy the connection string from the Neon dashboard

### 3. Configure environment variables

```bash
cp .env.example .env.local
```

Fill in `.env.local`:

```
DATABASE_URL=       # from Neon dashboard
AUTH_SECRET=        # run: npx auth secret
```

### 4. Run the database schema

Run `db/schema.sql` against your Neon database. You can do this from the Neon SQL editor or with `psql`:

```bash
psql $DATABASE_URL -f db/schema.sql
```

### 5. Start the dev server

```bash
npm run dev
```

Visit `http://localhost:3000`. Sign up at `/signup`, sign in at `/login`.

---

## Building your app with Claude Code

Open the project in Claude Code. The `CLAUDE.md` file gives Claude full context on conventions — you can go straight to describing features.

### Example prompts

**Add a new tracker:**
```
add a habits tracker. users can create habits and mark them complete each day.
```

**Add a data table:**
```
add a page at /expenses that lists all expenses for the current user from the database
```

**Add an API endpoint:**
```
add a POST /api/expenses route that creates a new expense for the current user
```

Claude Code will follow the existing patterns: adding tables to `db/schema.sql`, placing protected pages in `app/(dashboard)/`, writing mutations as Server Actions in `app/actions/`, and querying with `sql` from `lib/db.ts`.

---

## File structure

```
app/
  (auth)/           # /login, /signup — no auth required
  (dashboard)/      # protected pages, auth enforced by layout
  actions/          # Server Actions (mutations)
  api/              # Route handlers
lib/
  db.ts             # Neon SQL client
  dal.ts            # getUser() — request-memoized auth check
  env.ts            # Validated environment variables
db/
  schema.sql        # Database schema — extend for each app
auth.ts             # Auth.js config
middleware.ts       # Redirects for auth/unauth routes
```

## Adding a new feature

1. Add table(s) to `db/schema.sql` and run against Neon
2. Add page(s) under `app/(dashboard)/` for the UI
3. Add Server Actions under `app/actions/` for mutations
4. Query the DB in Server Components with `sql` from `lib/db.ts`
5. Get the current user with `getUser()` from `lib/dal.ts`
