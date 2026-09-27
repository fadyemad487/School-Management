"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import LandingPage from "@/app/page";
import { useAuth } from "@/components/shared/AuthProvider";

export default function LoginPage() {
  const router = useRouter();
  const { user, loading } = useAuth();
  const [checkingOAuth] = useState(
    () => typeof window !== "undefined" && Boolean(sessionStorage.getItem("oauth_in_progress"))
  );

  useEffect(() => {
    if (!loading && user && !checkingOAuth) router.replace("/dashboard");
  }, [checkingOAuth, loading, router, user]);

  return <LandingPage initialAuthOpen={true} initialAuthMode="login" />;
}
