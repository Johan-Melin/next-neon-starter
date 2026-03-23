import { cache } from "react";
import { auth } from "@/auth";
import { redirect } from "next/navigation";

export type SessionUser = {
  id: string;
  name: string;
  email: string;
};

/**
 * Returns the current session user, redirecting to /login if not authenticated.
 * Memoized per request via React cache().
 */
export const getUser = cache(async (): Promise<SessionUser> => {
  const session = await auth();
  if (!session?.user) redirect("/login");
  return session.user as SessionUser;
});
