"use client";

import { createContext, useContext, useEffect, useState, useCallback, ReactNode } from "react";
import { useRouter } from "next/navigation";
import { supabase, isSupabaseConfigured } from "@/lib/supabase";
import { api } from "@/lib/api";
import { connectSocket, disconnectSocket } from "@/lib/socket";

type AuthUser = { id: string; email: string | undefined; fullName: string; schoolId?: string | null; role?: string; school?: any; avatarUrl?: string };

interface AuthContextType {
  user: AuthUser | null;
  loading: boolean;
  logout: (reason?: string) => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  const logout = useCallback(async (reason?: string) => {
    await supabase.auth.signOut();
    setUser(null);
    disconnectSocket();
    if (reason) alert(reason);
    router.push("/login");
  }, [router]);

  const fetchProfile = useCallback(async () => {
    try {
      const { data } = await api.get("/auth/me");
      if (data.success) {
        const { data: { user: sbUser } } = await supabase.auth.getUser();
        const userData: AuthUser = {
          id: data.data.id,
          email: data.data.email,
          fullName: data.data.fullName,
          schoolId: data.data.school?.id,
          role: data.data.role,
          school: data.data.school,
          avatarUrl: sbUser?.user_metadata?.custom_avatar_url || sbUser?.user_metadata?.avatar_url
        };
        setUser(userData);
        const accessToken = (await supabase.auth.getSession()).data.session?.access_token;
        if (accessToken) connectSocket(accessToken);
      }
    } catch (err: any) {
      if (err.response?.status !== 401) {
        console.error("Failed to fetch profile:", err);
      }
      setUser(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!isSupabaseConfigured) {
      setLoading(false);
      return;
    }

    // Initial session check
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session) {
        fetchProfile();
      } else {
        setLoading(false);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === "SIGNED_IN" && session) {
        // Show global loading screen while we fetch the profile
        setLoading(true);
        fetchProfile();
      } else if (event === "SIGNED_OUT") {
        setUser(null);
        setLoading(false);
        disconnectSocket();
      }
    });

    return () => subscription.unsubscribe();
  }, [fetchProfile]);

  return (
    <AuthContext.Provider value={{ user, loading, logout, refreshProfile: fetchProfile }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
