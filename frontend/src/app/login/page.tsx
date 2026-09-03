"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { Mail, AlertCircle } from "lucide-react";

import { api, extractApiError } from "@/lib/api";
import { supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
import { AuthShell } from "@/components/auth/AuthShell";
import { GlassPasswordInput } from "@/components/auth/GlassPasswordInput";
import { useAuth } from "@/components/shared/AuthProvider";

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  rememberMe: z.boolean().optional()
});

const GoogleIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4" /><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" /><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" /><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" /></svg>
);
const FacebookIcon = () => (
  <svg viewBox="0 0 24 24" width="24" height="24" fill="#1877F2"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" /></svg>
);
const AppleIcon = () => (
  <svg viewBox="0 0 24 24" width="24" height="24" fill="#fff"><path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" /></svg>
);

export default function LoginPage() {
  const { t, isAr } = useTranslation();
  const router = useRouter();
  const { user, loading: authLoading, setAuthUser, refreshProfile } = useAuth();
  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [generalError, setGeneralError] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [oauthLoading, setOauthLoading] = useState<string | null>(null);
  const [oauthStatus, setOauthStatus] = useState<'idle' | 'verifying' | 'success' | 'error'>('idle');

  // Check if we are returning from an OAuth flow and verify cleanly without premature errors
  useEffect(() => {
    if (typeof window === "undefined") return;

    const hasOAuthToken = 
      window.location.hash.includes("access_token=") || 
      window.location.search.includes("code=");

    const oauthInitiated = sessionStorage.getItem("oauth_in_progress") === "true";

    // ONLY verify if an OAuth token is present AND OAuth was explicitly initiated
    // This strictly prevents any spurious verification on signout or normal navigation!
    if (!hasOAuthToken && !oauthInitiated) return;

    // Immediately consume the flag so it never runs again on subsequent page loads
    sessionStorage.removeItem("oauth_in_progress");

    setOauthStatus('verifying');
    let isMounted = true;

    const verifyOAuthFlow = async () => {
      try {
        // Wait for Supabase client to parse URL and populate session from window.location.hash
        let session = (await supabase.auth.getSession()).data.session;
        const start = Date.now();
        while (!session && Date.now() - start < 6000) {
          await new Promise((resolve) => setTimeout(resolve, 200));
          if (!isMounted) return;
          session = (await supabase.auth.getSession()).data.session;
        }

        // Clean up hash from browser address bar ONLY after Supabase has parsed it
        if (typeof window !== "undefined" && (window.location.hash || window.location.search)) {
          window.history.replaceState(null, '', window.location.pathname);
        }

        if (!session) {
          if (isMounted) {
            setOauthStatus('error');
            setTimeout(() => { if (isMounted) setOauthStatus('idle'); }, 4000);
          }
          return;
        }

        // Session is ready. Fetch local database user profile
        const profile = await refreshProfile();
        if (!isMounted) return;

        if (profile) {
          setOauthStatus('success');
          setTimeout(() => {
            if (isMounted) router.push("/dashboard");
          }, 1200);
        } else {
          setOauthStatus('error');
          setTimeout(() => {
            if (isMounted) setOauthStatus('idle');
          }, 4000);
        }
      } catch (err) {
        if (isMounted) {
          setOauthStatus('error');
          setTimeout(() => {
            if (isMounted) setOauthStatus('idle');
          }, 4000);
        }
      }
    };

    verifyOAuthFlow();

    return () => {
      isMounted = false;
    };
  }, [refreshProfile, router]);

  // Redirect if already logged in (when not verifying OAuth)
  useEffect(() => {
    if (oauthStatus === 'idle' && user) {
      router.push("/dashboard");
    }
  }, [user, oauthStatus, router]);
  
  // Handle Hydration safely for localStorage
  const [rememberedEmail, setRememberedEmail] = useState("");

  useEffect(() => {
    const saved = localStorage.getItem('edu_remembered_email') || "";
    setRememberedEmail(saved);
  }, []);
  
  const form = useForm<z.infer<typeof loginSchema>>({
    resolver: zodResolver(loginSchema),
    defaultValues: { 
      email: rememberedEmail,
      rememberMe: !!rememberedEmail 
    }
  });

  // Re-sync form when rememberedEmail is loaded (client-side)
  useEffect(() => {
    if (rememberedEmail) {
      form.setValue("email", rememberedEmail);
      form.setValue("rememberMe", true);
    }
  }, [rememberedEmail, form]);

  const onSubmit = form.handleSubmit(async (values) => {
    setEmailError("");
    setPasswordError("");
    setGeneralError("");
    setIsLoading(true);

    if (values.rememberMe) {
      localStorage.setItem('edu_remembered_email', values.email);
    } else {
      localStorage.removeItem('edu_remembered_email');
    }

    try {
      const { data: loginData } = await api.post("/auth/login", {
        email: values.email,
        password: values.password
      });

      if (loginData.data?.user) {
        setAuthUser({
          id: loginData.data.user.id,
          email: loginData.data.user.email,
          fullName: loginData.data.user.fullName,
          schoolId: loginData.data.user.school?.id,
          role: loginData.data.user.role,
          school: loginData.data.user.school,
          avatarUrl: loginData.data.user.avatarUrl
        });
      }

      if (loginData.data?.session) {
        await supabase.auth.setSession({
          access_token: loginData.data.session.access_token,
          refresh_token: loginData.data.session.refresh_token
        });
      }

      router.push("/dashboard");
    } catch (err: unknown) {
      const apiErr = extractApiError(err);
      const localizedMessage = t(apiErr.code as any) !== apiErr.code ? t(apiErr.code as any) : apiErr.message;

      if (apiErr.field === "email") setEmailError(localizedMessage);
      else if (apiErr.field === "password") setPasswordError(localizedMessage);
      else setGeneralError(localizedMessage);
    } finally {
      setIsLoading(false);
    }
  });

  /** OAuth Sign-In — redirects to provider, AuthProvider handles session callback */
  const handleOAuthSignIn = async (provider: 'google' | 'facebook' | 'apple') => {
    setOauthLoading(provider);
    setGeneralError("");
    try {
      if (typeof window !== "undefined") {
        sessionStorage.setItem("oauth_in_progress", "true");
      }
      const { error } = await supabase.auth.signInWithOAuth({
        provider,
        options: {
          redirectTo: `${window.location.origin}/login`,
        }
      });
      if (error) {
        if (typeof window !== "undefined") {
          sessionStorage.removeItem("oauth_in_progress");
        }
        setGeneralError(error.message);
        setOauthLoading(null);
      }
    } catch (err: any) {
      if (typeof window !== "undefined") {
        sessionStorage.removeItem("oauth_in_progress");
      }
      setGeneralError(err.message || "OAuth sign-in failed.");
      setOauthLoading(null);
    }
  };

  return (
    <AuthShell
      variant="login"
      title={t('auth_login_title')}
      subtitle={t('auth_login_subtitle')}
    >
      <div style={{ position: "relative" }}>
        {oauthStatus !== 'idle' && (
          <div style={{
            position: "absolute",
            inset: -20,
            zIndex: 10,
            background: "rgba(15, 23, 42, 0.7)",
            backdropFilter: "blur(8px)",
            borderRadius: "24px",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            color: "#fff",
            animation: "fadeIn 0.3s ease"
          }}>
            {oauthStatus === 'verifying' && (
              <>
                <div className="spinner-large" style={{ borderColor: "rgba(255,255,255,0.2)", borderLeftColor: "#fff", marginBottom: "16px" }} />
                <h3 style={{ fontSize: "18px", fontWeight: 800, marginBottom: "8px" }}>
                  {isAr ? "جاري التحقق..." : "Authenticating..."}
                </h3>
                <p style={{ fontSize: "13px", color: "rgba(255,255,255,0.7)", textAlign: "center", padding: "0 20px" }}>
                  {isAr ? "جاري الاتصال الآمن والتحقق من هويتك" : "Securely verifying your identity..."}
                </p>
              </>
            )}
            {oauthStatus === 'success' && (
              <>
                <div style={{ width: 56, height: 56, borderRadius: '50%', background: '#22c55e', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
                  <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
                </div>
                <h3 style={{ fontSize: "18px", fontWeight: 800, marginBottom: "8px" }}>
                  {isAr ? "تم بنجاح!" : "Success!"}
                </h3>
                <p style={{ fontSize: "13px", color: "rgba(255,255,255,0.7)", textAlign: "center", padding: "0 20px" }}>
                  {isAr ? "جاري توجيهك إلى لوحة التحكم..." : "Redirecting to your dashboard..."}
                </p>
              </>
            )}
            {oauthStatus === 'error' && (
              <>
                <div style={{ width: 56, height: 56, borderRadius: '50%', background: '#ef4444', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 16 }}>
                  <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                </div>
                <h3 style={{ fontSize: "18px", fontWeight: 800, marginBottom: "8px" }}>
                  {isAr ? "فشل التحقق" : "Verification Failed"}
                </h3>
                <p style={{ fontSize: "13px", color: "rgba(255,255,255,0.7)", textAlign: "center", padding: "0 20px" }}>
                  {isAr ? "الحساب غير مسجل لدينا" : "Account not found or not linked."}
                </p>
              </>
            )}
          </div>
        )}

        <div className="glass-social-row">
          <button type="button" className="glass-social-btn" onClick={() => handleOAuthSignIn('google')} disabled={!!oauthLoading || oauthStatus !== 'idle'} title="Sign in with Google">
            {oauthLoading === 'google' ? <div className="spinner-tiny" /> : <GoogleIcon />}
          </button>
          <button type="button" className="glass-social-btn" onClick={() => handleOAuthSignIn('facebook')} disabled={!!oauthLoading || oauthStatus !== 'idle'} title="Sign in with Facebook">
            {oauthLoading === 'facebook' ? <div className="spinner-tiny" /> : <FacebookIcon />}
          </button>
          <button type="button" className="glass-social-btn" onClick={() => handleOAuthSignIn('apple')} disabled={!!oauthLoading || oauthStatus !== 'idle'} title="Sign in with Apple">
            {oauthLoading === 'apple' ? <div className="spinner-tiny" /> : <AppleIcon />}
          </button>
        </div>

        <form onSubmit={onSubmit}>
          <div className="glass-input-group">
            <label>{t('field_email')}</label>
            <div className={`glass-input-wrapper ${emailError ? "input-error" : ""}`}>
              <Mail className="glass-input-icon" size={18} />
              <input placeholder="name@email.com" {...form.register("email")} />
            </div>
            {emailError && (
              <div className="field-error-inline error-shake">
                <AlertCircle size={14} />
                <span>{emailError}</span>
              </div>
            )}
          </div>

          <div className="glass-input-group">
            <label>{t('field_password')}</label>
            <GlassPasswordInput placeholder="••••••••" {...form.register("password")}  />
            {passwordError && (
              <div className="field-error-inline error-shake">
                <AlertCircle size={14} />
                <span>{passwordError}</span>
              </div>
            )}
          </div>

          <div
            className="remember-row"
            style={{
              marginBottom: "24px",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center"
            }}
          >
            <label
              className="checkbox-row"
              style={{
                color: "rgba(255,255,255,0.7)",
                display: "flex",
                alignItems: "center",
                gap: "8px"
              }}
            >
              <input type="checkbox" {...form.register("rememberMe")} />
              {t('btn_remember')}
            </label>

            <Link
              className="glass-link"
              style={{ fontSize: "14px" }}
              href="/forgot-password"
            >
              {t('btn_forgot')}
            </Link>
          </div>

          {generalError && <p className="error error-shake" style={{ marginBottom: "16px" }}>{generalError}</p>}
          
          <button type="submit" className={`btn-glass-primary ${isLoading ? "btn-loading" : ""}`} disabled={isLoading || !!oauthLoading || oauthStatus !== 'idle'}>
            {isLoading ? t('btn_authorizing') : t('btn_authorize')}
          </button>
        </form>

        <p className="auth-bottom" style={{ color: "rgba(255,255,255,0.5)", marginTop: "24px", textAlign: "center" }}>
          {t('btn_no_account')} <Link className="glass-link" href="/register" style={{ fontWeight: 700, color: "#fff" }}>{t('btn_signup')}</Link>
        </p>
      </div>
    </AuthShell>
  );
}
