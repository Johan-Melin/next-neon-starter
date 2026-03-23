import { sql } from "@/lib/db";

export default async function Home() {
  const result = await sql`SELECT 1 AS value`;
  const connected = result[0]?.value === 1;

  return (
    <main>
      <p>{connected ? "DB connected" : "DB connection failed"}</p>
    </main>
  );
}
