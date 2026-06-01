"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { AlertCircle, CheckCircle } from "lucide-react";

import { supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
import { AuthShell } from "@/components/auth/AuthShell";
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

  // We should be logged in via the recovery link fragment (access_token)
  // Supabase automatically parses this and creates a session.
  
  const form = useForm<z.infer<typeof updatePasswordSchema>>({
    resolver: zodResolver(updatePasswordSchema),
    defaultValues: {
      password: "",
      confirmPassword: ""
    }
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
        // Give the user time to see the success message before redirecting
        setTimeout(() => {
          router.push("/dashboard");
        }, 2000);
      }
    } catch (err: any) {
      setError(err.message || "An error occurred");
    } finally {
      setIsUpdating(false);
    }
  });

  return (
    <AuthShell
      variant="login" // We use login variant for standard size
      title={isAr ? "إعادة تعيين كلمة المرور" : "Reset Password"}
      subtitle={isAr ? "قم بإدخال كلمة المرور الجديدة لحسابك" : "Enter a new password for your account"}
    >
      {success ? (
        <div style={{ textAlign: "center", padding: "32px 0" }}>
          <div style={{ width: 64, height: 64, borderRadius: "50%", background: "rgba(34, 197, 94, 0.2)", color: "#22c55e", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 24px" }}>
            <CheckCircle size={32} />
          </div>
          <h3 style={{ fontSize: "20px", fontWeight: 800, color: "#fff", marginBottom: "8px" }}>
            {isAr ? "تم تغيير كلمة المرور بنجاح!" : "Password Reset Successfully!"}
          </h3>
          <p style={{ color: "rgba(255,255,255,0.7)", marginBottom: "32px" }}>
            {isAr ? "جاري توجيهك إلى لوحة التحكم..." : "Redirecting you to the dashboard..."}
          </p>
          <div className="spinner-large" style={{ borderColor: "rgba(255,255,255,0.2)", borderLeftColor: "#fff", margin: "0 auto", width: 32, height: 32 }} />
        </div>
      ) : (
        <form onSubmit={onSubmit}>
          <div className="glass-input-group" style={{ marginBottom: "20px" }}>
            <label>{isAr ? "كلمة المرور الجديدة" : "New Password"}</label>
            <GlassPasswordInput placeholder="••••••••" {...form.register("password")}  />
            <PasswordStrengthIndicator password={form.watch("password")} />
            {form.formState.errors.password && (
              <div className="field-error-inline error-shake">
                <AlertCircle size={14} />
                <span>{form.formState.errors.password.message}</span>
              </div>
            )}
          </div>

          <div className="glass-input-group">
            <label>{isAr ? "تأكيد كلمة المرور" : "Confirm Password"}</label>
            <GlassPasswordInput placeholder="••••••••" {...form.register("confirmPassword")}  />
            {form.formState.errors.confirmPassword && (
              <div className="field-error-inline error-shake">
                <AlertCircle size={14} />
                <span>{form.formState.errors.confirmPassword.message}</span>
              </div>
            )}
          </div>

          {error && <p className="error error-shake" style={{ marginBottom: "16px" }}>{error}</p>}
          
          <button type="submit" className={`btn-glass-primary ${isUpdating ? "btn-loading" : ""}`} disabled={isUpdating}>
            {isUpdating ? (isAr ? "جاري التحديث..." : "Updating...") : (isAr ? "تحديث كلمة المرور" : "Update Password")}
          </button>
        </form>
      )}

      {!success && (
        <p className="auth-bottom" style={{ color: "rgba(255,255,255,0.5)", marginTop: "24px", textAlign: "center" }}>
          <Link className="glass-link" href="/login" style={{ fontWeight: 700, color: "#fff" }}>
            {t('auth_return_login')}
          </Link>
        </p>
      )}
    </AuthShell>
  );
}
