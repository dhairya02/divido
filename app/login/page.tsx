"use client";
import { useState } from "react";
import { signIn } from "next-auth/react";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    const res = await signIn("credentials", { email, password, redirect: false });
    if (res?.error) setError("Invalid credentials");
    else window.location.href = "/";
    setSubmitting(false);
  };

  return (
    <div className="w-full p-6 space-y-4">
      <h1 className="text-2xl font-semibold">Log in</h1>
      <form onSubmit={submit} className="space-y-3">
        <input className="input w-full" placeholder="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input className="input w-full" placeholder="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
        {error && <div className="text-red-600 text-sm">{error}</div>}
        <button className="btn-primary" type="submit" disabled={submitting}>{submitting ? "Logging in..." : "Log in"}</button>
      </form>
    </div>
  );
}


