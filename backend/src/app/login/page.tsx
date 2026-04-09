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

export default function LoginPage() {
  const router = useRouter();
  const pathname = usePathname();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

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
                <Input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" type="email" required />
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
            layout={{
              fit: "fit-width",
              align: [0.5, 1],
            }}
            renderConfig={{ autoResize: true }}
            className="block h-[clamp(7.5rem,22vw,13rem)] w-full min-w-0 sm:h-[clamp(8.5rem,26vw,15rem)] md:h-[clamp(9.5rem,28vw,17rem)]"
            style={{ width: "100%", maxWidth: "100%" }}
          />
        </div>
      </div>
      {loading ? <FullPageLoader label="Signing in…" /> : null}
    </>
  );
}
