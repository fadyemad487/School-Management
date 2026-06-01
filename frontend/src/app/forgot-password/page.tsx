"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { Globe } from "lucide-react";

import { useTranslation } from "@/lib/i18n";
import { AuthShell } from "@/components/auth/AuthShell";
import { supabase, isSupabaseConfigured } from "@/lib/supabase";
import { api } from "@/lib/api";

const forgotSchema = z.object({
  email: z.string().email()
});

export default function ForgotPasswordPage() {
  const { t, isAr } = useTranslation();
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [isSending, setIsSending] = useState(false);
  const form = useForm<z.infer<typeof forgotSchema>>({ resolver: zodResolver(forgotSchema) });

  const onSubmit = form.handleSubmit(async ({ email }) => {
    setError("");
    setSuccess("");
    setIsSending(true);
    try {
      if (!isSupabaseConfigured) {
        setError("Supabase config error.");
        return;
      }

      // Step 1: Check if the email exists in our database
      const checkRes = await api.get(`/auth/check-school-email/${encodeURIComponent(email)}`);
      // If 'available' is true, it means the email is NOT in the database (it's available for registration)
      if (checkRes.data?.data?.available) {
        setError(isAr ? "هذا البريد الإلكتروني غير مسجل لدينا. الرجاء التأكد من كتابته بشكل صحيح." : "This email is not registered. Please check and try again.");
        return;
      }

      // Step 2: Send recovery link via Supabase
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/update-password`
      });
      
      if (resetError) {
        setError(resetError.message);
        return;
      }
      
      setSuccess(t('auth_recovery_sent'));
    } catch (err: any) {
      setError(err.message || "An unexpected error occurred");
    } finally {
      setIsSending(false);
    }
  });

  return (
    <AuthShell
      variant="forgot"
      title={t('auth_forgot_title')}
      subtitle={t('auth_forgot_subtitle')}
    >
      <form onSubmit={onSubmit}>
        <div className="glass-input-group">
          <label>{t('field_email_recover')}</label>
          <div className="glass-input-wrapper">
            <Globe className="glass-input-icon" size={18} />
            <input placeholder={t('field_email_recover_placeholder')} {...form.register("email")} />
          </div>
        </div>

        {error && <p className="error error-shake" style={{ marginBottom: "16px" }}>{error}</p>}
        {success && <p className="success" style={{ marginBottom: "16px" }}>{success}</p>}
        <button type="submit" className={`btn-glass-primary ${isSending ? "btn-loading" : ""}`} disabled={isSending}>
          {isSending ? (isAr ? "جاري الإرسال..." : "Sending...") : t('btn_send_link')}
        </button>
      </form>

      <p className="auth-bottom" style={{ color: "rgba(255,255,255,0.5)", marginTop: "24px", textAlign: "center" }}>
        {t('auth_regained_access')} <Link className="glass-link" href="/login" style={{ fontWeight: 700, color: "#fff" }}>{t('auth_return_login')}</Link>
      </p>
    </AuthShell>
  );
}
