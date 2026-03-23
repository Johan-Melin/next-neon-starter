"use server";

import { signIn } from "@/auth";
import { sql } from "@/lib/db";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { AuthError } from "next-auth";

const signupSchema = z.object({
  name: z.string().min(1, "Name is required"),
  email: z.string().email("Invalid email"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export type ActionState = {
  errors?: { name?: string[]; email?: string[]; password?: string[] };
  message?: string;
};

export async function signup(
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  const parsed = signupSchema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) {
    return { errors: parsed.error.flatten().fieldErrors };
  }

  const { name, email, password } = parsed.data;

  const existing = await sql`SELECT id FROM users WHERE email = ${email} LIMIT 1`;
  if (existing.length > 0) {
    return { errors: { email: ["Email already in use"] } };
  }

  const password_hash = await bcrypt.hash(password, 12);
  await sql`INSERT INTO users (name, email, password_hash) VALUES (${name}, ${email}, ${password_hash})`;

  await signIn("credentials", { email, password, redirectTo: "/" });
  return {};
}

export async function login(
  _prevState: ActionState,
  formData: FormData
): Promise<ActionState> {
  try {
    await signIn("credentials", { ...Object.fromEntries(formData), redirectTo: "/" });
  } catch (e) {
    if (e instanceof AuthError) {
      return { message: "Invalid email or password" };
    }
    throw e;
  }
  return {};
}
