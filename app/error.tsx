"use client";

export default function Error({
  error,
  unstable_retry,
}: {
  error: Error & { digest?: string };
  unstable_retry: () => void;
}) {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4">
      <h1 className="text-xl font-semibold">Something went wrong</h1>
      <p className="text-sm text-zinc-500">{error.message || "An unexpected error occurred."}</p>
      <button onClick={unstable_retry} className="underline text-sm">
        Try again
      </button>
    </div>
  );
}
