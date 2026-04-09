"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { authService } from "@/services/auth.service";
import type { Role } from "@/types";

export function withRoleGuard<TProps extends object>(
  Component: React.ComponentType<TProps>,
  roles: Role[],
) {
  return function Guarded(props: TProps) {
    const router = useRouter();

    useEffect(() => {
      let mounted = true;
      void authService
        .me()
        .then((res) => {
          if (!mounted) return;
          if (!roles.includes(res.user.role)) {
            router.replace("/dashboard");
          }
        })
        .catch(() => {
          if (!mounted) return;
          router.replace("/login");
        });
      return () => {
        mounted = false;
      };
    }, [router]);

    return <Component {...props} />;
  };
}
