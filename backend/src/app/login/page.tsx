"use client";

import { DotLottieReact } from "@lottiefiles/dotlottie-react";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { FullPageLoader } from "@/components/loading/full-page-loader";
import { Input } from "@/components/ui/input";
import { authService } from "@/services/auth.service";

const LOGIN_LOTTIE_SRC =
  "https://lottie.host/a568f5eb-3806-4150-b784-37665805e67d/MkAE7BXnfb.lottie";

const loginSchema = z.object({
  email: z.string().min(1, "Email is required").email("Enter a valid email address"),
  password: z.string().min(1, "Password is required"),
});

type LoginValues = z.infer<typeof loginSchema>;

/**
 * Password help.
 *
 * This dialog used to POST to /auth/reset-password and then display the shared
 * default password `Admin12345` on screen. That endpoint was unauthenticated,
 * so anyone knowing an admin email could take the account over — and this UI
 * advertised the resulting password. The endpoint is now super-admin only (see
 * SECURITY.md), which means self-service reset no longer exists. Showing a form
 * that always fails with 401 would be worse than explaining why; the Gmail OTP
 * flow meant to replace it is blocked on SMTP credentials.
 */
function PasswordHelpDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  return (
    <Dialog open={open} onOpenChange={(next) => !next && onClose()}>
      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>Forgot your password?</DialogTitle>
          <DialogDescription>Self-service reset is currently unavailable.</DialogDescription>
        </DialogHeader>
        <Alert variant="info" title="Ask a super admin">
          A super admin can issue you a one-time password. An email-based reset is being
          added.
        </Alert>
        <div className="mt-4 flex justify-end">
          <Button variant="secondary" onClick={onClose}>
            Close
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

export default function LoginPage() {
  const router = useRouter();
  const [serverError, setServerError] = useState("");
  const [showHelp, setShowHelp] = useState(false);

  const form = useForm<LoginValues>({
    resolver: zodResolver(loginSchema),
    // Validate once a field has been touched rather than on every keystroke —
    // errors appearing before you finish typing read as nagging.
    mode: "onTouched",
    defaultValues: { email: "", password: "" },
  });

  const { isSubmitting } = form.formState;

  const onSubmit = async (values: LoginValues) => {
    setServerError("");
    try {
      await authService.login(values.email, values.password);
      router.push("/dashboard");
      router.refresh();
    } catch {
      setServerError("Invalid email or password.");
    }
  };

  return (
    <>
      <div className="flex min-h-dvh min-h-screen flex-col">
        <main className="flex min-h-0 flex-1 flex-col items-center justify-center px-4 py-8">
          <div className="w-full max-w-md">
            <Card className="w-full space-y-4">
              <div>
                <h1 className="text-xl font-semibold text-foreground">GlowFit Admin</h1>
                <p className="text-sm text-muted-foreground">Sign in to continue</p>
              </div>

              <Form {...form}>
                <form className="space-y-3" onSubmit={form.handleSubmit(onSubmit)} noValidate>
                  <FormField
                    control={form.control}
                    name="email"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Email</FormLabel>
                        <FormControl>
                          <Input
                            {...field}
                            type="email"
                            autoComplete="email"
                            placeholder="you@example.com"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  <FormField
                    control={form.control}
                    name="password"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Password</FormLabel>
                        <FormControl>
                          <Input
                            {...field}
                            type="password"
                            autoComplete="current-password"
                            placeholder="••••••••"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />

                  {serverError && <Alert variant="danger">{serverError}</Alert>}

                  <Button disabled={isSubmitting} className="w-full" type="submit">
                    {isSubmitting ? "Signing in…" : "Sign in"}
                  </Button>
                </form>
              </Form>

              <div className="text-center">
                <button
                  type="button"
                  onClick={() => setShowHelp(true)}
                  className="text-sm text-muted-foreground underline-offset-2 hover:text-foreground hover:underline"
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

      {isSubmitting ? <FullPageLoader label="Signing in…" /> : null}
      <PasswordHelpDialog open={showHelp} onClose={() => setShowHelp(false)} />
    </>
  );
}
