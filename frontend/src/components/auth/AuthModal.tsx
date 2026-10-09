"use client";

import React, { useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useForm } from "react-hook-form";
import { z } from "zod";
import { zodResolver } from "@hookform/resolvers/zod";
import { X, AlertCircle, CheckCircle2, Mail, ArrowLeft, ArrowRight } from "lucide-react";

import { api, extractApiError } from "@/lib/api";
import { getCurrentSession, supabase } from "@/lib/supabase";
import { useTranslation } from "@/lib/i18n";
import { GlassPasswordInput } from "@/components/auth/GlassPasswordInput";
import { PasswordStrengthIndicator } from "@/components/auth/PasswordStrengthIndicator";
import { AnimatedVectorHub } from "@/components/auth/AnimatedVectorHub";
import { useAuth } from "@/components/shared/AuthProvider";
import { persistRememberedSession } from "@/lib/rememberedSession";

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

  const [mode, setMode] = useState<'login' | 'register' | 'forgot' | 'verify-otp' | 'update-password'>(initialMode);
  const [showEmailForm, setShowEmailForm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [oauthLoading, setOauthLoading] = useState<string | null>(null);
  const [oauthVerified, setOauthVerified] = useState<string | null>(null);
  const [generalError, setGeneralError] = useState("");
  const [successMsg, setSuccessMsg] = useState("");

  // Recovery & OTP states
  const [resetEmail, setResetEmail] = useState("");
  const [otpDigits, setOtpDigits] = useState<string[]>(["", "", "", "", "", ""]);
  const otpInputRefs = useRef<(HTMLInputElement | null)[]>([]);
  const [resendTimer, setResendTimer] = useState(0);

  // Update password states
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordError, setPasswordError] = useState("");

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
  const onCloseRef = useRef(onClose);

  useEffect(() => {
    onCloseRef.current = onClose;
  }, [onClose]);

  useEffect(() => {
    setMode(initialMode);
    setGeneralError("");
    setSuccessMsg("");
    setShowEmailForm(false);
    setOtpDigits(["", "", "", "", "", ""]);
    setNewPassword("");
    setConfirmPassword("");
    setPasswordError("");
  }, [initialMode, isOpen]);

  useEffect(() => {
    if (resendTimer <= 0) return;
    const interval = setInterval(() => setResendTimer((prev) => prev - 1), 1000);
    return () => clearInterval(interval);
  }, [resendTimer]);

  useEffect(() => {
    if (!isOpen || typeof window === "undefined") return;

    const oauthProvider = sessionStorage.getItem("oauth_in_progress");
    if (!oauthProvider) return;

    let active = true;
    let redirectTimer: ReturnType<typeof setTimeout> | undefined;

    const verifyOAuthAccount = async () => {
      setOauthLoading(oauthProvider);
      setGeneralError("");

      try {
        let session = await getCurrentSession();
        for (let attempt = 0; !session && attempt < 8; attempt += 1) {
          await new Promise((resolve) => setTimeout(resolve, 250));
          session = await getCurrentSession();
        }
        if (!session) {
          throw new Error("NO_SESSION");
        }

        const { data } = await api.get("/auth/me");
        if (!active || !data?.data) return;

        setAuthUser({
          id: data.data.id,
          email: data.data.email,
          fullName: data.data.fullName,
          schoolId: data.data.school?.id,
          role: data.data.role,
          school: data.data.school,
          avatarUrl: session.user.user_metadata?.custom_avatar_url || session.user.user_metadata?.avatar_url,
        });
        setOauthVerified(oauthProvider);
        sessionStorage.removeItem("oauth_in_progress");
        redirectTimer = setTimeout(() => {
          if (!active) return;
          onCloseRef.current();
          router.replace("/dashboard");
        }, 900);
      } catch {
        if (!active) return;
        await supabase.auth.signOut();
        sessionStorage.removeItem("oauth_in_progress");
        setOauthVerified(null);
        setGeneralError(
          isAr
            ? "حساب Google هذا غير مرتبط بحساب EduControl مسجل. سجّل الدخول بالبريد الذي أنشأت به المدرسة، أو أنشئ مدرسة جديدة أولاً."
            : "This Google account is not linked to a registered EduControl school. Sign in with your school email, or register your school first."
        );
      } finally {
        if (active) setOauthLoading(null);
      }
    };

    verifyOAuthAccount();
    return () => {
      active = false;
      if (redirectTimer) clearTimeout(redirectTimer);
    };
  }, [isAr, isOpen, router, setAuthUser]);

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

  useEffect(() => {
    if (typeof window === "undefined") return;
    const rememberedEmail = localStorage.getItem("edu_remembered_email");
    if (rememberedEmail) {
      loginForm.setValue("email", rememberedEmail);
      loginForm.setValue("rememberMe", true);
    }
  }, [loginForm]);

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
  const registerAgreeError = registerForm.formState.errors.agree?.message;

  const switchMode = (nextMode: "login" | "register" | "forgot") => {
    setMode(nextMode);
    setShowEmailForm(nextMode !== "forgot");
    setGeneralError("");
    setSuccessMsg("");
    if (typeof window !== "undefined" && window.location.hash) {
      window.history.replaceState(null, "", `${window.location.pathname}${window.location.search}`);
    }
  };

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

    if (values.rememberMe) localStorage.setItem("edu_remembered_email", values.email);
    else localStorage.removeItem("edu_remembered_email");

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
        const { data: sessionData, error } = await supabase.auth.setSession({
          access_token: loginData.data.session.access_token,
          refresh_token: loginData.data.session.refresh_token
        });
        if (error) throw error;
        if (sessionData.session) persistRememberedSession(sessionData.session, Boolean(values.rememberMe));
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
      const { data } = await api.post("/auth/register", {
        name: values.name,
        email: values.email,
        password: values.password,
        schoolId: values.schoolId
      });

      if (data.data?.session) {
        const { error } = await supabase.auth.setSession({
          access_token: data.data.session.access_token,
          refresh_token: data.data.session.refresh_token
        });
        if (error) throw error;
      }

      sessionStorage.setItem("edu_registration_onboarding", JSON.stringify({ startedAt: Date.now() }));
      onClose();
      router.push("/onboarding");
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

      // Step 2: Send reset password OTP via Supabase
      const { error: resetErr } = await supabase.auth.resetPasswordForEmail(email, {
        redirectTo: `${window.location.origin}/update-password`
      });

      if (resetErr) {
        setGeneralError(resetErr.message);
        return;
      }

      setResetEmail(email);
      setMode('verify-otp');
      setResendTimer(60);
      setSuccessMsg(
        isAr
          ? "تم إرسال رمز التحقق (6 أرقام) إلى بريدك الإلكتروني بنجاح! 📩"
          : "6-digit verification code sent to your email successfully! 📩"
      );
    } catch (err: any) {
      setGeneralError(err.message || "An unexpected error occurred");
    } finally {
      setIsLoading(false);
    }
  });

  // Handle Verify OTP Submit
  const onVerifyOtpSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setGeneralError("");
    setSuccessMsg("");

    const otpCode = otpDigits.join("").trim();
    if (otpCode.length < 6) {
      setGeneralError(isAr ? "يرجى إدخال رمز التحقق المكون من 6 أرقام كاملاً." : "Please enter the complete 6-digit code.");
      return;
    }

    setIsLoading(true);
    try {
      const { error: verifyErr } = await supabase.auth.verifyOtp({
        email: resetEmail,
        token: otpCode,
        type: "recovery"
      });

      if (verifyErr) {
        setGeneralError(verifyErr.message || (isAr ? "رمز التحقق غير صحيح أو انتهت صلاحيته." : "Invalid or expired code."));
        return;
      }

      setGeneralError("");
      setSuccessMsg("");
      setMode('update-password');
    } catch (err: any) {
      setGeneralError(err.message || "Failed to verify code");
    } finally {
      setIsLoading(false);
    }
  };

  // Handle Update Password Submit
  const onUpdatePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setGeneralError("");
    setPasswordError("");

    if (!newPassword || newPassword.length < 6) {
      setPasswordError(isAr ? "كلمة المرور يجب أن تكون 6 أحرف على الأقل." : "Password must be at least 6 characters.");
      return;
    }

    if (newPassword !== confirmPassword) {
      setPasswordError(isAr ? "كلمتا المرور غير متطابقتين." : "Passwords do not match.");
      return;
    }

    setIsLoading(true);
    try {
      const { error: updateErr } = await supabase.auth.updateUser({
        password: newPassword
      });

      if (updateErr) {
        setGeneralError(updateErr.message);
        return;
      }

      await supabase.auth.signOut().catch(() => {});
      if (typeof window !== "undefined") {
        try {
          localStorage.removeItem("edu_auth_user");
          sessionStorage.removeItem("edu_auth_user");
        } catch (_) {}
      }

      setSuccessMsg(
        isAr
          ? "تم تحديث كلمة المرور بنجاح! يمكنك الآن تسجيل الدخول."
          : "Password updated successfully! You can now log in."
      );
      setMode('login');
      setShowEmailForm(true);
      setNewPassword("");
      setConfirmPassword("");
    } catch (err: any) {
      setGeneralError(err.message || "Failed to update password");
    } finally {
      setIsLoading(false);
    }
  };

  // Handle OAuth Sign In
  const handleOAuthSignIn = async (provider: 'google' | 'facebook') => {
    setOauthLoading(provider);
    setOauthVerified(null);
    setGeneralError("");
    try {
      if (typeof window !== "undefined") {
        sessionStorage.setItem("oauth_in_progress", provider);
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
              {mode === 'verify-otp' && (isAr ? "رمز التحقق (6 أرقام)" : "Verification Code (6-digit)")}
              {mode === 'update-password' && (isAr ? "تعيين كلمة المرور الجديدة" : "Set New Password")}
            </h2>
            <p className="sub">
              {mode === 'forgot' && (isAr ? "أدخل بريدك الإلكتروني وسنرسل لك رمز استعادة مكون من 6 أرقام." : "Enter your email to receive a 6-digit recovery code.")}
              {mode === 'verify-otp' && (isAr ? `أدخل الرمز المكون من 6 أرقام المرسل إلى ${resetEmail}` : `Enter the 6-digit code sent to ${resetEmail}`)}
              {mode === 'update-password' && (isAr ? "أدخل كلمة المرور الجديدة لحسابك واضغط حفظ للمتابعة." : "Enter a new secure password for your account.")}
              {['login', 'register'].includes(mode) && (isAr ? "استخدم بريدك أو إحدى الخدمات للمتابعة في EduControl (مجاناً!)" : "Use your email or another service to continue with EduControl (it's free!)")}
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
          {['login', 'register'].includes(mode) && (
            <div className="cv-social-group">
              <button
                type="button"
                className={`cv-social-btn ${oauthVerified === "google" ? "cv-social-btn-success" : ""}`}
                onClick={() => handleOAuthSignIn('google')}
                disabled={!!oauthLoading}
              >
                {oauthVerified === "google" ? <CheckCircle2 size={20} /> : <GoogleIcon />}
                <span>
                  {oauthVerified === "google"
                    ? (isAr ? "تم التحقق من الحساب" : "Account verified")
                    : oauthLoading === "google"
                      ? (isAr ? "جارٍ التحقق من الحساب..." : "Verifying your account...")
                      : (isAr ? "المتابعة باستخدام Google" : "Continue with Google")}
                </span>
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
          {mode === 'forgot' && (
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
                {isLoading ? <span className="cv-spinner-sm" /> : (isAr ? "إرسال رمز التحقق (6 أرقام)" : "Send 6-Digit Code")}
              </button>

              <div className="cv-modal-switch" style={{ marginTop: 14 }}>
                <button
                  type="button"
                  className="cv-switch-btn"
                  onClick={() => switchMode("login")}
                  style={{ display: "inline-flex", alignItems: "center", gap: 6 }}
                >
                  {isAr ? <ArrowRight size={14} /> : <ArrowLeft size={14} />}
                  {isAr ? "الرجوع لتسجيل الدخول" : "Back to Log In"}
                </button>
              </div>
            </form>
          )}

          {/* ── VERIFY OTP FORM ── */}
          {mode === 'verify-otp' && (
            <form onSubmit={onVerifyOtpSubmit} className="cv-form">
              <div className="cv-field">
                <label style={{ textAlign: "center", width: "100%", display: "block" }}>
                  {isAr ? "أدخل الرمز المكون من 6 أرقام" : "Enter the 6-digit code"}
                </label>
                <div style={{ display: "flex", gap: "8px", justifyContent: "center", direction: "ltr", margin: "16px 0" }}>
                  {otpDigits.map((digit, i) => (
                    <input
                      key={i}
                      ref={(el) => { otpInputRefs.current[i] = el; }}
                      type="text"
                      inputMode="numeric"
                      maxLength={1}
                      value={digit}
                      onChange={(e) => {
                        const val = e.target.value.replace(/\D/g, "");
                        const newD = [...otpDigits];
                        newD[i] = val.slice(-1);
                        setOtpDigits(newD);
                        if (val && i < 5) otpInputRefs.current[i + 1]?.focus();
                      }}
                      onKeyDown={(e) => {
                        if (e.key === "Backspace" && !otpDigits[i] && i > 0) {
                          otpInputRefs.current[i - 1]?.focus();
                        }
                      }}
                      onPaste={(e) => {
                        e.preventDefault();
                        const pasted = e.clipboardData.getData("text").replace(/\D/g, "").slice(0, 6);
                        if (pasted) {
                          const newD = [...otpDigits];
                          for (let idx = 0; idx < pasted.length; idx++) {
                            newD[idx] = pasted[idx];
                          }
                          setOtpDigits(newD);
                          otpInputRefs.current[Math.min(pasted.length, 5)]?.focus();
                        }
                      }}
                      style={{
                        width: "44px",
                        height: "52px",
                        borderRadius: "12px",
                        border: digit ? "2px solid #4f46e5" : "1px solid rgba(255, 255, 255, 0.15)",
                        background: "rgba(255, 255, 255, 0.05)",
                        color: "#ffffff",
                        fontSize: "20px",
                        fontWeight: "800",
                        textAlign: "center",
                        outline: "none",
                        transition: "all 0.2s ease"
                      }}
                    />
                  ))}
                </div>
              </div>

              <button type="submit" className={`cv-btn cv-btn-grad cv-btn-block ${isLoading ? "loading" : ""}`}>
                {isLoading ? <span className="cv-spinner-sm" /> : (isAr ? "التحقق ومتابعة التغيير" : "Verify & Continue")}
              </button>

              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginTop: "16px", fontSize: "13px" }}>
                <button
                  type="button"
                  className="cv-switch-btn"
                  onClick={() => { setMode('forgot'); setGeneralError(""); }}
                  style={{ display: "inline-flex", alignItems: "center", gap: 4 }}
                >
                  {isAr ? <ArrowRight size={14} /> : <ArrowLeft size={14} />}
                  {isAr ? "تغيير الإيميل" : "Change Email"}
                </button>

                {resendTimer > 0 ? (
                  <span style={{ color: "rgba(255, 255, 255, 0.5)" }}>
                    {isAr ? `إعادة الإرسال بعد (${resendTimer}s)` : `Resend in (${resendTimer}s)`}
                  </span>
                ) : (
                  <button
                    type="button"
                    className="cv-switch-btn"
                    onClick={onForgotSubmit}
                  >
                    {isAr ? "إعادة إرسال الرمز" : "Resend Code"}
                  </button>
                )}
              </div>
            </form>
          )}

          {/* ── UPDATE PASSWORD FORM ── */}
          {mode === 'update-password' && (
            <form onSubmit={onUpdatePasswordSubmit} className="cv-form">
              <div className="cv-field">
                <label>{isAr ? "كلمة المرور الجديدة" : "New Password"}</label>
                <GlassPasswordInput
                  placeholder="••••••••"
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                />
                <PasswordStrengthIndicator password={newPassword} />
              </div>

              <div className="cv-field">
                <label>{isAr ? "تأكيد كلمة المرور" : "Confirm Password"}</label>
                <GlassPasswordInput
                  placeholder="••••••••"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                />
              </div>

              {passwordError && (
                <div className="cv-field-error" style={{ marginBottom: 12 }}>
                  <AlertCircle size={14} /> {passwordError}
                </div>
              )}

              <button type="submit" className={`cv-btn cv-btn-grad cv-btn-block ${isLoading ? "loading" : ""}`}>
                {isLoading ? <span className="cv-spinner-sm" /> : (isAr ? "حفظ كلمة المرور الجديدة" : "Save New Password")}
              </button>
            </form>
          )}

          {/* ── LOGIN & REGISTER FORMS ── */}
          {['login', 'register'].includes(mode) && (showEmailForm || mode === 'register') && (
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
                      <input type="checkbox" aria-invalid={Boolean(registerAgreeError)} {...registerForm.register("agree")} />
                      <span>
                        {isAr ? "أوافق على " : "I agree to "}
                        <Link href="/terms-and-conditions" className="cv-switch-btn" onClick={(event) => event.stopPropagation()}>
                          {isAr ? "الشروط والأحكام" : "Terms & Conditions"}
                        </Link>
                      </span>
                    </label>
                    {registerAgreeError && <div className="cv-field-error"><AlertCircle size={14} /> {isAr ? "يرجى الموافقة على الشروط والأحكام للمتابعة" : "Please agree to the Terms & Conditions to continue."}</div>}
                  </div>

                  <button type="submit" className={`cv-btn cv-btn-grad cv-btn-block ${isLoading ? "loading" : ""}`}>
                    {isLoading ? <span className="cv-spinner-sm" /> : (isAr ? "إنشاء حساب المدرسة" : "Register School")}
                  </button>
                </form>
              )}
            </div>
          )}

          {/* Toggle between Login and Register */}
          {['login', 'register'].includes(mode) && (
            <div className="cv-modal-switch">
              {mode === 'login' ? (
                <p>
                  {isAr ? "ليس لديك حساب؟ " : "Don't have an account? "}
                  <button
                    type="button"
                    className="cv-switch-btn"
                    onClick={() => switchMode("register")}
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
                    onClick={() => switchMode("login")}
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
