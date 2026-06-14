"use client";

import { DotLottieReact } from "@lottiefiles/dotlottie-react";
import { useEffect, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { FullPageLoader } from "@/components/loading/full-page-loader";
import { Input } from "@/components/ui/input";
import { authService } from "@/services/auth.service";

const LOGIN_LOTTIE_SRC =
  "https://lottie.host/a568f5eb-3806-4150-b784-37665805e67d/MkAE7BXnfb.lottie";

// ─── Forgot Password Modal ────────────────────────────────────────────────────

function ForgotPasswordModal({ onClose }: { onClose: () => void }) {
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [message, setMessage] = useState("");

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setStatus("loading");
    try {
      const res = await fetch("/api/auth/reset-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim().toLowerCase() }),
      });
      const data = (await res.json()) as { success: boolean; message: string };
      setMessage(data.message ?? "Done.");
      setStatus(data.success || res.ok ? "success" : "error");
    } catch {
      setMessage("Something went wrong. Please try again.");
      setStatus("error");
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div className="w-full max-w-sm rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl dark:border-slate-700 dark:bg-slate-900">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-base font-semibold text-slate-800 dark:text-slate-100">
            Reset Admin Password
          </h2>
          <button
            onClick={onClose}
            className="text-lg leading-none text-slate-400 hover:text-slate-600"
          >
            ✕
          </button>
        </div>

        {status === "success" ? (
          <div className="space-y-4">
            <div className="rounded-xl bg-green-50 p-4 text-sm text-green-700 dark:bg-green-900/20 dark:text-green-400">
              ✓ {message}
            </div>
            <p className="text-xs text-slate-500">
              Your password has been reset to{" "}
              <strong className="font-semibold text-slate-700">Admin12345</strong>. Sign in
              and change it from settings.
            </p>
            <Button className="w-full" onClick={onClose}>
              Back to login
            </Button>
          </div>
        ) : (
          <form className="space-y-3" onSubmit={onSubmit}>
            <p className="text-sm text-slate-500">
              Enter your admin email. Your password will be reset to a default value.
            </p>
            <Input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@example.com"
              required
              disabled={status === "loading"}
            />
            {status === "error" && (
              <p className="text-sm text-rose-600">{message}</p>
            )}
            <div className="flex gap-2">
              <Button
                type="button"
                variant="ghost"
                className="flex-1"
                onClick={onClose}
                disabled={status === "loading"}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                className="flex-1"
                disabled={!email.trim() || status === "loading"}
              >
                {status === "loading" ? "Resetting…" : "Reset Password"}
              </Button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

// ─── Login Page ───────────────────────────────────────────────────────────────

export default function LoginPage() {
  const router = useRouter();
  const pathname = usePathname();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showForgot, setShowForgot] = useState(false);

  useEffect(() => {
    if (pathname !== "/login") {
      setLoading(false);
    }
  }, [pathname]);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await authService.login(email, password);
      router.push("/dashboard");
      router.refresh();
    } catch {
      setError("Invalid credentials");
      setLoading(false);
    }
  };

  return (
    <>
      <div className="flex min-h-dvh min-h-screen flex-col">
        <main className="flex min-h-0 flex-1 flex-col items-center justify-center px-4 py-8">
          <div className="w-full max-w-md">
            <Card className="w-full space-y-4">
              <h1 className="text-xl font-semibold">GlowFit Admin Login</h1>
              <form className="space-y-3" onSubmit={onSubmit}>
                <Input
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Email"
                  type="email"
                  required
                />
                <Input
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Password"
                  type="password"
                  required
                />
                {error ? <p className="text-sm text-rose-600">{error}</p> : null}
                <Button disabled={loading} className="w-full" type="submit">
                  {loading ? "Signing in…" : "Sign in"}
                </Button>
              </form>
              <div className="text-center">
                <button
                  type="button"
                  onClick={() => setShowForgot(true)}
                  className="text-sm text-slate-400 underline-offset-2 hover:text-slate-600 hover:underline dark:hover:text-slate-300"
                >
                  Forgot password?
                </button>
              </div>
            </Card>
          </div>
        </main>
        <div
          className="mt-auto w-full min-w-0 shrink-0 overflow-x-hidden pb-0 pt-0 leading-none"
          aria-hidden="true"
        >
          <DotLottieReact
            src={LOGIN_LOTTIE_SRC}
            loop
            autoplay
            layout={{ fit: "fit-width", align: [0.5, 1] }}
            renderConfig={{ autoResize: true }}
            className="block h-[clamp(7.5rem,22vw,13rem)] w-full min-w-0 sm:h-[clamp(8.5rem,26vw,15rem)] md:h-[clamp(9.5rem,28vw,17rem)]"
            style={{ width: "100%", maxWidth: "100%" }}
          />
        </div>
      </div>
      {loading ? <FullPageLoader label="Signing in…" /> : null}
      {showForgot ? <ForgotPasswordModal onClose={() => setShowForgot(false)} /> : null}
    </>
  );
}
