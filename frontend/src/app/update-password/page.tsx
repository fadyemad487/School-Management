"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { AlertCircle, ArrowLeft, CheckCircle2, GraduationCap, ShieldCheck, ShieldAlert } from "lucide-react";

import { getPasswordRecoveryClient, hasVerifiedPasswordRecovery, isVerifiedPasswordRecoverySession, PASSWORD_RECOVERY_SESSION_KEY, supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { LanguageSwitcher } from "@/components/ui/LanguageSwitcher";
import { GlassPasswordInput } from "@/components/auth/GlassPasswordInput";
import { PasswordStrengthIndicator } from "@/components/auth/PasswordStrengthIndicator";
import { useAuth } from "@/components/shared/AuthProvider";
import { STRONG_PASSWORD_PATTERN, passwordPolicyMessage } from "@/lib/passwordPolicy";

const buildUpdatePasswordSchema = (isAr: boolean) => z.object({
  password: z.string().min(8, passwordPolicyMessage(isAr)).max(128, passwordPolicyMessage(isAr)).regex(STRONG_PASSWORD_PATTERN, passwordPolicyMessage(isAr)),
  confirmPassword: z.string()
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords do not match",
  path: ["confirmPassword"]
});

export default function UpdatePasswordPage() {
  const { t, isAr } = useTranslation();
  const router = useRouter();
  const { logout } = useAuth();
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [isDark, setIsDark] = useState(false);
  const [recoveryState, setRecoveryState] = useState<"checking" | "ready" | "invalid">("checking");
  const [recoveryClient, setRecoveryClient] = useState<typeof supabase | null>(null);

  useEffect(() => {
    const savedTheme = localStorage.getItem("cv_theme");
    setIsDark(savedTheme === "dark");
  }, []);

  useEffect(() => {
    let active = true;
    const authClient = getPasswordRecoveryClient();
    setRecoveryClient(authClient);

    const validateRecoverySession = async (session: Awaited<ReturnType<typeof authClient.auth.getSession>>["data"]["session"]) => {
      const verified = await isVerifiedPasswordRecoverySession(session, authClient);
      if (!active) return;

      if (verified) {
        sessionStorage.setItem(PASSWORD_RECOVERY_SESSION_KEY, "1");
        setRecoveryState("ready");
        window.history.replaceState(null, "", window.location.pathname);
      } else {
        sessionStorage.removeItem(PASSWORD_RECOVERY_SESSION_KEY);
        setRecoveryState("invalid");
      }
    };

    const { data: { subscription } } = authClient.auth.onAuthStateChange((event, session) => {
      if (!session || (event !== "PASSWORD_RECOVERY" && !hasVerifiedPasswordRecovery())) return;

      setRecoveryState("checking");
      // Defer Auth SDK calls until after its auth-state callback releases its lock.
      window.setTimeout(() => void validateRecoverySession(session), 0);
    });

    const verifyRecoverySession = async () => {
      const { data: { session } } = await authClient.auth.getSession();
      if (!active) return;
      await validateRecoverySession(session);
    };

    verifyRecoverySession();
    return () => {
      active = false;
      subscription.unsubscribe();
    };
  }, []);

  const toggleTheme = () => {
    setIsDark((current) => {
      const next = !current;
      localStorage.setItem("cv_theme", next ? "dark" : "light");
      return next;
    });
  };

  const updatePasswordSchema = buildUpdatePasswordSchema(isAr);
  const form = useForm<z.infer<typeof updatePasswordSchema>>({
    resolver: zodResolver(updatePasswordSchema),
    defaultValues: { password: "", confirmPassword: "" }
  });

  const onSubmit = form.handleSubmit(async (values) => {
    setError("");
    setIsUpdating(true);

    try {
      const authClient = recoveryClient;
      if (!authClient || recoveryState !== "ready" || !hasVerifiedPasswordRecovery()) {
        setRecoveryState("invalid");
        return;
      }

      const { data: { session: recoverySession }, error: recoverySessionError } = await authClient.auth.getSession();
      if (
        recoverySessionError || !recoverySession ||
        !(await isVerifiedPasswordRecoverySession(recoverySession, authClient))
      ) {
        setRecoveryState("invalid");
        return;
      }

      const { error: updateError } = await authClient.auth.updateUser({
        password: values.password
      });

      if (updateError) {
        setError(updateError.message);
      } else {
        setSuccess(true);
        // End the recovery session so it cannot silently become a dashboard
        // login. The user must authenticate again with the new password.
        sessionStorage.removeItem(PASSWORD_RECOVERY_SESSION_KEY);
        await authClient.auth.signOut().catch(() => undefined);
        await supabase.auth.signOut().catch(() => undefined);
        setTimeout(() => router.replace("/login?auth=login"), 2500);
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : (isAr ? "حصل خطأ، حاول مرة تانية." : "Something went wrong. Please try again."));
    } finally {
      setIsUpdating(false);
    }
  });

  const returnToSignIn = async () => {
    if (recoveryClient) await recoveryClient.auth.signOut().catch(() => undefined);
    await logout();
  };

  return (
    <main className={`cv-reset-page${isDark ? " cv-reset-page--dark" : ""}`} dir={isAr ? "rtl" : "ltr"}>
      <div className="cv-reset-topbar">
        <div className="wrap cv-reset-nav">
          <Link href="/" className="cv-reset-brand" aria-label="EduControl home">
            <span className="cv-reset-brand-mark"><GraduationCap size={21} strokeWidth={2.2} /></span>
            <span>EduControl</span>
          </Link>
          <div className="cv-reset-tools">
            <LanguageSwitcher appearance={isDark ? "onDark" : "onLight"} />
            <ThemeToggle
              isDark={isDark}
              onToggle={toggleTheme}
              labels={{ light: isAr ? "الوضع الفاتح" : "Switch to light mode", dark: isAr ? "الوضع الداكن" : "Switch to dark mode" }}
            />
          </div>
        </div>
      </div>

      <section className="cv-reset-content" dir={isAr ? "rtl" : "ltr"}>
        <div className="cv-reset-panel">
          <button type="button" onClick={returnToSignIn} className="cv-reset-back">
            <ArrowLeft size={17} aria-hidden="true" />
            <span>{isAr ? "العودة لتسجيل الدخول" : t("auth_return_login")}</span>
          </button>

          <div className="cv-reset-heading">
            <div className="cv-reset-icon"><ShieldCheck size={24} strokeWidth={1.9} /></div>
            <p className="cv-reset-eyebrow">{isAr ? "أمان حسابك" : "ACCOUNT SECURITY"}</p>
            <h1>{isAr ? "اختار كلمة مرور جديدة" : "Choose a new password"}</h1>
            <p className="cv-reset-subtitle">
              {isAr ? "أنشئ كلمة مرور قوية لتأمين حسابك، وبعدها هتقدر تدخل لحسابك." : "Create a strong password for your account. You can sign in as soon as it's updated."}
            </p>
          </div>

          {recoveryState === "checking" ? (
            <div className="cv-reset-status" role="status" aria-live="polite">
              <span className="cv-reset-spinner" />
              <p>{isAr ? "بنتأكد من رابط الاستعادة..." : "Verifying your recovery link..."}</p>
            </div>
          ) : recoveryState === "invalid" ? (
            <div className="cv-reset-invalid" role="alert">
              <ShieldAlert size={22} />
              <div>
                <h2>{isAr ? "رابط الاستعادة غير صالح" : "Recovery link unavailable"}</h2>
                <p>{isAr ? "افتح أحدث رابط وصل لبريدك الإلكتروني، أو ارجع لتسجيل الدخول واطلب رابطًا جديدًا." : "Open the latest recovery email, or return to sign in and request a new link."}</p>
              </div>
              <button type="button" onClick={returnToSignIn} className="cv-reset-submit">
                {isAr ? "العودة لتسجيل الدخول" : t("auth_return_login")}
              </button>
            </div>
          ) : success ? (
            <div className="cv-reset-success" role="status" aria-live="polite">
              <div className="cv-reset-success-icon"><CheckCircle2 size={27} strokeWidth={2.2} /></div>
              <div>
                <h2>{isAr ? "كلمة المرور اتغيرت بنجاح" : "Password updated"}</h2>
                <p>{isAr ? "سجّل دخولك بكلمة المرور الجديدة للمتابعة." : "Sign in with your new password to continue."}</p>
              </div>
            </div>
          ) : (
            <form className="cv-reset-form" onSubmit={onSubmit}>
              <div className="cv-reset-field">
                <label htmlFor="new-password">{isAr ? "كلمة المرور الجديدة" : "New password"}</label>
                <GlassPasswordInput
                  id="new-password"
                  autoComplete="new-password"
                  maxLength={128}
                  placeholder={isAr ? "اكتب كلمة مرور جديدة" : "Enter a new password"}
                  {...form.register("password")}
                />
                <PasswordStrengthIndicator password={form.watch("password")} />
                {form.formState.errors.password && (
                  <span className="cv-reset-field-error">
                    <AlertCircle size={14} />
                    {form.formState.errors.password.message}
                  </span>
                )}
              </div>

              <div className="cv-reset-field">
                <label htmlFor="confirm-password">{isAr ? "تأكيد كلمة المرور" : "Confirm password"}</label>
                <GlassPasswordInput
                  id="confirm-password"
                  autoComplete="new-password"
                  maxLength={128}
                  placeholder={isAr ? "اكتب كلمة المرور مرة تانية" : "Re-enter your new password"}
                  {...form.register("confirmPassword")}
                />
                {form.formState.errors.confirmPassword && (
                  <span className="cv-reset-field-error">
                    <AlertCircle size={14} />
                    {form.formState.errors.confirmPassword.message}
                  </span>
                )}
              </div>

              {error && <p className="cv-reset-error" role="alert">{error}</p>}

              <button type="submit" className="cv-reset-submit" disabled={isUpdating}>
                {isUpdating ? (isAr ? "جاري التحديث..." : "Updating password...") : (isAr ? "حفظ كلمة المرور الجديدة" : "Save new password")}
              </button>
            </form>
          )}

          <p className="cv-reset-footnote">
            {isAr ? "نصيحة: استخدم كلمة مرور مختلفة عن كلمات المرور الأخرى." : "For better security, use a password you don't use elsewhere."}
          </p>
        </div>

        <footer className="cv-reset-footer">© {new Date().getFullYear()} EduControl</footer>
      </section>
    </main>
  );
}
