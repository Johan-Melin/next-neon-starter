import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4">
      <h1 className="text-xl font-semibold">404 — Page not found</h1>
      <Link href="/" className="underline text-sm">
        Go home
      </Link>
    </div>
  );
}
