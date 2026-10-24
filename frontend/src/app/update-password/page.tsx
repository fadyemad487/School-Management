"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { AlertCircle, ArrowLeft, CheckCircle2, GraduationCap } from "lucide-react";

import { supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
import { ThemeToggle } from "@/components/ui/ThemeToggle";
import { LanguageSwitcher } from "@/components/ui/LanguageSwitcher";
import { GlassPasswordInput } from "@/components/auth/GlassPasswordInput";
import { PasswordStrengthIndicator } from "@/components/auth/PasswordStrengthIndicator";

const updatePasswordSchema = z.object({
  password: z.string().min(6, "Password must be at least 6 characters"),
  confirmPassword: z.string()
}).refine(data => data.password === data.confirmPassword, {
  message: "Passwords do not match",
  path: ["confirmPassword"]
});

export default function UpdatePasswordPage() {
  const { t, isAr } = useTranslation();
  const router = useRouter();
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);
  const [isDark, setIsDark] = useState(false);

  useEffect(() => {
    const savedTheme = localStorage.getItem("cv_theme");
    setIsDark(savedTheme === "dark");
  }, []);

  const toggleTheme = () => {
    setIsDark((current) => {
      const next = !current;
      localStorage.setItem("cv_theme", next ? "dark" : "light");
      return next;
    });
  };

  const form = useForm<z.infer<typeof updatePasswordSchema>>({
    resolver: zodResolver(updatePasswordSchema),
    defaultValues: { password: "", confirmPassword: "" }
  });

  const onSubmit = form.handleSubmit(async (values) => {
    setError("");
    setIsUpdating(true);

    try {
      const { error: updateError } = await supabase.auth.updateUser({
        password: values.password
      });

      if (updateError) {
        setError(updateError.message);
      } else {
        setSuccess(true);
        setTimeout(() => router.push("/dashboard"), 2000);
      }
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : (isAr ? "حصل خطأ، حاول مرة تانية." : "Something went wrong. Please try again."));
    } finally {
      setIsUpdating(false);
    }
  });

  return (
    <main className={`cv-reset-page${isDark ? " cv-reset-page--dark" : ""}`} dir={isAr ? "rtl" : "ltr"}>
      <div className="cv-reset-topbar">
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

      <section className="cv-reset-content" dir={isAr ? "rtl" : "ltr"}>
        <div className="cv-reset-panel">
          <Link href="/login" className="cv-reset-back">
            <ArrowLeft size={17} aria-hidden="true" />
            <span>{isAr ? "العودة لتسجيل الدخول" : t("auth_return_login")}</span>
          </Link>

          <div className="cv-reset-heading">
            <div className="cv-reset-icon"><span /></div>
            <p className="cv-reset-eyebrow">{isAr ? "أمان حسابك" : "ACCOUNT SECURITY"}</p>
            <h1>{isAr ? "اختار كلمة مرور جديدة" : "Choose a new password"}</h1>
            <p className="cv-reset-subtitle">
              {isAr ? "أنشئ كلمة مرور قوية لتأمين حسابك، وبعدها هتقدر تدخل لحسابك." : "Create a strong password for your account. You can sign in as soon as it's updated."}
            </p>
          </div>

          {success ? (
            <div className="cv-reset-success" role="status" aria-live="polite">
              <div className="cv-reset-success-icon"><CheckCircle2 size={27} strokeWidth={2.2} /></div>
              <div>
                <h2>{isAr ? "كلمة المرور اتغيرت بنجاح" : "Password updated"}</h2>
                <p>{isAr ? "جاري توجيهك إلى لوحة التحكم..." : "Taking you to your dashboard..."}</p>
              </div>
            </div>
          ) : (
            <form className="cv-reset-form" onSubmit={onSubmit}>
              <div className="cv-reset-field">
                <label htmlFor="new-password">{isAr ? "كلمة المرور الجديدة" : "New password"}</label>
                <GlassPasswordInput
                  id="new-password"
                  autoComplete="new-password"
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
      </section>

      <footer className="cv-reset-footer">© {new Date().getFullYear()} EduControl</footer>
    </main>
  );
}
