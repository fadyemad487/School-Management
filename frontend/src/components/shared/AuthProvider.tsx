"use client";

import { createContext, useContext, useEffect, useState, useCallback, useRef, ReactNode } from "react";
import { useRouter } from "next/navigation";
import { getCurrentSession, supabase, isSupabaseConfigured } from "@/lib/supabase";
import { api } from "@/lib/api";
import { connectSocket, disconnectSocket } from "@/lib/socket";
import { clearRememberedSession, getRememberedSession, syncRememberedSession } from "@/lib/rememberedSession";

export type AuthUser = { id: string; email: string | undefined; fullName: string; schoolId?: string | null; role?: string; school?: any; avatarUrl?: string };

interface AuthContextType {
  user: AuthUser | null;
  loading: boolean;
  logout: (reason?: string) => Promise<void>;
  refreshProfile: () => Promise<AuthUser | null>;
  setAuthUser: (user: AuthUser) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(() => {
    if (typeof window !== "undefined") {
      try {
        const cached = localStorage.getItem("edu_auth_user") || sessionStorage.getItem("edu_auth_user");
        if (cached) return JSON.parse(cached);
      } catch (_) {}
    }
    return null;
  });
  const [loading, setLoading] = useState(false);
  const profileRequest = useRef<Promise<AuthUser | null> | null>(null);
  const router = useRouter();

  const setAuthUser = useCallback((newUser: AuthUser) => {
    setUser(newUser);
    if (typeof window !== "undefined") {
      try {
        localStorage.setItem("edu_auth_user", JSON.stringify(newUser));
      } catch (_) {}
    }
  }, []);

  const logout = useCallback(async (reason?: string) => {
    await supabase.auth.signOut();
    setUser(null);
    clearRememberedSession();
    if (typeof window !== "undefined") {
      try {
        localStorage.removeItem("edu_auth_user");
        sessionStorage.removeItem("edu_auth_user");
        sessionStorage.removeItem("oauth_in_progress");
      } catch (_) {}
    }
    disconnectSocket();
    if (reason) alert(reason);
    if (typeof window !== "undefined") {
      window.location.href = "/login";
    } else {
      router.replace("/login");
    }
  }, [router]);

  const fetchProfile = useCallback(async (): Promise<AuthUser | null> => {
    if (profileRequest.current) return profileRequest.current;

    const request = (async (): Promise<AuthUser | null> => {
    setLoading(true);
    try {
      const { data } = await api.get("/auth/me");
      if (data.success) {
        const session = await getCurrentSession();
        const userData: AuthUser = {
          id: data.data.id,
          email: data.data.email,
          fullName: data.data.fullName,
          schoolId: data.data.school?.id,
          role: data.data.role,
          school: data.data.school,
          avatarUrl: session?.user.user_metadata?.custom_avatar_url || session?.user.user_metadata?.avatar_url
        };
        setUser(userData);
        if (typeof window !== "undefined") {
          try {
            localStorage.setItem("edu_auth_user", JSON.stringify(userData));
          } catch (_) {}
        }
        const accessToken = (await getCurrentSession())?.access_token;
        if (accessToken) connectSocket(accessToken);
        return userData;
      }
      return null;
    } catch (err: any) {
      if (err.response?.status !== 401) {
        console.error("Failed to fetch profile:", err);
      }
      setUser(null);
      if (typeof window !== "undefined") {
        try {
          localStorage.removeItem("edu_auth_user");
          sessionStorage.removeItem("edu_auth_user");
        } catch (_) {}
      }
      if (err.response?.status === 401) {
        clearRememberedSession();
        await supabase.auth.signOut();
      }
      return null;
    } finally {
      setLoading(false);
    }
    })();

    profileRequest.current = request;
    try {
      return await request;
    } finally {
      profileRequest.current = null;
    }
  }, []);

  useEffect(() => {
    if (!isSupabaseConfigured) {
      setLoading(false);
      return;
    }

    const initializeSession = async () => {
      let session = await getCurrentSession();

      if (!session) {
        const remembered = getRememberedSession();
        if (remembered) {
          const { data, error } = await supabase.auth.setSession(remembered);
          if (!error) session = data.session;
          else clearRememberedSession();
        }
      }

      if (session) {
        syncRememberedSession(session);
        await fetchProfile();
        return;
      }

      setUser(null);
      if (typeof window !== "undefined") {
        try {
          localStorage.removeItem("edu_auth_user");
          sessionStorage.removeItem("edu_auth_user");
        } catch (_) {}
      }
      setLoading(false);
    };

    initializeSession();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      if ((event === "SIGNED_IN" || event === "TOKEN_REFRESHED") && session) {
        syncRememberedSession(session);
        fetchProfile();
      } else if (event === "SIGNED_OUT") {
        setUser(null);
        clearRememberedSession();
        if (typeof window !== "undefined") {
          try {
            localStorage.removeItem("edu_auth_user");
            sessionStorage.removeItem("edu_auth_user");
          } catch (_) {}
        }
        setLoading(false);
        disconnectSocket();
      }
    });

    return () => subscription.unsubscribe();
  }, [fetchProfile]);

  return (
    <AuthContext.Provider value={{ user, loading, logout, refreshProfile: fetchProfile, setAuthUser }}>
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
