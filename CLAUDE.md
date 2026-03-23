@AGENTS.md

# Project: next-neon-starter

Template for tracker apps. Stack: Next.js 16 (App Router), Neon PostgreSQL, Auth.js v5, Tailwind CSS 4, TypeScript.

## Key conventions

### Auth
- Auth is handled by Auth.js v5 (`auth.ts` at project root).
- Route protection is in `proxy.ts` (Next.js 16 renamed Middleware → Proxy). Export as named `proxy` const.
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
proxy.ts        # Route protection (Next.js 16 Proxy, replaces middleware)
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

### Metadata (title, description, favicon)

Set app-wide metadata in `app/layout.tsx`. Always fill in a real title and description — never leave them as placeholder strings:
```ts
export const metadata: Metadata = {
  title: {
    template: "%s | MyApp",  // page title format
    default: "MyApp",        // shown when no page-level title is set
  },
  description: "One-line description of what the app does.",
};
```

For per-page titles, export `metadata` from the page file:
```ts
export const metadata: Metadata = { title: "Dashboard" };
// → renders as "Dashboard | MyApp"
```

The favicon lives at `app/favicon.ico`. Replace it with a project-specific icon — Next.js picks it up automatically with no extra config needed.

### Adding a new feature
1. Add table(s) to `db/schema.sql` and run against Neon.
2. Add page(s) under `app/(dashboard)/` for protected UI.
3. Add Server Actions under `app/actions/` for mutations.
4. Query the DB directly in Server Components using `sql` from `lib/db.ts`.

### Server Actions pattern

Always follow this structure for Server Actions that mutate data:
```ts
"use server";

import { getUser } from "@/lib/dal";
import { sql } from "@/lib/db";
import { revalidatePath } from "next/cache";

export async function createEntry(formData: FormData) {
  const user = await getUser(); // redirects if not authenticated

  const value = formData.get("value") as string;
  if (!value) return { error: "Value is required" };

  await sql`
    INSERT INTO entries (user_id, value, created_at)
    VALUES (${user.id}, ${value}, NOW())
  `;

  revalidatePath("/tracker");
}
```

Key points:
- Always call `getUser()` first — it handles auth and gives you `user.id`.
- Validate inputs before hitting the DB.
- Return `{ error: string }` for expected failures so the client can display them.
- Call `revalidatePath()` after mutations so Server Components re-fetch fresh data.

### Returning errors from Server Actions

Server Actions should return a plain object for expected errors, not throw:
```ts
// Good — client can read this
return { error: "Weight must be a positive number" };

// Bad — unhandled throw crashes the action
throw new Error("Invalid input");
```

On the client side, check the return value:
```tsx
"use client";

export function EntryForm() {
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(formData: FormData) {
    const result = await createEntry(formData);
    if (result?.error) setError(result.error);
  }

  return (
    <form action={handleSubmit}>
      {error && <p className="text-red-500 text-sm">{error}</p>}
      ...
    </form>
  );
}
```

### Revalidation after mutations

After any insert, update, or delete in a Server Action, call `revalidatePath()` with the route that displays the affected data. Without this, the page will serve stale cached data.
```ts
revalidatePath("/tracker");           // revalidate a specific route
revalidatePath("/tracker", "layout"); // revalidate layout + all children
```

If the mutation affects multiple routes (e.g. a dashboard summary and a detail page), call `revalidatePath` for each.

### Default to Server Components

Do not add `"use client"` unless the component genuinely needs it. Valid reasons:
- Uses React state (`useState`, `useReducer`)
- Uses browser APIs or event listeners
- Uses a client-only library

Data fetching, DB queries, and auth checks all work in Server Components and should stay there. Keeping components on the server reduces bundle size and avoids prop-drilling auth state.

## Known gotchas

### Route conflicts with `app/page.tsx`
`app/page.tsx` and `app/(dashboard)/page.tsx` both resolve to `/` — Next.js will throw a build error if both exist. Protected pages must live at a sub-path (e.g. `app/(dashboard)/tracker/page.tsx` → `/tracker`). Keep `app/page.tsx` as a thin redirect: redirect authenticated users to the app, show login/signup links otherwise.

### Auth.js v5 does not forward `user.id` into the session automatically
The `id` returned from `authorize()` is stored as `token.sub` in the JWT, but `session.user.id` is **not** populated unless you wire it up explicitly. Always add these callbacks to `auth.ts`:
```ts
callbacks: {
  jwt({ token, user }) {
    if (user?.id) token.sub = user.id;
    return token;
  },
  session({ session, token }) {
    if (token.sub) session.user.id = token.sub;
    return session;
  },
},
```
Without this, any insert that uses `user.id` from `getUser()` will fail with a not-null constraint violation.

### `searchParams` and `params` are Promises in Next.js 16
Page props must be awaited before use:
```ts
export default async function Page({
  searchParams,
}: {
  searchParams: Promise<{ year?: string; page?: string }>
}) {
  const { year, page } = await searchParams;
}
```

### Neon `sql` results are untyped — cast explicitly
The tagged-template `sql` function returns `any[]`. Cast results at the call site:
```ts
const rows = (await sql`SELECT ...`) as Array<{ id: string; name: string }>;
```

### Conditional WHERE clauses require separate query branches
The Neon `sql` tag does not support interpolating raw SQL fragments safely. For optional filters, write separate queries:
```ts
if (yearFilter) {
  rows = await sql`SELECT ... WHERE user_id = ${id} AND EXTRACT(YEAR FROM date) = ${yearFilter}`;
} else {
  rows = await sql`SELECT ... WHERE user_id = ${id}`;
}
```

### Linting
Use `npm run lint`, not `npx next lint` (the latter misinterprets the command in some shells).

### Safari zooms in on input focus
Safari auto-zooms the viewport when an input receives focus if its `font-size` is below 16px. Tailwind's `text-sm` is 14px — enough to trigger it. Fix globally in `globals.css`:
```css
input, select, textarea {
  font-size: 16px;
}
```

### Content and inputs overflowing their containers
Flex children can exceed their parent's width if not constrained. Date and number inputs inside a `flex` row are common offenders. Always add `min-w-0` alongside `flex-1` on inputs that should grow:
```tsx
<input className="flex-1 min-w-0 ..." />
```
For rows with many items (e.g. filter controls + date range), split into multiple rows rather than relying on `flex-wrap` — wrapping is unpredictable across screen sizes. Auth pages also need `px-4` on the outer wrapper so the form never touches screen edges on narrow phones.

### Mobile padding and margins
Always check padding at mobile widths. Specific patterns that bite:
- Auth pages (`/login`, `/signup`): the centering wrapper needs `px-4`, otherwise inputs reach the screen edge.
- Card sections: `p-4` is the right card padding; `p-6` feels too large and wastes space on mobile.
- Nav/main layout: use `px-4 sm:px-6` on wrappers so content breathes on small screens.
- Touch targets: interactive elements (icon buttons, small pills) should be at least 44×44px tappable area. Wrap small icons in a `p-2` button if needed.
