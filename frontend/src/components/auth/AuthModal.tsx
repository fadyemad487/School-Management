"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { X, AlertCircle, CheckCircle2, Mail, ArrowLeft, ArrowRight } from "lucide-react";

import { api, extractApiError } from "@/lib/api";
import { supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
import { GlassPasswordInput } from "@/components/auth/GlassPasswordInput";
import { PasswordStrengthIndicator } from "@/components/auth/PasswordStrengthIndicator";
import { AnimatedVectorHub } from "@/components/auth/AnimatedVectorHub";
import { useAuth } from "@/components/shared/AuthProvider";

/* ── SVG Icons ── */
const BrandIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="28" height="28">
    <path d="M12 3l9 4.5-9 4.5-9-4.5L12 3z" stroke="#fff" strokeWidth="1.6" strokeLinejoin="round"/>
    <path d="M6 10.5V16c0 1.5 2.7 3 6 3s6-1.5 6-3v-5.5" stroke="#fff" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round"/>
  </svg>
);

const GoogleIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20">
    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4" />
    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" />
    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" />
    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" />
  </svg>
);

const FacebookIcon = () => (
  <svg viewBox="0 0 24 24" width="20" height="20" fill="#1877F2">
    <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" />
  </svg>
);

/* ── Validation Schemas ── */
const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  rememberMe: z.boolean().optional()
});

const latinRegex = /^[a-zA-Z0-9\s!@#$%^&*()_+={}\[\]:;"'<>,.?/\\|`~-]+$/;

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email().regex(latinRegex, "English characters only"),
  password: z.string().min(6).regex(latinRegex, "English characters only"),
  schoolId: z.string().min(3, "Invalid School ID").regex(/^[A-Za-z0-9\-_]+$/, "ID must be in English"),
  agree: z.boolean().refine((v) => v === true, "Required")
});

const forgotSchema = z.object({
  email: z.string().email()
});

interface AuthModalProps {
  isOpen: boolean;
  initialMode?: 'login' | 'register' | 'forgot';
  onClose: () => void;
}

