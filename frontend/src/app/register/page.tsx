"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { User, ShieldCheck, Check, X, AlertCircle, CheckCircle2 } from "lucide-react";

import { api, extractApiError } from "@/lib/api";
import { supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
import { AuthShell } from "@/components/auth/AuthShell";
import { GlassPasswordInput } from "@/components/auth/GlassPasswordInput";
import { PasswordStrengthIndicator } from "@/components/auth/PasswordStrengthIndicator";
import { EmailAutocompleteInput } from "@/components/auth/EmailAutocompleteInput";
import { PolicyModal } from "@/components/auth/PolicyModal";

const latinRegex = /^[a-zA-Z0-9\s!@#$%^&*()_+={}\[\]:;"'<>,.?/\\|`~-]+$/;

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email().regex(latinRegex, "English characters only"),
  password: z.string().min(6).regex(latinRegex, "English characters only"),
  schoolId: z.string().min(3, "Invalid School ID").regex(/^[A-Za-z0-9\-_]+$/, "ID must be in English"),
  agree: z.boolean().refine((v) => v === true, "Required")
});

export default function RegisterPage() {
  const { t, isAr } = useTranslation();
  const router = useRouter();
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isSchoolIdValid, setIsSchoolIdValid] = useState<boolean | null>(null);
  const [isCheckingSchoolId, setIsCheckingSchoolId] = useState(false);
  const [isNameValid, setIsNameValid] = useState<boolean | null>(null);
  const [isCheckingName, setIsCheckingName] = useState(false);
  const [isEmailValid, setIsEmailValid] = useState<boolean | null>(null);
  const [isCheckingEmail, setIsCheckingEmail] = useState(false);
  const [showPolicies, setShowPolicies] = useState(false);

  const form = useForm<z.infer<typeof registerSchema>>({
    resolver: zodResolver(registerSchema),
    defaultValues: { agree: false }
  });

  const passwordValue = form.watch("password");
  const schoolIdValue = form.watch("schoolId");
  const nameValue = form.watch("name");
  const emailValue = form.watch("email");

  // Real-time School ID validation
  useEffect(() => {
    if (!schoolIdValue || schoolIdValue.length < 3) {
      setIsSchoolIdValid(null);
      return;
    }
    const timer = setTimeout(async () => {
      setIsCheckingSchoolId(true);
      try {
        const { data } = await api.get(`/auth/check-school-id/${schoolIdValue}`);
        setIsSchoolIdValid(data.data.available);
      } catch (err) {
        setIsSchoolIdValid(null);
      } finally {
        setIsCheckingSchoolId(false);
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [schoolIdValue]);

  // Real-time School Name validation
  useEffect(() => {
    if (!nameValue || nameValue.length < 2) {
      setIsNameValid(null);
      return;
    }
    const timer = setTimeout(async () => {
      setIsCheckingName(true);
      try {
        const { data } = await api.get(`/auth/check-school-name/${nameValue}`);
        setIsNameValid(data.data.available);
      } catch (err) {
        setIsNameValid(null);
      } finally {
        setIsCheckingName(false);
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [nameValue]);

  // Real-time School Email validation
  useEffect(() => {
    if (!emailValue || !emailValue.includes("@")) {
      setIsEmailValid(null);
      return;
    }
    const timer = setTimeout(async () => {
      setIsCheckingEmail(true);
      try {
        const { data } = await api.get(`/auth/check-school-email/${emailValue}`);
        setIsEmailValid(data.data.available);
      } catch (err) {
        setIsEmailValid(null);
      } finally {
        setIsCheckingEmail(false);
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [emailValue]);

  const [showIntro, setShowIntro] = useState(false);

  const onSubmit = form.handleSubmit(async (values) => {
    setError("");
    setSuccess("");

    if (isSchoolIdValid === false) {
      setError("This School ID is already taken.");
      return;
    }
    if (isNameValid === false) {
      setError("This Institution Name is already registered.");
      return;
    }
    if (isEmailValid === false) {
      setError("This School Email is already registered.");
      return;
    }

    setIsLoading(true);

    try {
      const { data: regData } = await api.post("/auth/register", {
        name: values.name,
        email: values.email,
        password: values.password,
        schoolId: values.schoolId
      });

      // Set session immediately
      if (regData.data?.session) {
        await supabase.auth.setSession({
          access_token: regData.data.session.access_token,
          refresh_token: regData.data.session.refresh_token
        });
      }

      // Flag to play intro video in dashboard layout
      localStorage.setItem("play_intro", "true");

      setSuccess(t('auth_created'));
      setTimeout(() => router.push("/dashboard"), 20000);
    } catch (err: any) {
      const apiErr = extractApiError(err);
      setError(apiErr.message);
    } finally {
      setIsLoading(false);
    }
  });

  return (
    <AuthShell
      variant="register"
      title={t('auth_register_title')}
      subtitle={t('auth_register_subtitle')}
    >
      <form onSubmit={onSubmit}>
        {success && (
          <div className="glass-success-overlay" style={{ textAlign: "center", padding: "40px 20px" }}>
            <div className="success-icon-shine" style={{ marginBottom: "24px" }}>
              <CheckCircle2 size={64} color="#10b981" />
            </div>
            <h3 style={{ fontSize: "22px", fontWeight: 700, marginBottom: "12px", color: "#fff" }}>{t('auth_created')}</h3>

            <p style={{ color: "rgba(255,255,255,0.7)", fontSize: "14px", marginBottom: "24px" }}>
              {isAr ? "جاري تحويلك إلى لوحة التحكم..." : "Redirecting to your dashboard..."}
            </p>

            <div className="premium-progress-container">
              <div className="premium-progress-bar"></div>
            </div>
          </div>
        )}
        {!success && (
          <>
            <div className="glass-input-group">
              <label>{t('field_school_name')}</label>
              <div className={`glass-input-wrapper ${isNameValid === false ? "input-error" : ""}`} style={{ position: "relative" }}>
                <User className="glass-input-icon" size={18} />
                <input placeholder="Enter school name" {...form.register("name")} />
                <div className="school-id-status">
                  {isCheckingName && <div className="spinner-mini" />}
                  {!isCheckingName && isNameValid === true && <Check size={16} color="#10b981" />}
                  {!isCheckingName && isNameValid === false && <X size={16} color="#ef4444" />}
                </div>
              </div>
              {isNameValid === false && (
                <div className="field-error-inline error-shake">
                  <AlertCircle size={14} />
                  <span>{t('err_name_taken')}</span>
                </div>
              )}
            </div>

            <div className="glass-input-group">
              <label>{t('field_school_email')}</label>
              <EmailAutocompleteInput
                name="email"
                placeholder="name@email.com"
                register={form.register}
                setValue={form.setValue}
                watch={form.watch}
                isLoading={isCheckingEmail}
                isValid={isEmailValid}
                isError={isEmailValid === false}
              />
              {form.formState.errors.email && (
                <div className="field-error-inline error-shake">
                  <AlertCircle size={14} />
                  <span>{t('err_english_only')}</span>
                </div>
              )}
              {isEmailValid === false && !form.formState.errors.email && (
                <div className="field-error-inline error-shake">
                  <AlertCircle size={14} />
                  <span>{t('err_email_taken')}</span>
                </div>
              )}
            </div>

            <div className="glass-input-group">
              <label>{t('field_password_new')}</label>
              <GlassPasswordInput placeholder={t('field_password_placeholder')} {...form.register("password")} />
              {form.formState.errors.password && (
                <div className="field-error-inline error-shake">
                  <AlertCircle size={14} />
                  <span>{t('err_english_only')}</span>
                </div>
              )}
              <PasswordStrengthIndicator password={passwordValue} />
            </div>

            <div className="glass-input-group">
              <label>{t('field_school_id')}</label>
              <div className={`glass-input-wrapper ${isSchoolIdValid === false || form.formState.errors.schoolId ? "input-error" : ""}`} style={{ position: "relative" }}>
                <ShieldCheck className="glass-input-icon" size={18} />
                <input placeholder="Enter unique school ID" {...form.register("schoolId")} />
                <div className="school-id-status">
                  {isCheckingSchoolId && <div className="spinner-mini" />}
                  {!isCheckingSchoolId && isSchoolIdValid === true && <Check size={16} color="#10b981" />}
                  {!isCheckingSchoolId && isSchoolIdValid === false && <X size={16} color="#ef4444" />}
                </div>
              </div>
              {form.formState.errors.schoolId && (
                <div className="field-error-inline error-shake">
                  <AlertCircle size={14} />
                  <span>{t('err_english_only')}</span>
                </div>
              )}
              {isSchoolIdValid === false && !form.formState.errors.schoolId && (
                <div className="field-error-inline error-shake">
                  <AlertCircle size={14} />
                  <span>{t('err_id_taken')}</span>
                </div>
              )}
            </div>

            <div style={{ marginBottom: "24px" }}>
              <label
                className="checkbox-row"
                style={{
                  color: form.formState.errors.agree ? "#ef4444" : "rgba(255,255,255,0.6)",
                  display: "flex",
                  alignItems: "center",
                  gap: "8px",
                  cursor: "pointer"
                }}
              >
                <input type="checkbox" {...form.register("agree")} />

                <span style={{ fontSize: "14px" }}>
                  {t('auth_agree_policies')}{" "}
                  <button
                    type="button"
                    className="glass-link"
                    style={{ background: "none", border: "none", padding: 0, font: "inherit", cursor: "pointer" }}
                    onClick={() => setShowPolicies(true)}
                  >
                    {t('auth_institutional_policies')}
                  </button>
                </span>
              </label>
              {form.formState.errors.agree && (
                <div className="field-error-inline error-shake">
                  <AlertCircle size={14} />
                  <span>{t('err_agree_required')}</span>
                </div>
              )}
            </div>

            {error && <p className="error error-shake" style={{ marginBottom: "16px" }}>{error}</p>}

            <button
              type="submit"
              disabled={isLoading || isCheckingSchoolId}
              className={`btn-glass-primary ${isLoading ? "btn-loading" : ""}`}
            >
              {isLoading ? t('btn_creating_account') : t('btn_create_account')}
            </button>
          </>
        )}
      </form>

      <PolicyModal
        isOpen={showPolicies}
        onClose={() => setShowPolicies(false)}
        onAccept={() => form.setValue("agree", true, { shouldValidate: true })}
      />

      <p className="auth-bottom" style={{ color: "rgba(255,255,255,0.5)", marginTop: "24px", textAlign: "center" }}>
        {t('auth_have_account')} <Link className="glass-link" href="/login" style={{ fontWeight: 700, color: "#fff" }}>{t('nav_signin')}</Link>
      </p>
    </AuthShell>
  );
}
