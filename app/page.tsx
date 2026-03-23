import { auth, signOut } from "@/auth";
import Link from "next/link";

export default async function Home() {
  const session = await auth();

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4">
      {session?.user ? (
        <>
          <p>Signed in as <strong>{session.user.name}</strong> ({session.user.email})</p>
          <form
            action={async () => {
              "use server";
              await signOut({ redirectTo: "/login" });
            }}
          >
            <button type="submit" className="underline text-sm">
              Sign out
            </button>
          </form>
        </>
      ) : (
        <>
          <p>Not signed in.</p>
          <div className="flex gap-4 text-sm">
            <Link href="/login" className="underline">Sign in</Link>
            <Link href="/signup" className="underline">Sign up</Link>
          </div>
        </>
      )}
    </main>
  );
}
