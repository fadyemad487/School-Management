"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { AlertCircle, CheckCircle2, KeyRound, ArrowRight, ArrowLeft, GraduationCap, Loader2, ShieldCheck, HelpCircle } from "lucide-react";

import { supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
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

  const [checkingSession, setCheckingSession] = useState(true);
  const [hasValidToken, setHasValidToken] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [isUpdating, setIsUpdating] = useState(false);

  const form = useForm<z.infer<typeof updatePasswordSchema>>({
    resolver: zodResolver(updatePasswordSchema),
    defaultValues: {
      password: "",
      confirmPassword: ""
    }
  });

  useEffect(() => {
    // Check if recovery token session exists in URL fragment or memory
    const verifyRecoverySession = async () => {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        
        // Check hash parameters for access_token or recovery type
        const hash = typeof window !== "undefined" ? window.location.hash : "";
        const isRecoveryInHash = hash.includes("type=recovery") || hash.includes("access_token=");
        
        if (!session && !isRecoveryInHash) {
          setHasValidToken(false);
        } else {
          setHasValidToken(true);
        }
      } catch (err) {
        setHasValidToken(false);
      } finally {
        setCheckingSession(false);
      }
    };

    verifyRecoverySession();
  }, []);

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
        // SECURITY HIGH: Clear the recovery session so the user must log in cleanly with new password
        await supabase.auth.signOut().catch(() => {});
        if (typeof window !== "undefined") {
          try {
            localStorage.removeItem("edu_auth_user");
            sessionStorage.removeItem("edu_auth_user");
          } catch (_) {}
        }
        setSuccess(true);
      }
    } catch (err: any) {
      setError(err.message || "An unexpected error occurred");
    } finally {
      setIsUpdating(false);
    }
  });

  const ArrowIcon = isAr ? ArrowLeft : ArrowRight;

  return (
    <div
      style={{
        minHeight: "100vh",
        width: "100vw",
        background: "radial-gradient(circle at 50% 0%, #1e1b4b 0%, #0f172a 60%, #090d16 100%)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "24px",
        position: "relative",
        overflow: "hidden",
        fontFamily: "var(--font-cairo), var(--font-inter), sans-serif",
        direction: isAr ? "rtl" : "ltr"
      }}
    >
      {/* Background Animated Ambient Glowing Spheres */}
      <div
        style={{
          position: "absolute",
          top: "-15%",
          left: "50%",
          transform: "translateX(-50%)",
          width: "600px",
          height: "600px",
          background: "radial-gradient(circle, rgba(99, 102, 241, 0.25) 0%, rgba(0, 0, 0, 0) 70%)",
          filter: "blur(60px)",
          pointerEvents: "none"
        }}
      />
      <div
        style={{
          position: "absolute",
          bottom: "-10%",
          left: "10%",
          width: "400px",
          height: "400px",
          background: "radial-gradient(circle, rgba(168, 85, 247, 0.15) 0%, rgba(0, 0, 0, 0) 70%)",
          filter: "blur(60px)",
          pointerEvents: "none"
        }}
      />

      <div
        style={{
          width: "100%",
          maxWidth: "480px",
          background: "rgba(15, 23, 42, 0.75)",
          backdropFilter: "blur(24px)",
          WebkitBackdropFilter: "blur(24px)",
          border: "1px solid rgba(255, 255, 255, 0.12)",
          borderRadius: "28px",
          padding: "40px 36px",
          boxShadow: "0 25px 50px -12px rgba(0, 0, 0, 0.6), inset 0 1px 1px rgba(255, 255, 255, 0.1)",
          position: "relative",
          zIndex: 10
        }}
      >
        {/* Brand Header */}
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "32px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
            <div style={{ background: "linear-gradient(135deg, #4338ca, #6d28d9)", padding: "10px", borderRadius: "14px", boxShadow: "0 4px 12px rgba(99, 102, 241, 0.3)" }}>
              <GraduationCap size={24} color="#ffffff" />
            </div>
            <h3 style={{ fontSize: "22px", color: "#ffffff", fontWeight: 800, letterSpacing: "-0.5px" }}>
              Edu<span style={{ color: "#818cf8" }}>Control</span>
            </h3>
          </div>

          <Link
            href="/login"
            style={{
              display: "flex",
              alignItems: "center",
              gap: "6px",
              color: "rgba(255, 255, 255, 0.6)",
              fontSize: "13px",
              fontWeight: 600,
              textDecoration: "none",
              padding: "6px 12px",
              borderRadius: "10px",
              background: "rgba(255, 255, 255, 0.05)",
              border: "1px solid rgba(255, 255, 255, 0.08)",
              transition: "all 0.2s ease"
            }}
          >
            <span>{isAr ? "تسجيل الدخول" : "Sign In"}</span>
            <ArrowIcon size={14} />
          </Link>
        </div>

        {checkingSession ? (
          <div style={{ textAlign: "center", padding: "48px 0", color: "rgba(255, 255, 255, 0.6)" }}>
            <Loader2 className="animate-spin" size={32} style={{ margin: "0 auto 16px", color: "#818cf8" }} />
            <p style={{ fontSize: "14px" }}>{isAr ? "جاري تحقق من رابط الاستعادة..." : "Verifying recovery link..."}</p>
          </div>
        ) : !hasValidToken ? (
          /* Invalid / Expired Token Warning Screen */
          <div style={{ textAlign: "center", padding: "16px 0" }}>
            <div
              style={{
                width: 64,
                height: 64,
                borderRadius: "20px",
                background: "rgba(245, 158, 11, 0.15)",
                border: "1px solid rgba(245, 158, 11, 0.3)",
                color: "#fbbf24",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                margin: "0 auto 20px"
              }}
            >
              <HelpCircle size={32} />
            </div>

            <h3 style={{ fontSize: "20px", fontWeight: 800, color: "#ffffff", marginBottom: "10px" }}>
              {isAr ? "رابط غير صالح أو منتهي الصلاحية" : "Invalid or Expired Link"}
            </h3>

            <p style={{ color: "rgba(255, 255, 255, 0.65)", fontSize: "14px", lineHeight: "1.6", marginBottom: "28px" }}>
              {isAr
                ? "يبدو أن رابط استعادة كلمة السر هذا قد استُخدم بالفعل أو انتهت مدة صلاحيته. يرجى طلب رابط جديد."
                : "This password recovery link has already been used or has expired. Please request a new link."}
            </p>

            <Link
              href="/forgot-password"
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "8px",
                width: "100%",
                padding: "14px",
                borderRadius: "14px",
                background: "linear-gradient(135deg, #4f46e5, #6d28d9)",
                color: "#ffffff",
                fontWeight: 700,
                fontSize: "15px",
                textDecoration: "none",
                boxShadow: "0 10px 25px -5px rgba(79, 70, 229, 0.4)",
                transition: "transform 0.2s ease"
              }}
            >
              <span>{isAr ? "طلب رابط جديد لإعادة التعيين" : "Request New Recovery Link"}</span>
              <ArrowIcon size={16} />
            </Link>
          </div>
        ) : success ? (
          /* Success Screen */
          <div style={{ textAlign: "center", padding: "16px 0" }}>
            <div
              style={{
                width: 68,
                height: 68,
                borderRadius: "22px",
                background: "rgba(34, 197, 94, 0.15)",
                border: "1px solid rgba(34, 197, 94, 0.3)",
                color: "#4ade80",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                margin: "0 auto 20px",
                boxShadow: "0 0 30px rgba(34, 197, 94, 0.2)"
              }}
            >
              <CheckCircle2 size={36} />
            </div>

            <h3 style={{ fontSize: "22px", fontWeight: 800, color: "#ffffff", marginBottom: "10px" }}>
              {isAr ? "تم تحديث كلمة المرور بنجاح!" : "Password Updated Successfully!"}
            </h3>

            <p style={{ color: "rgba(255, 255, 255, 0.7)", fontSize: "14px", lineHeight: "1.6", marginBottom: "28px" }}>
              {isAr
                ? "تم حفظ كلمة المرور الجديدة وإغلاق جلسة الاستعادة بأمان. يمكنك الآن تسجيل الدخول بحسابك."
                : "Your new password has been saved securely. You can now log in with your new credentials."}
            </p>

            <Link
              href="/login"
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "8px",
                width: "100%",
                padding: "14px",
                borderRadius: "14px",
                background: "linear-gradient(135deg, #16a34a, #15803d)",
                color: "#ffffff",
                fontWeight: 700,
                fontSize: "15px",
                textDecoration: "none",
                boxShadow: "0 10px 25px -5px rgba(22, 163, 74, 0.4)",
                transition: "transform 0.2s ease"
              }}
            >
              <span>{isAr ? "تسجيل الدخول الآن" : "Sign In Now"}</span>
              <ArrowIcon size={16} />
            </Link>
          </div>
        ) : (
          /* Form Screen */
          <div>
            {/* Header Title */}
            <div style={{ display: "flex", alignItems: "center", gap: "14px", marginBottom: "24px" }}>
              <div
                style={{
                  width: "48px",
                  height: "48px",
                  borderRadius: "14px",
                  background: "linear-gradient(135deg, rgba(99, 102, 241, 0.2), rgba(168, 85, 247, 0.2))",
                  border: "1px solid rgba(99, 102, 241, 0.3)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "#818cf8",
                  flexShrink: 0
                }}
              >
                <KeyRound size={24} />
              </div>
              <div>
                <h2 style={{ fontSize: "20px", fontWeight: 800, color: "#ffffff", margin: 0 }}>
                  {isAr ? "إعادة تعيين كلمة المرور" : "Reset Your Password"}
                </h2>
                <p style={{ fontSize: "13px", color: "rgba(255, 255, 255, 0.55)", margin: "4px 0 0" }}>
                  {isAr ? "قم بإدخال كلمة المرور الجديدة لحسابك" : "Enter a new secure password for your account"}
                </p>
              </div>
            </div>

            <form onSubmit={onSubmit}>
              {/* New Password */}
              <div style={{ marginBottom: "20px" }}>
                <label style={{ display: "block", fontSize: "13px", fontWeight: 700, color: "rgba(255, 255, 255, 0.8)", marginBottom: "8px" }}>
                  {isAr ? "كلمة المرور الجديدة" : "New Password"}
                </label>
                <GlassPasswordInput placeholder="••••••••" {...form.register("password")} />
                <PasswordStrengthIndicator password={form.watch("password") || ""} />
                {form.formState.errors.password && (
                  <div style={{ display: "flex", alignItems: "center", gap: "6px", color: "#f87171", fontSize: "12px", marginTop: "6px" }}>
                    <AlertCircle size={14} />
                    <span>{form.formState.errors.password.message}</span>
                  </div>
                )}
              </div>

              {/* Confirm Password */}
              <div style={{ marginBottom: "24px" }}>
                <label style={{ display: "block", fontSize: "13px", fontWeight: 700, color: "rgba(255, 255, 255, 0.8)", marginBottom: "8px" }}>
                  {isAr ? "تأكيد كلمة المرور" : "Confirm Password"}
                </label>
                <GlassPasswordInput placeholder="••••••••" {...form.register("confirmPassword")} />
                {form.formState.errors.confirmPassword && (
                  <div style={{ display: "flex", alignItems: "center", gap: "6px", color: "#f87171", fontSize: "12px", marginTop: "6px" }}>
                    <AlertCircle size={14} />
                    <span>{form.formState.errors.confirmPassword.message}</span>
                  </div>
                )}
              </div>

              {error && (
                <div
                  style={{
                    padding: "12px 14px",
                    borderRadius: "12px",
                    background: "rgba(239, 68, 68, 0.12)",
                    border: "1px solid rgba(239, 68, 68, 0.3)",
                    color: "#fca5a5",
                    fontSize: "13px",
                    marginBottom: "20px",
                    display: "flex",
                    alignItems: "center",
                    gap: "8px"
                  }}
                >
                  <AlertCircle size={16} style={{ flexShrink: 0 }} />
                  <span>{error}</span>
                </div>
              )}

              <button
                type="submit"
                disabled={isUpdating}
                style={{
                  width: "100%",
                  padding: "14px",
                  borderRadius: "14px",
                  background: "linear-gradient(135deg, #4f46e5, #6d28d9)",
                  border: "none",
                  color: "#ffffff",
                  fontSize: "15px",
                  fontWeight: 700,
                  cursor: isUpdating ? "not-allowed" : "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "8px",
                  boxShadow: "0 10px 25px -5px rgba(79, 70, 229, 0.4)",
                  transition: "all 0.2s ease-in-out",
                  opacity: isUpdating ? 0.7 : 1
                }}
              >
                {isUpdating ? (
                  <>
                    <Loader2 className="animate-spin" size={18} />
                    <span>{isAr ? "جاري الحديث..." : "Updating..."}</span>
                  </>
                ) : (
                  <>
                    <ShieldCheck size={18} />
                    <span>{isAr ? "تحديث كلمة المرور" : "Update Password"}</span>
                  </>
                )}
              </button>
            </form>
          </div>
        )}
      </div>
    </div>
  );
}
