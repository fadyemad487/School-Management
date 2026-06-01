"use client";

import { ReactNode } from "react";
import { GraduationCap } from "lucide-react";
import { useTranslation } from "@/lib/i18n";
import { BackButton } from "@/components/ui/BackButton";

export function AuthShell({
  title,
  subtitle,
  children
}: {
  variant: "login" | "register" | "forgot";
  title: string;
  subtitle: string;
  children: ReactNode;
}) {
  const { t } = useTranslation();
  return (
    <section className="auth-viewport">
      <div className="auth-bg-sphere sphere-1"></div>
      <div className="auth-bg-sphere sphere-2"></div>
      <div className="auth-bg-sphere sphere-3"></div>

      <div className="auth-container-premium">
        {/* ── Left Side (Hero) ── */}
        <aside className="auth-hero-premium">
          <div className="auth-logo-premium" style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "40px" }}>
            <BackButton className="auth-logo-back" />
            <div style={{ background: "var(--gradient-primary)", padding: "10px", borderRadius: "12px" }}><GraduationCap size={24} color="#fff" /></div>
            <h3 style={{ fontSize: "24px", color: "#fff", fontWeight: 800 }}>EduControl</h3>
          </div>
          <h1>{t('auth_welcome_title')}</h1>
          <p>{t('auth_welcome_desc')}</p>
          <div className="auth-hero-img-container">
            <img src="/auth-ref/login-premium.png" alt="Education Illustration" className="auth-hero-illustration" />
          </div>
        </aside>

        {/* ── Right Side (Form) ── */}
        <main className="auth-form-premium">
          <div className="auth-form-card">
            <h2>{title}</h2>
            <p className="subtitle">{subtitle}</p>
            {children}
          </div>
        </main>
      </div>

    </section>
  );
}
