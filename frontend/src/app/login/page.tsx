"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import LandingPage from "@/app/page";
import { useAuth } from "@/components/shared/AuthProvider";

export default function LoginPage() {
  const router = useRouter();
  const { user, loading } = useAuth();

  useEffect(() => {
    if (!loading && user) router.replace("/dashboard");
  }, [loading, router, user]);

  return <LandingPage initialAuthOpen={true} initialAuthMode="login" />;
}