export function AuthModal({ isOpen, initialMode = 'login', onClose }: AuthModalProps) {
  const { t, isAr } = useTranslation();
  const router = useRouter();
  const { setAuthUser } = useAuth();

  const [mode, setMode] = useState<'login' | 'register' | 'forgot'>(initialMode);
  const [showEmailForm, setShowEmailForm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [oauthLoading, setOauthLoading] = useState<string | null>(null);
  const [generalError, setGeneralError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  // Login field errors
  const [loginEmailError, setLoginEmailError] = useState("");
  const [loginPasswordError, setLoginPasswordError] = useState("");

  // Register real-time checks
  const [isSchoolIdValid, setIsSchoolIdValid] = useState<boolean | null>(null);
  const [isCheckingSchoolId, setIsCheckingSchoolId] = useState(false);

  const [isNameValid, setIsNameValid] = useState<boolean | null>(null);
  const [isCheckingName, setIsCheckingName] = useState(false);

  const [isEmailValid, setIsEmailValid] = useState<boolean | null>(null);
  const [isCheckingEmail, setIsCheckingEmail] = useState(false);

  useEffect(() => {
    setMode(initialMode);
    setGeneralError("");
    setSuccessMsg("");
    setShowEmailForm(false);
  }, [initialMode, isOpen]);

  // Prevent background scroll when modal is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "auto";
    }
    return () => {
      document.body.style.overflow = "auto";
    };
  }, [isOpen]);

  // Login Form
  const loginForm = useForm<z.infer<typeof loginSchema>>({
    resolver: zodResolver(loginSchema),
    defaultValues: { email: "", password: "", rememberMe: false }
  });

  // Register Form
  const registerForm = useForm<z.infer<typeof registerSchema>>({
    resolver: zodResolver(registerSchema),
    defaultValues: { name: "", email: "", password: "", schoolId: "", agree: false }
  });

  // Forgot Password Form
  const forgotForm = useForm<z.infer<typeof forgotSchema>>({
    resolver: zodResolver(forgotSchema),
    defaultValues: { email: "" }
  });

  const registerSchoolId = registerForm.watch("schoolId");
  const registerName = registerForm.watch("name");
  const registerEmail = registerForm.watch("email");
  const registerPassword = registerForm.watch("password");

  // Real-time School ID check
  useEffect(() => {
    if (!registerSchoolId || registerSchoolId.length < 3) {
      setIsSchoolIdValid(null);
      return;
    }
    const timer = setTimeout(async () => {
      setIsCheckingSchoolId(true);
      try {
        const { data } = await api.get(`/auth/check-school-id/${registerSchoolId}`);
        setIsSchoolIdValid(data.data.available);
      } catch (err) {
        setIsSchoolIdValid(null);
      } finally {
        setIsCheckingSchoolId(false);
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [registerSchoolId]);

  // Real-time School Name check
  useEffect(() => {
    if (!registerName || registerName.length < 2) {
      setIsNameValid(null);
      return;
    }
    const timer = setTimeout(async () => {
      setIsCheckingName(true);
      try {
        const { data } = await api.get(`/auth/check-school-name/${encodeURIComponent(registerName)}`);
        setIsNameValid(data.data.available);
      } catch (err) {
        setIsNameValid(null);
      } finally {
        setIsCheckingName(false);
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [registerName]);

  // Real-time School Email check
  useEffect(() => {
    if (!registerEmail || !registerEmail.includes("@")) {
      setIsEmailValid(null);
      return;
    }
    const timer = setTimeout(async () => {
      setIsCheckingEmail(true);
      try {
        const { data } = await api.get(`/auth/check-school-email/${encodeURIComponent(registerEmail)}`);
        setIsEmailValid(data.data.available);
      } catch (err) {
        setIsEmailValid(null);
      } finally {
        setIsCheckingEmail(false);
      }
    }, 500);
    return () => clearTimeout(timer);
  }, [registerEmail]);

  // Handle Login Submit
  const onLoginSubmit = loginForm.handleSubmit(async (values) => {
    setLoginEmailError("");
    setLoginPasswordError("");
    setGeneralError("");
    setIsLoading(true);

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

      onClose();
      router.push("/dashboard");
    } catch (err: unknown) {
      const apiErr = extractApiError(err);
      const localizedMessage = t(apiErr.code as any) !== apiErr.code ? t(apiErr.code as any) : apiErr.message;

      if (apiErr.field === "email") setLoginEmailError(localizedMessage);
      else if (apiErr.field === "password") setLoginPasswordError(localizedMessage);
      else setGeneralError(localizedMessage);
    } finally {
      setIsLoading(false);
    }
  });

  // Handle Register Submit
  const onRegisterSubmit = registerForm.handleSubmit(async (values) => {
    setGeneralError("");
    setSuccessMsg("");

    if (isEmailValid === false) {
      setGeneralError(isAr ? "البريد الإلكتروني مسجل بالفعل لدينا" : "Email is already registered");
      return;
    }
    if (isSchoolIdValid === false) {
      setGeneralError(isAr ? "معرف المدرسة مستخدم بالفعل" : "School ID is already taken");
      return;
    }

    setIsLoading(true);

    try {
      const { data } = await api.post("/auth/register-school", {
        name: values.name,
        email: values.email,
        password: values.password,
        schoolId: values.schoolId
      });

      setSuccessMsg(isAr ? "تم إنشاء الحساب بنجاح! جاري التوجيه..." : "Account created successfully! Redirecting...");

      if (data.data?.session) {
        await supabase.auth.setSession({
          access_token: data.data.session.access_token,
          refresh_token: data.data.session.refresh_token
        });
      }

      setTimeout(() => {
        onClose();
        router.push("/dashboard");
      }, 1500);
    } catch (err: unknown) {
      const apiErr = extractApiError(err);
      const localizedMessage = t(apiErr.code as any) !== apiErr.code ? t(apiErr.code as any) : apiErr.message;
      setGeneralError(localizedMessage);
    } finally {
      setIsLoading(false);
    }
  });

  // Handle Forgot Password Submit
  const onForgotSubmit = forgotForm.handleSubmit(async ({ email }) => {
    setGeneralError("");
    setSuccessMsg("");
    setIsLoading(true);

    try {
      // Step 1: Check if email is registered
      const checkRes = await api.get(`/auth/check-school-email/${encodeURIComponent(email)}`);
      if (checkRes.data?.data?.available) {
        setGeneralError(
          isAr
            ? "هذا البريد الإلكتروني غير مسجل لدينا. الرجاء التأكد من كتابته بشكل صحيح."
            : "This email is not registered. Please check and try again."
        );
        return;
      }

      // Step 2: Send reset password link via Supabase
      const { error: resetErr } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/update-password`
      });

      if (resetErr) {
        setGeneralError(resetErr.message);
        return;
      }

      setSuccessMsg(
        isAr
          ? "تم إرسال رابط استعادة كلمة السر إلى بريدك الإلكتروني بنجاح! 📩"
          : "Recovery link sent to your email successfully! 📩"
      );
    } catch (err: any) {
      setGeneralError(err.message || "An unexpected error occurred");
    } finally {
      setIsLoading(false);
    }
  });

  // Handle OAuth Sign In
  const handleOAuthSignIn = async (provider: 'google' | 'facebook') => {
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

  if (!isOpen) return null;

  return (
    <div className="cv-modal-backdrop" onClick={(e) => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="cv-modal-dialog" role="dialog" aria-modal="true">
        {/* Close Button */}
        <button className="cv-modal-close" onClick={onClose} type="button" aria-label="Close">
          <X size={20} />
        </button>

        {/* ── Left Side: Form Column ── */}
        <div className="cv-modal-left">
          <div className="cv-modal-header">
            <h2 className="disp">
              {mode === 'login' && (isAr ? "تسجيل الدخول إلى EduControl" : "Log in to EduControl")}
              {mode === 'register' && (isAr ? "تسجيل الدخول أو إنشاء حساب خلال ثوانٍ" : "Log in or sign up in seconds")}
              {mode === 'forgot' && (isAr ? "استرجاع كلمة السر" : "Reset your password")}
            </h2>
            <p className="sub">
              {mode === 'forgot'
                ? (isAr ? "أدخل بريدك الإلكتروني وسنرسل لك رابطاً لاستعادة حسابك." : "Enter your email to receive a password reset link.")
                : (isAr ? "استخدم بريدك أو إحدى الخدمات للمتابعة في EduControl (مجاناً!)" : "Use your email or another service to continue with EduControl (it's free!)")}
            </p>
          </div>

          {generalError && (
            <div className="cv-error" role="alert">
              <AlertCircle size={16} style={{ display: "inline", marginInlineEnd: 6 }} /> {generalError}
            </div>
          )}

          {successMsg && (
            <div className="cv-success" style={{ color: "#22B573", fontSize: "0.88rem", fontWeight: 700, marginBottom: 14, textAlign: "center" }}>
              <CheckCircle2 size={16} style={{ display: "inline", marginInlineEnd: 6 }} /> {successMsg}
            </div>
          )}

          {/* Social Logins (Only for Login & Register) */}
          {mode !== 'forgot' && (
            <div className="cv-social-group">
              <button
                type="button"
                className="cv-social-btn"
                onClick={() => handleOAuthSignIn('google')}
                disabled={!!oauthLoading}
              >
                <GoogleIcon />
                <span>{isAr ? "المتابعة باستخدام Google" : "Continue with Google"}</span>
              </button>

              <button
                type="button"
                className="cv-social-btn"
                onClick={() => handleOAuthSignIn('facebook')}
                disabled={!!oauthLoading}
              >
                <FacebookIcon />
                <span>{isAr ? "المتابعة باستخدام Facebook" : "Continue with Facebook"}</span>
              </button>

              {!showEmailForm && (
                <button
                  type="button"
                  className="cv-social-btn cv-social-btn-email"
                  onClick={() => setShowEmailForm(true)}
                >
                  <Mail size={18} />
                  <span>{isAr ? "المتابعة باستخدام البريد الإلكتروني" : "Continue with email"}</span>
                </button>
              )}
            </div>
          )}

          {/* ── FORGOT PASSWORD FORM ── */}
          {mode === 'forgot' ? (
            <form onSubmit={onForgotSubmit} className="cv-form">
              <div className="cv-field">
                <label>{isAr ? "البريد الإلكتروني المسجل" : "Registered Email Address"}</label>
                <input
                  type="email"
                  placeholder="admin@school.edu"
                  {...forgotForm.register("email")}
                />
              </div>

              <button type="submit" className={`cv-btn cv-btn-grad cv-btn-block ${isLoading ? "loading" : ""}`}>
                {isLoading ? <span className="cv-spinner-sm" /> : (isAr ? "إرسال رابط الاستعادة" : "Send Recovery Link")}
              </button>

              <div className="cv-modal-switch" style={{ marginTop: 14 }}>
                <button
                  type="button"
                  className="cv-switch-btn"
                  onClick={() => { setMode('login'); setGeneralError(""); setSuccessMsg(""); }}
                  style={{ display: "inline-flex", alignItems: "center", gap: 6 }}
                >
                  {isAr ? <ArrowRight size={14} /> : <ArrowLeft size={14} />}
                  {isAr ? "الرجوع لتسجيل الدخول" : "Back to Log In"}
                </button>
              </div>
            </form>
          ) : (
            /* ── LOGIN & REGISTER FORMS ── */
            (showEmailForm || mode === 'register') && (
              <div className="cv-email-form-wrap">
                <div className="cv-divider">
                  <span>{isAr ? "أو أدخل بياناتك" : "or enter your details"}</span>
                </div>

                {mode === 'login' ? (
                  /* LOGIN FORM */
                  <form onSubmit={onLoginSubmit} className="cv-form">
                    <div className="cv-field">
                      <label>{isAr ? "البريد الإلكتروني" : "Email Address"}</label>
                      <input
                        type="email"
                        placeholder="name@school.edu"
                        {...loginForm.register("email")}
                      />
                      {loginEmailError && <div className="cv-field-error"><AlertCircle size={14} /> {loginEmailError}</div>}
                    </div>

                    <div className="cv-field">
                      <label>{isAr ? "كلمة المرور" : "Password"}</label>
                      <GlassPasswordInput
                        {...loginForm.register("password")}
                        placeholder="••••••••"
                      />
                      {loginPasswordError && <div className="cv-field-error"><AlertCircle size={14} /> {loginPasswordError}</div>}
                    </div>

                    <div className="cv-field-row">
                      <label className="cv-checkbox-label">
                        <input type="checkbox" {...loginForm.register("rememberMe")} />
                        {isAr ? "تذكرني" : "Remember me"}
                      </label>
                      <button
                        type="button"
                        className="cv-forgot-link"
                        onClick={() => { setMode('forgot'); setGeneralError(""); setSuccessMsg(""); }}
                        style={{ background: "none", border: "none", cursor: "pointer", fontFamily: "inherit" }}
                      >
                        {isAr ? "نسيت كلمة السر؟" : "Forgot password?"}
                      </button>
                    </div>

                    <button type="submit" className={`cv-btn cv-btn-grad cv-btn-block ${isLoading ? "loading" : ""}`}>
                      {isLoading ? <span className="cv-spinner-sm" /> : (isAr ? "تسجيل الدخول" : "Log In")}
                    </button>
                  </form>
                ) : (
                  /* REGISTER FORM */
                  <form onSubmit={onRegisterSubmit} className="cv-form">
                    <div className="cv-field">
                      <label>{isAr ? "اسم المدرسة" : "School Name"}</label>
                      <input
                        type="text"
                        placeholder={isAr ? "مثال: مدرسة الأمل الخاصة" : "e.g. Al-Amal School"}
                        {...registerForm.register("name")}
                      />
                      {isCheckingName && <span className="cv-checking-hint">{isAr ? "جاري التحقق من الاسم..." : "Checking name..."}</span>}
                      {isNameValid === false && <div className="cv-field-error"><AlertCircle size={14} /> {isAr ? "اسم المدرسة مسجل بالفعل" : "School name already registered"}</div>}
                    </div>

                    <div className="cv-field">
                      <label>{isAr ? "البريد الإلكتروني للمدرسة" : "School Email"}</label>
                      <input
                        type="email"
                        placeholder="admin@school.com"
                        {...registerForm.register("email")}
                      />
                      {isCheckingEmail && <span className="cv-checking-hint">{isAr ? "جاري التحقق من البريد..." : "Checking email..."}</span>}
                      {isEmailValid === true && <div className="cv-field-success" style={{ color: "#22B573", fontSize: "0.82rem", fontWeight: 600, marginTop: 4 }}>✓ {isAr ? "البريد متاح" : "Email available"}</div>}
                      {isEmailValid === false && <div className="cv-field-error"><AlertCircle size={14} /> {isAr ? "البريد الإلكتروني مسجل بالفعل" : "Email already registered"}</div>}
                    </div>

                    <div className="cv-field">
                      <label>{isAr ? "معرف المدرسة (School ID)" : "School ID (Short code)"}</label>
                      <input
                        type="text"
                        placeholder="e.g. alamal-school"
                        {...registerForm.register("schoolId")}
                      />
                      {isCheckingSchoolId && <span className="cv-checking-hint">{isAr ? "جاري التحقق من المعرف..." : "Checking ID..."}</span>}
                      {isSchoolIdValid === true && <div className="cv-field-success" style={{ color: "#22B573", fontSize: "0.82rem", fontWeight: 600, marginTop: 4 }}>✓ {isAr ? "المعرف متاح" : "ID is available"}</div>}
                      {isSchoolIdValid === false && <div className="cv-field-error"><AlertCircle size={14} /> {isAr ? "المعرف مستخدم بالفعل" : "ID already taken"}</div>}
                    </div>

                    <div className="cv-field">
                      <label>{isAr ? "كلمة المرور" : "Password"}</label>
                      <GlassPasswordInput
                        {...registerForm.register("password")}
                        placeholder="••••••••"
                      />
                      <PasswordStrengthIndicator password={registerPassword || ""} />
                    </div>

                    <div className="cv-field-row">
                      <label className="cv-checkbox-label">
                        <input type="checkbox" {...registerForm.register("agree")} />
                        <span>{isAr ? "أوافق على الشروط والأحكام" : "I agree to Terms & Conditions"}</span>
                      </label>
                    </div>

                    <button type="submit" className={`cv-btn cv-btn-grad cv-btn-block ${isLoading ? "loading" : ""}`}>
                      {isLoading ? <span className="cv-spinner-sm" /> : (isAr ? "إنشاء حساب المدرسة" : "Register School")}
                    </button>
                  </form>
                )}
              </div>
            )
          )}

          {/* Toggle between Login and Register */}
          {mode !== 'forgot' && (
            <div className="cv-modal-switch">
              {mode === 'login' ? (
                <p>
                  {isAr ? "ليس لديك حساب؟ " : "Don't have an account? "}
                  <button
                    type="button"
                    className="cv-switch-btn"
                    onClick={() => { setMode('register'); setShowEmailForm(true); setGeneralError(""); setSuccessMsg(""); }}
                  >
                    {isAr ? "إنشاء حساب مجاني" : "Sign up free"}
                  </button>
                </p>
              ) : (
                <p>
                  {isAr ? "لديك حساب بالفعل؟ " : "Already have an account? "}
                  <button
                    type="button"
                    className="cv-switch-btn"
                    onClick={() => { setMode('login'); setShowEmailForm(true); setGeneralError(""); setSuccessMsg(""); }}
                  >
                    {isAr ? "تسجيل الدخول" : "Log in"}
                  </button>
                </p>
              )}
            </div>
          )}

          <p className="cv-modal-footer-notice">
            {isAr
              ? "بمتابعتك، فإنك توافق على شروط الاستخدام وسياسة الخصوصية الخاصة بـ EduControl."
              : "By continuing, you agree to EduControl's Terms of Use & Privacy Policy."}
          </p>
        </div>

        {/* ── Right Side: Animated Vector Hub Graphic Panel ── */}
        <div className="cv-modal-right">
          <AnimatedVectorHub />
        </div>
      </div>
    </div>
  );
}
