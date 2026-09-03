"use client";

import { useMemo, useState, useEffect } from "react";
import { useSearchParams, useRouter, usePathname } from "next/navigation";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import {
  Settings,
  Calendar,
  Clock,
  CheckCircle2,
  AlertCircle,
  Save,
  ShieldCheck,
  Building2,
  Image as ImageIcon,
  KeyRound,
  Lock,
  Video,
  CalendarCheck,
  Loader2,
  Eye,
  EyeOff
} from "lucide-react";
import { supabase } from "@/lib/supabase";
import { useAuth } from "@/components/shared/AuthProvider";
import { LinkIcon, Unlink } from "lucide-react";

// ─── OAuth Provider SVG Icons ──────────────────────────────────
const GoogleIconSmall = () => (
  <svg viewBox="0 0 24 24" width="22" height="22"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4" /><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853" /><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05" /><path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335" /></svg>
);
const FacebookIconSmall = () => (
  <svg viewBox="0 0 24 24" width="22" height="22" fill="#1877F2"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z" /></svg>
);
const AppleIconSmall = () => (
  <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" /></svg>
);

// ─── Linked Accounts Section Component ─────────────────────────
function LinkedAccountsSection({ isAr }: { isAr: boolean }) {
  const [identities, setIdentities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  const providers = [
    { id: 'google', name: 'Google', icon: <GoogleIconSmall />, color: '#4285F4', bg: 'rgba(66, 133, 244, 0.1)', border: 'rgba(66, 133, 244, 0.3)' },
    { id: 'facebook', name: 'Facebook', icon: <FacebookIconSmall />, color: '#1877F2', bg: 'rgba(24, 119, 242, 0.1)', border: 'rgba(24, 119, 242, 0.3)' },
    { id: 'apple', name: 'Apple', icon: <AppleIconSmall />, color: 'var(--glass-text-primary)', bg: 'rgba(255,255,255,0.05)', border: 'var(--glass-border)' },
  ];

  const fetchIdentities = async () => {
    try {
      const { data, error } = await supabase.auth.getUserIdentities();
      if (!error && data?.identities) {
        setIdentities(data.identities);
      }
    } catch (err) {
      console.error("Failed to fetch identities:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchIdentities();
  }, []);

  const isLinked = (provider: string) => {
    return identities.some((i: any) => i.provider === provider);
  };

  const handleLink = async (provider: string) => {
    setActionLoading(provider);
    try {
      const { error } = await supabase.auth.linkIdentity({
        provider: provider as any,
        options: {
          redirectTo: `${window.location.origin}/dashboard/settings?tab=account`,
        }
      });
      if (error) {
        alert(`❌ ${error.message}`);
      }
      // On success, user is redirected to provider, then back. fetchIdentities runs on mount.
    } catch (err: any) {
      alert(`❌ ${err.message}`);
    } finally {
      setActionLoading(null);
    }
  };

  const handleUnlink = async (provider: string) => {
    const identity = identities.find((i: any) => i.provider === provider);
    if (!identity) return;

    // Don't allow unlinking if it's the only identity
    if (identities.length <= 1) {
      alert(isAr ? "لا يمكن إلغاء ربط آخر طريقة دخول. يجب أن يكون لديك طريقة واحدة على الأقل." : "Cannot unlink your only sign-in method. You must have at least one.");
      return;
    }

    setActionLoading(provider);
    try {
      const { error } = await supabase.auth.unlinkIdentity(identity);
      if (error) {
        alert(`❌ ${error.message}`);
      } else {
        await supabase.auth.refreshSession();
        await fetchIdentities();
      }
    } catch (err: any) {
      alert(`❌ ${err.message}`);
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div style={{ marginBottom: "48px", borderBottom: "1px solid var(--glass-border)", paddingBottom: "48px" }}>
      <h4 style={{ fontSize: "18px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "8px", textAlign: isAr ? "right" : "left" }}>
        {isAr ? "الحسابات المرتبطة" : "Linked Accounts"}
      </h4>
      <p style={{ color: "var(--glass-text-secondary)", fontSize: "14px", marginBottom: "24px", textAlign: isAr ? "right" : "left" }}>
        {isAr ? "اربط حساباتك الخارجية لتتمكن من تسجيل الدخول بسرعة عبر Google أو Facebook أو Apple." : "Link your external accounts to enable quick sign-in via Google, Facebook, or Apple."}
      </p>

      {loading ? (
        <div style={{ textAlign: "center", padding: "24px", color: "var(--glass-text-muted)" }}>
          <Loader2 className="animate-spin" size={24} style={{ margin: "0 auto" }} />
        </div>
      ) : (
        <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
          {providers.map(p => {
            const linked = isLinked(p.id);
            const isActionLoading = actionLoading === p.id;
            return (
              <div key={p.id} style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "16px 20px",
                borderRadius: "16px",
                background: linked ? p.bg : "var(--glass-icon-bg)",
                border: `1px solid ${linked ? p.border : "var(--glass-border)"}`,
                transition: "all 0.3s ease",
                flexDirection: isAr ? "row-reverse" : "row",
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: "14px", flexDirection: isAr ? "row-reverse" : "row" }}>
                  <div style={{
                    width: "44px", height: "44px", borderRadius: "12px",
                    background: linked ? p.bg : "rgba(255,255,255,0.03)",
                    border: `1px solid ${linked ? p.border : "var(--glass-border)"}`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    color: p.color,
                  }}>
                    {p.icon}
                  </div>
                  <div style={{ textAlign: isAr ? "right" : "left" }}>
                    <p style={{ fontWeight: 700, color: "var(--glass-text-primary)", fontSize: "15px", marginBottom: "2px" }}>{p.name}</p>
                    <p style={{ fontSize: "12px", color: linked ? p.color : "var(--glass-text-muted)", fontWeight: 600 }}>
                      {linked
                        ? (isAr ? "✓ مرتبط — يمكنك تسجيل الدخول به" : "✓ Linked — You can sign in with this")
                        : (isAr ? "غير مرتبط" : "Not linked")
                      }
                    </p>
                  </div>
                </div>

                <button
                  onClick={() => linked ? handleUnlink(p.id) : handleLink(p.id)}
                  disabled={isActionLoading}
                  style={{
                    display: "flex", alignItems: "center", gap: "8px",
                    padding: "10px 20px", borderRadius: "12px",
                    fontWeight: 700, fontSize: "13px",
                    cursor: isActionLoading ? "wait" : "pointer",
                    border: `1px solid ${linked ? "rgba(239, 68, 68, 0.3)" : p.border}`,
                    background: linked ? "rgba(239, 68, 68, 0.08)" : p.bg,
                    color: linked ? "#ef4444" : p.color,
                    transition: "all 0.2s ease",
                    flexDirection: isAr ? "row-reverse" : "row",
                  }}
                >
                  {isActionLoading ? (
                    <Loader2 className="animate-spin" size={16} />
                  ) : linked ? (
                    <><Unlink size={16} /> {isAr ? "إلغاء الربط" : "Unlink"}</>
                  ) : (
                    <><LinkIcon size={16} /> {isAr ? "ربط" : "Link"}</>
                  )}
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default function SettingsPage() {
  const { t, isAr } = useTranslation();
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const queryClient = useQueryClient();
  const { refreshProfile, user, logout } = useAuth();
  
  const initialTab = (searchParams.get("tab") as "account" | "ops" | "academic" | "comm") || "account";
  const [activeTab, setActiveTab] = useState<"account" | "ops" | "academic" | "comm">(initialTab);

  // Helper to change tab and update URL simultaneously to prevent state-URL conflict
  const handleTabChange = (tab: "account" | "ops" | "academic" | "comm") => {
    setActiveTab(tab);
    const params = new URLSearchParams(searchParams.toString());
    params.set("tab", tab);
    router.push(`${pathname}?${params.toString()}`, { scroll: false });
  };
  const [saveStatus, setSaveStatus] = useState<"idle" | "saving" | "success" | "error">("idle");

  useEffect(() => {
    const tab = searchParams.get("tab");
    if (tab && (tab === "account" || tab === "ops" || tab === "academic" || tab === "comm")) {
      if (tab !== activeTab) {
        setActiveTab(tab);
      }
    }
  }, [searchParams]); // Only depend on searchParams to avoid circular updates with activeTab

  const { data: settings, isLoading, isError, error } = useQuery({
    queryKey: ["school-settings"],
    queryFn: async () => (await api.get("/settings")).data.data
  });

  const mutation = useMutation({
    mutationFn: (newSettings: any) => api.patch("/settings", newSettings),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["school-settings"] });
      setSaveStatus("success");
      setTimeout(() => setSaveStatus("idle"), 3000);
    },
    onError: () => setSaveStatus("error")
  });

  const [formData, setFormData] = useState<any>(null);

  useEffect(() => {
    if (settings) {
      setFormData(settings);
    }
  }, [settings]);

  const { data: school, isLoading: isSchoolLoading } = useQuery({
    queryKey: ["school-me"],
    queryFn: async () => (await api.get("/school/me")).data.data,
  });

  const [accountForm, setAccountForm] = useState<{ name: string; email: string; code: string; logo: string }>({
    name: "",
    email: "",
    code: "",
    logo: "",
  });
  const [accountStatus, setAccountStatus] = useState<"idle" | "saving" | "success" | "error">("idle");
  const [accountError, setAccountError] = useState<string | null>(null);
  const [emailCheckStatus, setEmailCheckStatus] = useState<"idle" | "checking" | "available" | "taken">("idle");

  // Real-time Email Check
  useEffect(() => {
    if (!accountForm.email || !accountForm.email.includes("@")) {
      setEmailCheckStatus("idle");
      return;
    }

    // Don't check if it's the current email
    if (accountForm.email.trim() === user?.email) {
      setEmailCheckStatus("available");
      return;
    }

    const timer = setTimeout(async () => {
      setEmailCheckStatus("checking");
      try {
        const { data } = await api.get(`/auth/check-school-email/${encodeURIComponent(accountForm.email.trim())}`);
        if (data.success && data.data.available) {
          setEmailCheckStatus("available");
        } else {
          setEmailCheckStatus("taken");
        }
      } catch (e) {
        setEmailCheckStatus("idle");
      }
    }, 600);

    return () => clearTimeout(timer);
  }, [accountForm.email, user?.email]);
  const [newPassword, setNewPassword] = useState("");
  const [passwordStatus, setPasswordStatus] = useState<"idle" | "saving" | "success" | "error">("idle");
  const [showPassword, setShowPassword] = useState(false);
  const [passwordError, setPasswordError] = useState<string | null>(null);

  useEffect(() => {
    if (school) {
      setAccountForm({
        name: school.name ?? "",
        email: school.email ?? "",
        code: school.code ?? "",
        logo: school.logo ?? "",
      });
    }
  }, [school]);

  const updateSchoolMutation = useMutation({
    mutationFn: async () =>
      api.patch("/school/me", {
        name: accountForm.name.trim(),
        email: accountForm.email.trim() ? accountForm.email.trim() : null,
        logo: accountForm.logo ? accountForm.logo : null,
      }),
    onSuccess: async () => {
      const emailChanged = accountForm.email.trim() !== user?.email;
      
      await queryClient.invalidateQueries({ queryKey: ["school-me"] });
      setAccountStatus("success");
      setAccountError(null);
      
      if (emailChanged) {
        // Since login identity changed, we must force a re-login
        setTimeout(() => {
          logout(isAr 
            ? "تم تغيير البريد الإلكتروني بنجاح. يرجى تسجيل الدخول مجدداً بالبريد الجديد." 
            : "Email updated successfully. Please log in again with your new email.");
        }, 2000);
      } else {
        setTimeout(() => setAccountStatus("idle"), 2500);
        await refreshProfile();
      }
    },
    onError: (e) => {
      setAccountStatus("error");
      setAccountError(extractApiError(e).message);
      setTimeout(() => setAccountStatus("idle"), 3000);
    },
  });

  const schoolBucket = process.env.NEXT_PUBLIC_SCHOOL_LOGO_BUCKET || "school-assets";

  const uploadLogo = async (file: File) => {
    if (!school?.id) throw new Error("School not loaded");
    const ext = file.name.split(".").pop() || "png";
    const path = `schools/${school.id}/logo.${ext}`;
    const { error: uploadError } = await supabase.storage.from(schoolBucket).upload(path, file, {
      upsert: true,
      cacheControl: "3600",
      contentType: file.type || undefined,
    } as any);
    if (uploadError) throw uploadError;
    const { data } = supabase.storage.from(schoolBucket).getPublicUrl(path);
    return data.publicUrl;
  };

  const handlePasswordChange = async () => {
    setPasswordStatus("saving");
    setPasswordError(null);
    try {
      if (newPassword.trim().length < 6) throw new Error("Password must be at least 6 characters.");
      
      // Artificial delay for better UX (so the user sees the animation)
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      const { error: err } = await supabase.auth.updateUser({ password: newPassword.trim() });
      if (err) throw err;
      setPasswordStatus("success");
      setNewPassword("");
      
      // Mandatory re-login after password change for security
      setTimeout(() => {
        logout();
      }, 2000);
    } catch (e: any) {
      setPasswordStatus("error");
      setPasswordError(e?.message || "Failed to update password.");
      setTimeout(() => setPasswordStatus("idle"), 3000);
    }
  };

  if (isLoading) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--glass-text-primary)" }}>{isAr ? "جاري تحميل تفضيلات المؤسسة..." : "Loading institutional preferences..."}</div>;
  }

  if (isError) {
    return (
      <div className="card-glass" style={{ padding: "24px", borderColor: "rgba(248,113,113,0.35)", color: "#f87171" }}>
        {extractApiError(error).message}
      </div>
    );
  }

  if (!formData) {
    return <div style={{ padding: "40px", textAlign: "center", color: "var(--glass-text-primary)" }}>{isAr ? "لا توجد إعدادات متاحة." : "No settings available."}</div>;
  }

  const handleToggleDay = (day: number) => {
    const current = [...(formData.workingDays || [])];
    if (current.includes(day)) {
      setFormData({ ...formData, workingDays: current.filter(d => d !== day) });
    } else {
      setFormData({ ...formData, workingDays: [...current, day].sort() });
    }
  };

  const handleSaveSettings = () => {
    setSaveStatus("saving");
    mutation.mutate(formData);
  };

  const handleSaveAccount = () => {
    if (!accountForm.name.trim() || emailCheckStatus === "taken") return;
    setAccountStatus("saving");
    updateSchoolMutation.mutate();
  };

  const onGlobalSave = () => {
    if (activeTab === "account") {
      handleSaveAccount();
    } else {
      handleSaveSettings();
    }
  };

  const isGlobalSaving = saveStatus === "saving" || accountStatus === "saving";
  const isGlobalSuccess = saveStatus === "success" || accountStatus === "success";

  // Inline Styles inside component to access isAr/t
  const navItemStyle = (active: boolean): React.CSSProperties => ({
    display: "flex",
    alignItems: "center",
    gap: "12px",
    padding: "14px 16px",
    borderRadius: "12px",
    backgroundColor: active ? "var(--glass-bg)" : "transparent",
    color: active ? "var(--primary-light)" : "var(--glass-text-secondary)",
    fontWeight: active ? 800 : 500,
    transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
    textAlign: isAr ? "right" : "left",
    cursor: "pointer",
    border: active ? "1px solid var(--glass-border)" : "1px solid transparent",
    boxShadow: active ? "0 4px 12px rgba(0, 0, 0, 0.08)" : "none",
    position: "relative",
    width: "100%",
    flexDirection: isAr ? "row-reverse" : "row",
    whiteSpace: "nowrap",
    fontSize: "14px",
    transform: active ? "scale(1.02)" : "scale(1)",
  });

  const sectionTitleStyle: React.CSSProperties = {
    fontSize: "20px",
    fontWeight: 700,
    marginBottom: "32px",
    borderBottomWidth: "1px",
    borderBottomStyle: "solid",
    borderBottomColor: "var(--glass-border)",
    paddingBottom: "16px",
    color: "var(--glass-text-primary)",
    textAlign: isAr ? "right" : "left"
  };

  const subTitleStyle: React.CSSProperties = {
    fontSize: "14px",
    fontWeight: 700,
    textTransform: "uppercase",
    letterSpacing: "1px",
    color: "var(--glass-text-muted)",
    marginBottom: "16px",
    textAlign: isAr ? "right" : "left"
  };

  const labelStyle: React.CSSProperties = {
    display: "block",
    fontSize: "14px",
    fontWeight: 600,
    marginBottom: "8px",
    color: "var(--glass-text-secondary)",
    textAlign: isAr ? "right" : "left"
  };

  const inputStyle: React.CSSProperties = {
    width: "100%",
    padding: "12px 16px",
    borderRadius: "10px",
    background: "var(--glass-input-bg)",
    borderWidth: "1px",
    borderStyle: "solid",
    borderColor: "var(--glass-input-border)",
    color: "var(--glass-text-primary)",
    fontSize: "15px",
    outline: "none",
    textAlign: isAr ? "right" : "left",
    transition: "border-color 0.2s ease, box-shadow 0.2s ease"
  };

  const toggleRowStyle: React.CSSProperties = {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    padding: "20px 24px",
    background: "var(--glass-icon-bg)",
    borderRadius: "16px",
    borderWidth: "1px",
    borderStyle: "solid",
    borderColor: "var(--glass-border)",
    flexDirection: isAr ? "row-reverse" : "row",
    transition: "all 0.3s ease",
    gap: "20px"
  };

  const selectorCardStyle = (active: boolean): React.CSSProperties => ({
    padding: "24px",
    borderRadius: "20px",
    background: active ? "var(--primary-glow)" : "rgba(255,255,255,0.02)",
    borderWidth: "2px",
    borderStyle: "solid",
    borderColor: active ? "var(--primary-light)" : "var(--glass-border)",
    display: "flex",
    alignItems: "center",
    gap: "20px",
    cursor: "pointer",
    transition: "all 0.4s cubic-bezier(0.4, 0, 0.2, 1)",
    flexDirection: isAr ? "row-reverse" : "row",
    boxShadow: active ? "0 8px 24px rgba(59, 130, 246, 0.15)" : "none",
    transform: active ? "translateY(-4px)" : "none"
  });

  const dayButtonStyle = (active: boolean): React.CSSProperties => ({
    width: "40px",
    height: "40px",
    borderRadius: "10px",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    fontSize: "13px",
    fontWeight: 600,
    cursor: "pointer",
    transition: "all 0.2s ease",
    background: active ? "rgba(99, 102, 241, 0.2)" : "var(--glass-icon-bg)",
    color: active ? "var(--primary-light)" : "var(--glass-text-muted)",
    borderWidth: "1px",
    borderStyle: "solid",
    borderColor: active ? "rgba(129, 140, 248, 0.4)" : "var(--glass-border)",
  });

  return (
    <div className="settings-module" style={{ height: "100%", display: "flex", flexDirection: "column" }}>
      {/* Header */}
      <div className="module-header" style={{ marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>
            {t('dash_settings')}
          </h2>
          <p style={{ color: "var(--glass-text-secondary)" }}>{isAr ? "مركز الإدارة والتحكم" : "Management & Control Center"}</p>
        </div>
      </div>

      <div className="card-glass" style={{ 
        display: "flex", 
        flex: 1, 
        padding: 0, 
        overflow: "hidden", 
        flexDirection: isAr ? "row-reverse" : "row",
        borderRadius: "24px",
        minHeight: "700px"
      }}>
        {/* Sidebar Nav */}
        <div style={{ 
          width: "300px", 
          display: "flex", 
          flexDirection: "column", 
          gap: "8px", 
          padding: "32px 16px",
          background: "rgba(59, 130, 246, 0.02)", // Very subtle blue tint for contrast
          borderRight: isAr ? "none" : "1px solid var(--glass-border)",
          borderLeft: isAr ? "1px solid var(--glass-border)" : "none",
        }}>
          <button
            onClick={() => handleTabChange("account")}
            className={`setting-nav-item ${activeTab === "account" ? "active" : ""}`}
            style={navItemStyle(activeTab === "account")}
          >
            <Building2 size={20} />
            {isAr ? "الملف الشخصي" : "Profile Settings"}
          </button>
          <button
            onClick={() => handleTabChange("ops")}
            className={`setting-nav-item ${activeTab === "ops" ? "active" : ""}`}
            style={navItemStyle(activeTab === "ops")}
          >
            <ShieldCheck size={20} />
            {t('sett_tab_ops')}
          </button>
          <button
            onClick={() => handleTabChange("academic")}
            className={`setting-nav-item ${activeTab === "academic" ? "active" : ""}`}
            style={navItemStyle(activeTab === "academic")}
          >
            <Calendar size={20} />
            {t('sett_tab_academic')}
          </button>
          <button
            onClick={() => handleTabChange("comm")}
            className={`setting-nav-item ${activeTab === "comm" ? "active" : ""}`}
            style={navItemStyle(activeTab === "comm")}
          >
            <Video size={20} />
            {isAr ? "الاتصالات و Zoom" : "Communication & Zoom"}
          </button>
        </div>

        {/* Content Area */}
        <div style={{ 
          flex: 1, 
          padding: "40px 60px", 
          overflowY: "auto",
          background: "transparent" 
        }}>
          
          {/* Header Action Bar (Inside Content) */}
          <div style={{ 
            display: "flex", 
            justifyContent: "space-between", 
            alignItems: "center",
            marginBottom: "40px",
            flexDirection: isAr ? "row-reverse" : "row",
            borderBottom: "1px solid var(--glass-border)",
            paddingBottom: "20px"
          }}>
            <h3 style={{ ...sectionTitleStyle, borderBottom: "none", marginBottom: 0, paddingBottom: 0 }}>
              {activeTab === "account" && (isAr ? "الملف الشخصي" : "Institution Profile")}
              {activeTab === "ops" && t('sett_tab_ops')}
              {activeTab === "academic" && t('sett_tab_academic')}
              {activeTab === "comm" && (isAr ? "إعدادات الاتصال و Zoom" : "Communication & Zoom Settings")}
            </h3>
          </div>

          {activeTab === "ops" && (
            <div className="setting-section">
              <div style={{ marginTop: "0px" }}>
                <h4 style={subTitleStyle}>{isAr ? "قنوات التنبيه" : "Notification Channels"}</h4>
                <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
                  {/* SMS Row */}
                  <div 
                    style={{ ...toggleRowStyle, borderColor: formData.smsEnabled ? "var(--primary-light)" : "var(--glass-border)" }}
                    onClick={() => setFormData({ ...formData, smsEnabled: !formData.smsEnabled })}
                  >
                    <div style={{ textAlign: isAr ? "right" : "left", flex: 1 }}>
                      <p style={{ fontWeight: 700, color: "var(--glass-text-primary)", fontSize: "16px", marginBottom: "4px" }}>{isAr ? "تنبيهات SMS" : "SMS Notifications"}</p>
                      <p style={{ fontSize: "13px", color: "var(--glass-text-muted)", lineHeight: 1.5 }}>{isAr ? "إرسال تنبيهات الحضور والغياب لأولياء الأمور عبر الرسائل النصية." : "Send automated attendance alerts to parents via SMS gateway."}</p>
                    </div>
                    <div className={`premium-toggle ${formData.smsEnabled ? 'active' : ''}`} style={{
                      width: "48px",
                      height: "26px",
                      borderRadius: "20px",
                      background: formData.smsEnabled ? "var(--gradient-primary)" : "rgba(255,255,255,0.05)",
                      position: "relative",
                      cursor: "pointer",
                      transition: "all 0.3s ease",
                      border: "1px solid",
                      borderColor: formData.smsEnabled ? "transparent" : "var(--glass-border)"
                    }}>
                      <div style={{
                        position: "absolute",
                        top: "3px",
                        [isAr ? (formData.smsEnabled ? "left" : "right") : (formData.smsEnabled ? "right" : "left")]: "4px",
                        width: "18px",
                        height: "18px",
                        borderRadius: "50%",
                        background: "#fff",
                        transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
                        boxShadow: "0 2px 4px rgba(0,0,0,0.2)"
                      }} />
                    </div>
                  </div>

                  {/* WhatsApp Row */}
                  <div 
                    style={{ ...toggleRowStyle, borderColor: formData.whatsappEnabled ? "#10b981" : "var(--glass-border)" }}
                    onClick={() => setFormData({ ...formData, whatsappEnabled: !formData.whatsappEnabled })}
                  >
                    <div style={{ textAlign: isAr ? "right" : "left", flex: 1 }}>
                      <p style={{ fontWeight: 700, color: "var(--glass-text-primary)", fontSize: "16px", marginBottom: "4px" }}>{isAr ? "بوابة واتساب" : "WhatsApp Gateway"}</p>
                      <p style={{ fontSize: "13px", color: "var(--glass-text-muted)", lineHeight: 1.5 }}>{isAr ? "تواصل مباشر وفوري مع أولياء الأمور عبر تطبيق واتساب." : "Real-time, instant parent communication via official WhatsApp API."}</p>
                    </div>
                    <div className={`premium-toggle ${formData.whatsappEnabled ? 'active' : ''}`} style={{
                      width: "48px",
                      height: "26px",
                      borderRadius: "20px",
                      background: formData.whatsappEnabled ? "linear-gradient(135deg, #10b981 0%, #059669 100%)" : "rgba(255,255,255,0.05)",
                      position: "relative",
                      cursor: "pointer",
                      transition: "all 0.3s ease",
                      border: "1px solid",
                      borderColor: formData.whatsappEnabled ? "transparent" : "var(--glass-border)"
                    }}>
                      <div style={{
                        position: "absolute",
                        top: "3px",
                        [isAr ? (formData.whatsappEnabled ? "left" : "right") : (formData.whatsappEnabled ? "right" : "left")]: "4px",
                        width: "18px",
                        height: "18px",
                        borderRadius: "50%",
                        background: "#fff",
                        transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
                        boxShadow: "0 2px 4px rgba(0,0,0,0.2)"
                      }} />
                    </div>
                  </div>
                </div>

                <div style={{ marginTop: "60px", display: "flex", justifyContent: isAr ? "flex-start" : "flex-end" }}>
                  <button
                    onClick={handleSaveSettings}
                    disabled={saveStatus === "saving"}
                    className="btn-glass"
                    style={{
                      padding: "14px 40px",
                      background: saveStatus === "success" ? "rgba(16, 185, 129, 0.15)" : "var(--save-btn-bg)",
                      color: saveStatus === "success" ? "#10b981" : "#fff",
                      borderColor: saveStatus === "success" ? "#10b981" : "transparent",
                      fontWeight: 800,
                      borderRadius: "14px"
                    }}
                  >
                    {saveStatus === "saving" ? <Loader2 className="animate-spin" size={20} /> : (isAr ? "حفظ التغييرات" : "Save Changes")}
                  </button>
                </div>
              </div>
            </div>
          )}

          {activeTab === "comm" && (
            <div className="setting-section fade-in">
              <div 
                style={{ ...toggleRowStyle, marginBottom: "32px", borderColor: formData.zoomEnabled ? "var(--primary-light)" : "var(--glass-border)" }}
                onClick={() => setFormData({ ...formData, zoomEnabled: !formData.zoomEnabled })}
              >
                <div style={{ textAlign: isAr ? "right" : "left", flex: 1 }}>
                  <p style={{ fontWeight: 700, color: "var(--glass-text-primary)", fontSize: "16px", marginBottom: "4px" }}>{isAr ? "ربط زووم" : "Zoom Integration"}</p>
                  <p style={{ fontSize: "13px", color: "var(--glass-text-muted)", lineHeight: 1.5 }}>{isAr ? "تفعيل الفصول الافتراضية واجتماعات الموظفين عبر زووم." : "Enable virtual classrooms and staff meetings via Zoom API."}</p>
                </div>
                <div className={`premium-toggle ${formData.zoomEnabled ? 'active' : ''}`} style={{
                  width: "48px",
                  height: "26px",
                  borderRadius: "20px",
                  background: formData.zoomEnabled ? "var(--gradient-primary)" : "rgba(255,255,255,0.05)",
                  position: "relative",
                  cursor: "pointer",
                  transition: "all 0.3s ease",
                  border: "1px solid",
                  borderColor: formData.zoomEnabled ? "transparent" : "var(--glass-border)"
                }}>
                  <div style={{
                    position: "absolute",
                    top: "3px",
                    [isAr ? (formData.zoomEnabled ? "left" : "right") : (formData.zoomEnabled ? "right" : "left")]: "4px",
                    width: "18px",
                    height: "18px",
                    borderRadius: "50%",
                    background: "#fff",
                    transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
                    boxShadow: "0 2px 4px rgba(0,0,0,0.2)"
                  }} />
                </div>
              </div>

              {formData.zoomEnabled && (
                <div style={{ display: "flex", flexDirection: "column", gap: "24px" }} className="fade-in">
                  <div className="card-glass" style={{ padding: "20px", background: "rgba(59, 130, 246, 0.05)", border: "1px dashed var(--primary-light)" }}>
                    <p style={{ fontSize: "13px", color: "var(--glass-text-secondary)", lineHeight: 1.6 }}>
                      {isAr ? "استخدم نظام OAuth (Server-to-Server) لربط زووم بالمدرسة. يمكنك الحصول على هذه البيانات من Zoom App Marketplace." : "Use Zoom Server-to-Server OAuth for secure integration. Obtain these from the Zoom App Marketplace."}
                    </p>
                  </div>

                  <div style={{ display: "grid", gridTemplateColumns: "1fr", gap: "20px" }}>
                    <div className="field-group">
                      <label style={labelStyle}>Zoom Account ID</label>
                      <input
                        type="text"
                        value={formData.zoomAccountId || ""}
                        onChange={(e) => setFormData({ ...formData, zoomAccountId: e.target.value })}
                        style={inputStyle}
                        placeholder="e.g. AbC123Xyz..."
                      />
                    </div>
                    <div className="field-group">
                      <label style={labelStyle}>Zoom Client ID</label>
                      <input
                        type="text"
                        value={formData.zoomClientId || ""}
                        onChange={(e) => setFormData({ ...formData, zoomClientId: e.target.value })}
                        style={inputStyle}
                        placeholder="Client ID from App Credentials"
                      />
                    </div>
                    <div className="field-group">
                      <label style={labelStyle}>Zoom Client Secret</label>
                      <input
                        type="password"
                        value={formData.zoomClientSecret || ""}
                        onChange={(e) => setFormData({ ...formData, zoomClientSecret: e.target.value })}
                        style={inputStyle}
                        placeholder="••••••••••••••••"
                      />
                    </div>
                  </div>
                </div>
              )}

              <div style={{ marginTop: "60px", display: "flex", justifyContent: isAr ? "flex-start" : "flex-end" }}>
                <button
                  onClick={handleSaveSettings}
                  disabled={saveStatus === "saving"}
                  className="btn-glass"
                  style={{
                    padding: "14px 40px",
                    background: saveStatus === "success" ? "rgba(16, 185, 129, 0.15)" : "var(--save-btn-bg)",
                    color: saveStatus === "success" ? "#10b981" : "#fff",
                    borderColor: saveStatus === "success" ? "#10b981" : "transparent",
                    fontWeight: 800,
                    borderRadius: "14px"
                  }}
                >
                  {saveStatus === "saving" ? <Loader2 className="animate-spin" size={20} /> : (isAr ? "حفظ التغييرات" : "Save Changes")}
                </button>
              </div>
            </div>
          )}

          {activeTab === "academic" && (
            <div className="setting-section fade-in">
              <div style={{ marginBottom: "32px" }}>
                <label style={{ ...labelStyle, marginBottom: "16px", display: "block", fontSize: "14px" }}>{t('sett_attendance_mode')}</label>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                  <div
                    onClick={() => setFormData({ ...formData, attendanceMode: "DAILY" })}
                    style={{ ...selectorCardStyle(formData.attendanceMode === "DAILY"), padding: "18px", borderRadius: "24px" }}
                  >
                    <div style={{ 
                      width: "48px", 
                      height: "48px", 
                      borderRadius: "14px", 
                      background: formData.attendanceMode === "DAILY" ? "var(--gradient-primary)" : "var(--glass-icon-bg)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: formData.attendanceMode === "DAILY" ? "#fff" : "var(--glass-text-secondary)",
                      boxShadow: formData.attendanceMode === "DAILY" ? "0 6px 12px rgba(59, 130, 246, 0.25)" : "none",
                      transition: "all 0.3s ease"
                    }}>
                      <CalendarCheck size={24} />
                    </div>
                    <div style={{ textAlign: isAr ? "right" : "left", flex: 1 }}>
                      <p style={{ fontWeight: 800, color: "var(--glass-text-primary)", fontSize: "16px", marginBottom: "2px" }}>{t('sett_daily')}</p>
                      <p style={{ fontSize: "12px", color: "var(--glass-text-secondary)", lineHeight: 1.4 }}>{t('sett_daily_desc')}</p>
                    </div>
                  </div>

                  <div
                    onClick={() => setFormData({ ...formData, attendanceMode: "PERIODIC" })}
                    style={{ ...selectorCardStyle(formData.attendanceMode === "PERIODIC"), padding: "18px", borderRadius: "24px" }}
                  >
                    <div style={{ 
                      width: "48px", 
                      height: "48px", 
                      borderRadius: "14px", 
                      background: formData.attendanceMode === "PERIODIC" ? "var(--gradient-primary)" : "var(--glass-icon-bg)",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: formData.attendanceMode === "PERIODIC" ? "#fff" : "var(--glass-text-secondary)",
                      boxShadow: formData.attendanceMode === "PERIODIC" ? "0 6px 12px rgba(124, 58, 237, 0.25)" : "none",
                      transition: "all 0.3s ease"
                    }}>
                      <Clock size={24} />
                    </div>
                    <div style={{ textAlign: isAr ? "right" : "left", flex: 1 }}>
                      <p style={{ fontWeight: 800, color: "var(--glass-text-primary)", fontSize: "16px", marginBottom: "2px" }}>{t('sett_periodic')}</p>
                      <p style={{ fontSize: "12px", color: "var(--glass-text-secondary)", lineHeight: 1.4 }}>{t('sett_periodic_desc')}</p>
                    </div>
                  </div>
                </div>
              </div>

              <div style={{ marginBottom: "32px" }}>
                <label style={{ ...labelStyle, marginBottom: "16px", display: "block", fontSize: "14px" }}>{t('sett_working_days')}</label>
                <div style={{ 
                  display: "flex", 
                  flexWrap: "wrap", 
                  gap: "10px", 
                  background: "var(--glass-icon-bg)", 
                  padding: "12px", 
                  borderRadius: "24px",
                  border: "1px solid var(--glass-border)",
                  flexDirection: isAr ? "row-reverse" : "row"
                }}>
                  {[6, 0, 1, 2, 3, 4, 5].map(day => {
                    const isActive = (formData.workingDays || []).includes(day);
                    return (
                      <button
                        key={day}
                        onClick={() => handleToggleDay(day)}
                        style={{
                          ...dayButtonStyle(isActive),
                          width: "auto",
                          minWidth: "95px",
                          height: "42px",
                          padding: "0 14px",
                          borderRadius: "14px",
                          fontSize: "13px",
                          boxShadow: isActive ? "0 4px 10px rgba(59, 130, 246, 0.15)" : "none"
                        }}
                      >
                        {isActive && <CheckCircle2 size={12} style={{ [isAr ? "marginLeft" : "marginRight"]: "6px" }} />}
                        {t(`day_${day}` as any)}
                      </button>
                    );
                  })}
                </div>
              </div>

              <div className="premium-card" style={{ padding: "24px", borderRadius: "24px", border: "1px solid var(--glass-border)" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", flexDirection: isAr ? "row-reverse" : "row" }}>
                  <div>
                    <label style={{ ...labelStyle, marginBottom: "2px", display: "block", fontSize: "14px" }}>{t('sett_periods_per_day')}</label>
                    <p style={{ fontSize: "12px", color: "var(--glass-text-muted)" }}>{isAr ? "حدد عدد الحصص الدراسية اليومية." : "Define the daily academic periods."}</p>
                  </div>
                  <div style={{ 
                    width: "65px", 
                    height: "65px", 
                    borderRadius: "18px", 
                    background: "var(--save-btn-bg)", 
                    color: "#fff", 
                    display: "flex", 
                    flexDirection: "column",
                    alignItems: "center", 
                    justifyContent: "center", 
                    boxShadow: "0 6px 16px rgba(37, 99, 235, 0.15)"
                  }}>
                    <span style={{ fontSize: "26px", fontWeight: 900, lineHeight: 1 }}>{formData.periodsPerDay || 7}</span>
                    <span style={{ fontSize: "10px", fontWeight: 600, opacity: 0.8, marginTop: "2px" }}>{isAr ? "حصة" : "Periods"}</span>
                  </div>
                </div>
                
                <div style={{ display: "flex", alignItems: "center", gap: "20px" }}>
                  <input
                    type="range"
                    min="1"
                    max="12"
                    value={formData.periodsPerDay || 7}
                    onChange={e => setFormData({ ...formData, periodsPerDay: parseInt(e.target.value) })}
                    style={{ 
                      flex: 1, 
                      accentColor: "var(--primary-light)",
                      height: "6px",
                      cursor: "pointer"
                    }}
                  />
                </div>
              </div>

              <div style={{ marginTop: "60px", display: "flex", justifyContent: isAr ? "flex-start" : "flex-end" }}>
                <button
                  onClick={handleSaveSettings}
                  disabled={saveStatus === "saving"}
                  className="btn-glass"
                  style={{
                    padding: "14px 40px",
                    background: saveStatus === "success" ? "rgba(16, 185, 129, 0.15)" : "var(--save-btn-bg)",
                    color: saveStatus === "success" ? "#10b981" : "#fff",
                    borderColor: saveStatus === "success" ? "#10b981" : "transparent",
                    fontWeight: 800,
                    borderRadius: "14px",
                    boxShadow: saveStatus === "success" ? "none" : "0 8px 20px rgba(0, 0, 0, 0.1)"
                  }}
                >
                  {saveStatus === "saving" ? <Loader2 className="animate-spin" size={20} /> : (isAr ? "حفظ التغييرات" : "Save Changes")}
                </button>
              </div>
            </div>
          )}

          {activeTab === "account" && (
            <div className="setting-section fade-in">
              <div style={{ display: "flex", alignItems: "center", gap: "16px", marginBottom: "32px" }}>
                <div style={{ width: "48px", height: "48px", borderRadius: "14px", background: "var(--gradient-primary)", display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", boxShadow: "0 8px 20px rgba(59, 130, 246, 0.3)" }}>
                  <Building2 size={24} />
                </div>
                <div style={{ textAlign: isAr ? "right" : "left" }}>
                  <h3 style={{ fontSize: "24px", fontWeight: 900, color: "var(--glass-text-primary)", margin: 0 }}>{isAr ? "ملف المؤسسة" : "Institution Profile"}</h3>
                  <p style={{ color: "var(--glass-text-secondary)", fontSize: "14px", marginTop: "4px" }}>{isAr ? "إدارة بيانات المدرسة الرسمية وبيانات الوصول الأمنية." : "Manage your official school details and security credentials."}</p>
                </div>
              </div>

              <div className="card-glass" style={{
                padding: "24px",
                marginBottom: "32px",
                display: "flex",
                flexDirection: "column",
                gap: "24px",
                borderRadius: "20px",
                borderWidth: "1px",
                borderStyle: "solid",
                borderColor: "var(--glass-border)",
                background: "var(--glass-icon-bg)",
                boxShadow: "0 8px 32px rgba(0, 0, 0, 0.05)"
              }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "10px", color: "var(--primary-light)", fontWeight: 700, textTransform: "uppercase", fontSize: "13px", letterSpacing: "1px" }}>
                    <ShieldCheck size={16} />
                    <span>{isAr ? "هوية المدرسة الرسمية" : "Official School Identity"}</span>
                  </div>
                  <div style={{
                    padding: "6px 14px",
                    background: "rgba(16, 185, 129, 0.1)",
                    color: "#10b981",
                    borderRadius: "12px",
                    border: "1px solid rgba(16, 185, 129, 0.2)",
                    fontWeight: 700,
                    fontSize: "12px",
                    display: "flex",
                    alignItems: "center",
                    gap: "6px"
                  }}>
                    <CheckCircle2 size={14} /> {isAr ? "موثق" : "Verified"}
                  </div>
                </div>

                <div style={{
                  padding: "16px 24px",
                  background: "var(--glass-input-bg)",
                  borderWidth: "1px",
                  borderStyle: "dashed",
                  borderColor: "var(--glass-border)",
                  borderRadius: "16px",
                  display: "flex",
                  alignItems: "center",
                  gap: "16px"
                }}>
                  <div style={{ width: "48px", height: "48px", borderRadius: "12px", background: "var(--glass-icon-bg)", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--glass-text-secondary)" }}>
                    <Lock size={20} />
                  </div>
                  <div style={{ textAlign: isAr ? "right" : "left" }}>
                    <p style={{ fontSize: "12px", color: "var(--glass-text-muted)", textTransform: "uppercase", fontWeight: 500, marginBottom: "4px", letterSpacing: "1px" }}>{isAr ? "كود تعريف النظام" : "System ID Code"}</p>
                    <p style={{ fontSize: "23px", fontWeight: 500, color: "var(--glass-text-primary)", letterSpacing: "1px", lineHeight: 1 }}>
                      {accountForm.code || (isSchoolLoading ? "…" : "")}
                    </p>
                  </div>
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px", marginBottom: "32px" }}>
                <div className="field-group">
                  <label style={labelStyle}>{isAr ? "اسم المؤسسة الرسمي" : "Official Institution Name"}</label>
                  <input
                    type="text"
                    value={accountForm.name}
                    onChange={(e) => setAccountForm({ ...accountForm, name: e.target.value })}
                    style={inputStyle}
                    placeholder={isAr ? "مثال: مدرسة أكسفورد الدولية" : "e.g. Oxford International School"}
                  />
                </div>
                <div className="field-group">
                  <label style={labelStyle}>{isAr ? "البريد الإلكتروني الرئيسي" : "Primary Contact Email"}</label>
                  <div style={{ position: "relative" }}>
                    <input
                      type="email"
                      value={accountForm.email}
                      onChange={(e) => setAccountForm({ ...accountForm, email: e.target.value })}
                      style={{ 
                        ...inputStyle, 
                        paddingRight: isAr ? "16px" : "45px", 
                        paddingLeft: isAr ? "45px" : "16px",
                        borderColor: emailCheckStatus === "taken" ? "#f87171" : emailCheckStatus === "available" ? "#34d399" : "var(--glass-input-border)"
                      }}
                      placeholder="contact@school.edu"
                    />
                    <div style={{ 
                      position: "absolute", 
                      top: "50%", 
                      transform: "translateY(-50%)", 
                      [isAr ? "left" : "right"]: "15px",
                      display: "flex",
                      alignItems: "center"
                    }}>
                      {emailCheckStatus === "checking" && <div className="spinner-small" style={{ width: "16px", height: "16px", border: "2px solid rgba(99,102,241,0.2)", borderTopColor: "#6366f1", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />}
                      {emailCheckStatus === "available" && <CheckCircle2 size={16} style={{ color: "#34d399" }} />}
                      {emailCheckStatus === "taken" && <AlertCircle size={16} style={{ color: "#f87171" }} />}
                    </div>
                  </div>
                  {emailCheckStatus === "taken" && (
                    <p style={{ fontSize: "12px", color: "#f87171", marginTop: "6px", fontWeight: 600 }}>
                      {isAr ? "عفواً، هذا البريد مسجل بالفعل في النظام." : "Sorry, this email is already registered in the system."}
                    </p>
                  )}
                </div>
              </div>



              {accountError && (
                <div style={{ padding: "16px", background: "rgba(248,113,113,0.1)", border: "1px solid rgba(248,113,113,0.3)", borderRadius: "12px", color: "#f87171", fontWeight: 600, display: "flex", alignItems: "center", gap: "10px", marginBottom: "24px" }}>
                  <AlertCircle size={18} /> {accountError}
                </div>
              )}

              {/* ── Linked Accounts (OAuth) ── */}
              <LinkedAccountsSection isAr={isAr} />

              <div>
                <h4 style={{ fontSize: "18px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "8px", textAlign: isAr ? "right" : "left" }}>{isAr ? "الأمان والوصول" : "Security & Access"}</h4>
                <p style={{ color: "var(--glass-text-secondary)", fontSize: "14px", marginBottom: "24px", textAlign: isAr ? "right" : "left" }}>{isAr ? "تحديث كلمة مرور المدير للحفاظ على أمان الحساب." : "Update your administrator password to maintain account security."}</p>

                <div className="premium-card" style={{ 
                  padding: "24px", 
                  display: "flex", 
                  flexDirection: isAr ? "row-reverse" : "row", 
                  gap: "24px", 
                  alignItems: "flex-end",
                  borderRadius: "24px"
                }}>
                  <div style={{ flex: 1 }}>
                    <label style={{ ...labelStyle, textAlign: isAr ? "right" : "left" }}>{isAr ? "كلمة المرور الرئيسية الجديدة" : "New Master Password"}</label>
                    <div style={{ position: "relative" }}>
                      <input
                        type={showPassword ? "text" : "password"}
                        value={newPassword}
                        onChange={(e) => setNewPassword(e.target.value)}
                        style={{ ...inputStyle, textAlign: isAr ? "right" : "left", paddingRight: isAr ? "16px" : "44px", paddingLeft: isAr ? "44px" : "16px" }}
                        placeholder="••••••••"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        style={{
                          position: "absolute",
                          top: "50%",
                          transform: "translateY(-50%)",
                          [isAr ? "left" : "right"]: "12px",
                          background: "transparent",
                          border: "none",
                          color: "var(--glass-text-secondary)",
                          cursor: "pointer",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          padding: "4px",
                          borderRadius: "8px",
                          transition: "all 0.2s ease"
                        }}
                      >
                        {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
                      </button>
                    </div>
                  </div>
                  <button
                    onClick={handlePasswordChange}
                    disabled={passwordStatus === "saving" || !newPassword.trim()}
                    className="btn-glass"
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 8,
                      padding: "12px 24px",
                      borderRadius: 14,
                      fontWeight: 800,
                      background: passwordStatus === "success" ? "rgba(16, 185, 129, 0.15)" : "var(--glass-input-bg)",
                      border: "1px solid",
                      borderColor: passwordStatus === "success" ? "#10b981" : "var(--glass-border)",
                      color: passwordStatus === "success" ? "#10b981" : "var(--glass-text-primary)",
                      cursor: "pointer",
                      height: "46px",
                      transition: "all 0.3s ease",
                      flexDirection: isAr ? "row-reverse" : "row"
                    }}
                  >
                    {passwordStatus === "saving" ? (
                      <Loader2 className="animate-spin" size={20} />
                    ) : passwordStatus === "success" ? (
                      <>
                        <CheckCircle2 size={18} />
                        <span>{isAr ? "تم التحديث" : "Updated"}</span>
                      </>
                    ) : (
                      <>
                        <KeyRound size={18} />
                        <span>{isAr ? "تحديث" : "Update"}</span>
                      </>
                    )}
                  </button>
                </div>
                {passwordError && (
                  <div style={{ padding: "16px", marginTop: "16px", background: "rgba(248,113,113,0.1)", border: "1px solid rgba(248,113,113,0.3)", borderRadius: "12px", color: "#f87171", fontWeight: 600, display: "flex", alignItems: "center", gap: "10px" }}>
                    <AlertCircle size={18} /> {passwordError}
                  </div>
                )}

              {/* Save Footer for Account */}
              <div style={{ marginTop: "60px", display: "flex", justifyContent: isAr ? "flex-start" : "flex-end" }}>
                <button
                  onClick={handleSaveAccount}
                  disabled={accountStatus === "saving" || !accountForm.name.trim() || emailCheckStatus === "taken"}
                  className="btn-glass"
                  style={{
                    padding: "14px 40px",
                    background: accountStatus === "success" ? "rgba(16, 185, 129, 0.15)" : "var(--save-btn-bg)",
                    color: accountStatus === "success" ? "#10b981" : "#fff",
                    borderColor: accountStatus === "success" ? "#10b981" : "transparent",
                    fontWeight: 800,
                    borderRadius: "14px"
                  }}
                >
                  {accountStatus === "saving" ? (
                    <Loader2 className="animate-spin" size={20} />
                  ) : accountStatus === "success" ? (
                    <>
                      <CheckCircle2 size={18} />
                      {isAr ? "تم حفظ التغييرات" : "Changes Saved"}
                    </>
                  ) : (
                    (isAr ? "حفظ التغييرات" : "Save Changes")
                  )}
                </button>
              </div>
            </div>
          </div>
          )}
        </div>
      </div>
    </div>
  );
}
