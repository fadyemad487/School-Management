"use client";

import React, { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { motion, AnimatePresence } from "framer-motion";
import { usePathname, useRouter } from "next/navigation";
import { useQueryClient, useIsFetching } from "@tanstack/react-query";
import { getSocket } from "@/lib/socket";
import type { LucideIcon } from "lucide-react";
import {
  GraduationCap,
  LayoutDashboard,
  Users,
  BookOpen,
  School,
  CalendarCheck,
  Bell,
  Settings,
  LogOut,
  Library,
  CalendarDays,
  ClipboardList,
  Award,
  UserCircle,
  Shield,
  Bus,
  Wallet,
  Megaphone,
  BarChart3,
  X,
  PanelLeft,
  ChevronRight,
  MessageCircle,
  UserPlus,
  Key,
  CalendarRange,
  Search,
  Video,
  Eye,
  EyeOff,
  AlertCircle,
  CheckCircle2,
  Loader2,
  Camera,
  Archive as ArchiveIcon,
  FileText,
  CalendarClock
} from "lucide-react";
import { useTranslation, type TranslationKey } from "@/lib/i18n";
import { useAuth } from "@/components/shared/AuthProvider";
import { LanguageSwitcher } from "@/components/ui/LanguageSwitcher";
import { ThemeToggle, useDashboardTheme } from "@/components/ui/ThemeToggle";
import { supabase } from "@/lib/supabase";
import Lottie from "lottie-react";
import aiAnimation from "@/assets/AI assistant animation.json";

type NavItem = { href: string; labelKey: TranslationKey; Icon: LucideIcon };
type NavGroup = { id: string; labelKey: TranslationKey; items: NavItem[] };

const NAV_GROUPS: NavGroup[] = [
  {
    id: "finance",
    labelKey: "nav_group_finance",
    items: [
      { href: "/dashboard", labelKey: "dash_overview", Icon: LayoutDashboard },
      { href: "/dashboard/payments", labelKey: "dash_finance", Icon: Wallet },
    ],
  },
  {
    id: "admission",
    labelKey: "nav_group_admission",
    items: [
      { href: "/dashboard/admissions", labelKey: "dash_admissions", Icon: UserPlus },
      { href: "/dashboard/students", labelKey: "dash_students", Icon: Users },
      { href: "/dashboard/credentials", labelKey: "dash_credentials", Icon: Key },
    ],
  },
  {
    id: "structure",
    labelKey: "nav_group_academic",
    items: [
      { href: "/dashboard/academic-years", labelKey: "dash_academic_years", Icon: CalendarRange },
      { href: "/dashboard/grades", labelKey: "dash_grades", Icon: GraduationCap },
      { href: "/dashboard/classes", labelKey: "dash_classes", Icon: School },
      { href: "/dashboard/subjects", labelKey: "dash_subjects", Icon: Library },
    ],
  },
  {
    id: "ops",
    labelKey: "nav_group_ops",
    items: [
      { href: "/dashboard/attendance", labelKey: "dash_attendance", Icon: CalendarCheck },
      { href: "/dashboard/timetable", labelKey: "dash_timetable", Icon: CalendarDays },
      { href: "/dashboard/schedules", labelKey: "dash_schedules", Icon: CalendarClock },
      { href: "/dashboard/homework", labelKey: "dash_homework", Icon: ClipboardList },
      { href: "/dashboard/exams", labelKey: "dash_exams", Icon: Award },
      { href: "/dashboard/behavior", labelKey: "dash_behavior", Icon: AlertCircle },
    ],
  },
  {
    id: "people",
    labelKey: "nav_group_people",
    items: [
      { href: "/dashboard/teachers", labelKey: "dash_teachers", Icon: BookOpen },
      { href: "/dashboard/teacher-assignments", labelKey: "dash_teacher_assignments" as TranslationKey, Icon: GraduationCap },
      { href: "/dashboard/parents", labelKey: "dash_parents", Icon: UserCircle },
      { href: "/dashboard/leaves", labelKey: "dash_leaves", Icon: FileText },
      { href: "/dashboard/users", labelKey: "dash_users", Icon: Shield },
    ],
  },
  {
    id: "services",
    labelKey: "nav_group_comm",
    items: [
      { href: "/dashboard/drivers", labelKey: "dash_drivers", Icon: Users },
      { href: "/dashboard/supervisors", labelKey: "dash_supervisors", Icon: Users },
      { href: "/dashboard/transport", labelKey: "dash_transport", Icon: Bus },
      { href: "/dashboard/announcements", labelKey: "dash_announcements", Icon: Megaphone },
      { href: "/dashboard/messages", labelKey: "dash_messages", Icon: MessageCircle },
      { href: "/dashboard/notifications", labelKey: "dash_notifications", Icon: Bell },
      { href: "/dashboard/communication/zoom", labelKey: "dash_zoom", Icon: Video },
    ],
  },
  {
    id: "system",
    labelKey: "nav_group_system",
    items: [
      { href: "/dashboard/reports", labelKey: "dash_reports", Icon: BarChart3 },
      { href: "/dashboard/archive", labelKey: "dash_archive", Icon: ArchiveIcon },
      { href: "/dashboard/settings", labelKey: "dash_settings", Icon: Settings },
    ],
  },
];

function navActive(href: string, pathname: string) {
  if (href === "/dashboard") return pathname === "/dashboard";
  return pathname === href || pathname.startsWith(`${href}/`);
}

function SidebarNav({
  t,
  pathname,
  collapsed,
  onNavigate,
}: {
  t: (k: TranslationKey) => string;
  pathname: string;
  collapsed: boolean;
  onNavigate?: () => void;
}) {
  return (
    <nav className="shell-nav" aria-label="Main" data-collapsed={collapsed ? "true" : "false"}>
      {NAV_GROUPS.map((group) => (
        <div key={group.id} className="shell-nav__group">
          <div className="shell-nav__group-label">{t(group.labelKey)}</div>
          <div className="shell-nav__group-items">
            {group.items.map(({ href, labelKey, Icon }) => {
              const active = navActive(href, pathname);
              return (
                <Link
                  key={href}
                  href={href}
                  className={`shell-nav__link${active ? " shell-nav__link--active" : ""}`}
                  title={collapsed ? t(labelKey) : undefined}
                >
                  <Icon className="shell-nav__icon" size={20} strokeWidth={1.75} aria-hidden />
                  <span className="shell-nav__label">{t(labelKey)}</span>
                  <ChevronRight className="shell-nav__chev" size={16} strokeWidth={2} aria-hidden />
                </Link>
              );
            })}
          </div>
        </div>
      ))}
    </nav>
  );
}

function roleBadgeLabel(role?: string) {
  if (!role) return "Member";
  if (role.toUpperCase() === "ADMIN") return "School-Owner";
  return role.replace(/_/g, " ");
}

import { AIChatAssistant } from "@/components/dashboard/AIChatAssistant";

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const { t, isAr } = useTranslation();
  const { user, loading, logout, refreshProfile } = useAuth();
  const pathname = usePathname();
  const router = useRouter();
  const queryClient = useQueryClient();
  const isFetching = useIsFetching();
  const [navOpen, setNavOpen] = useState(false);
  const [collapsed, setCollapsed] = useState(false);
  const [profileMenuOpen, setProfileMenuOpen] = useState(false);
  const [uploadingAvatar, setUploadingAvatar] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const avatarInputRef = React.useRef<HTMLInputElement>(null);
  const [showPasswordModal, setShowPasswordModal] = useState(false);
  const [oldPassword, setOldPassword] = useState("");
  const [newPasswordInModal, setNewPasswordInModal] = useState("");
  const [passModalStatus, setPassModalStatus] = useState<"idle" | "saving" | "success" | "error">("idle");
  const [passModalError, setPassModalError] = useState<string | null>(null);
  const [showEyeOld, setShowEyeOld] = useState(false);
  const [showEyeNew, setShowEyeNew] = useState(false);
  const [isWide, setIsWide] = useState(false);
  const { theme, toggle } = useDashboardTheme();
  const [isAiOpen, setIsAiOpen] = useState(false);

  const handleUpdatePassword = async () => {
    if (!oldPassword || !newPasswordInModal) return;
    setPassModalStatus("saving");
    setPassModalError(null);
    try {
      // 1. Verify old password by trying to sign in again
      const { error: signInErr } = await supabase.auth.signInWithPassword({
        email: user?.email || "",
        password: oldPassword,
      });

      if (signInErr) {
        throw new Error(isAr ? "كلمة المرور القديمة غير صحيحة" : "Old password is incorrect");
      }

      // 2. Update to new password
      const { error: updateErr } = await supabase.auth.updateUser({
        password: newPasswordInModal,
      });

      if (updateErr) throw updateErr;

      setPassModalStatus("success");
      setTimeout(() => {
        logout(); // Force logout after password change
      }, 2000);
    } catch (err: any) {
      setPassModalStatus("error");
      setPassModalError(err.message);
    }
  };

  const handleAvatarUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !user) return;

    setUploadingAvatar(true);
    try {
      const fileExt = file.name.split('.').pop();
      const fileName = `${user.id}-${Math.random()}.${fileExt}`;
      const filePath = `avatars/${fileName}`;

      const { error: uploadError } = await supabase.storage
        .from('school-assets')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('school-assets')
        .getPublicUrl(filePath);

      const { error: updateError } = await supabase.auth.updateUser({
        data: {
          avatar_url: publicUrl, // Keep for compatibility
          custom_avatar_url: publicUrl // Store here to prevent Google overwriting
        }
      });

      if (updateError) throw updateError;

      // Refresh auth profile
      if (refreshProfile) await refreshProfile();

    } catch (error: any) {
      alert(isAr ? "فشل تحميل الصورة" : "Failed to upload avatar");
    } finally {
      setUploadingAvatar(false);
    }
  };

  const handleLogout = async () => {
    setIsLoggingOut(true);
    // Artificial delay for professional animation feel
    await new Promise(resolve => setTimeout(resolve, 1000));
    logout();
  };

  useEffect(() => {
    if (typeof window === "undefined") return;
    const mq = window.matchMedia("(min-width: 1025px)");
    const apply = () => setIsWide(mq.matches);
    apply();
    mq.addEventListener("change", apply);
    return () => mq.removeEventListener("change", apply);
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") return;
    setCollapsed(localStorage.getItem("edu_sidebar_collapsed") === "1");
  }, []);

  const setCollapsedPersist = useCallback((next: boolean) => {
    setCollapsed(next);
    if (typeof window !== "undefined") {
      localStorage.setItem("edu_sidebar_collapsed", next ? "1" : "0");
    }
  }, []);

  useEffect(() => {
    if (!loading && !user) {
      router.push("/login");
    }
  }, [user, loading, router]);

  useEffect(() => {
    setNavOpen(false);
  }, [pathname]);

  useEffect(() => {
    if (!navOpen) return;
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = prev;
    };
  }, [navOpen]);

  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const handleRefresh = () => {
      console.log("[WS] Real-time Live Refetch triggered - updating active views.");
      queryClient.invalidateQueries();
    };

    socket.on("settings:updated", () => {
      queryClient.invalidateQueries({ queryKey: ["school-settings"] });
      handleRefresh();
    });

    const invalidate = (key: string[]) => () => {
      queryClient.invalidateQueries({ queryKey: key });
      handleRefresh();
    };

    socket.on("announcement:created", handleRefresh);
    socket.on("announcement:deleted", handleRefresh);
    socket.on("notification:new", invalidate(["notifications"]));
    socket.on("notification:system", invalidate(["notifications"]));
    socket.on("settings:updated", invalidate(["reports-overview"]));
    socket.on("school:updated", invalidate(["school-me"]));
    socket.on("chat:message", invalidate(["conversations"]));
    socket.on("student:updated", invalidate(["students"]));
    
    // Real-time synchronization listeners for 100% live application
    socket.on("subject:created", handleRefresh);
    socket.on("subject:deleted", handleRefresh);
    socket.on("subjects:bulk_created", handleRefresh);
    socket.on("homework:created", handleRefresh);
    socket.on("homework:updated", handleRefresh);
    socket.on("homework:deleted", handleRefresh);
    socket.on("exam:created", handleRefresh);
    socket.on("exam:updated", handleRefresh);
    socket.on("exam:deleted", handleRefresh);
    socket.on("teacher:created", handleRefresh);
    socket.on("teacher:updated", handleRefresh);
    socket.on("teacher:deleted", handleRefresh);
    socket.on("class:created", handleRefresh);
    socket.on("class:deleted", handleRefresh);
    socket.on("attendance:bulk_marked", handleRefresh);
    socket.on("attendance:marked", handleRefresh);
    socket.on("payment:received", handleRefresh);
    socket.on("leave:created", handleRefresh);
    socket.on("leave:updated", handleRefresh);
    socket.on("bus:attendance_updated", handleRefresh);
    socket.on("bus:deleted", handleRefresh);
    socket.on("route:deleted", handleRefresh);
    
    socket.on("dashboard:update", handleRefresh);

    socket.on("database:updated", (payload: any) => {
      console.log("[WS] Database updated via AI:", payload.model);
      if (payload.model) {
        // Invalidate both singular and plural keys to be safe
        queryClient.invalidateQueries({ queryKey: [payload.model] });
        queryClient.invalidateQueries({ queryKey: [payload.model + "s"] });
      } else {
        queryClient.invalidateQueries();
      }
      handleRefresh(); // Also refreshes overview
    });

    return () => {
      socket.off("settings:updated");
      socket.off("database:updated");
      socket.off("subject:created");
      socket.off("subject:deleted");
      socket.off("subjects:bulk_created");
      socket.off("homework:created");
      socket.off("homework:updated");
      socket.off("homework:deleted");
      socket.off("exam:created");
      socket.off("exam:updated");
      socket.off("exam:deleted");
      socket.off("teacher:created");
      socket.off("teacher:updated");
      socket.off("teacher:deleted");
      socket.off("class:created");
      socket.off("class:deleted");
      socket.off("attendance:bulk_marked");
      socket.off("attendance:marked");
      socket.off("payment:received");
      socket.off("leave:created");
      socket.off("leave:updated");
      socket.off("announcement:created");
      socket.off("announcement:deleted");
      socket.off("notification:new");
      socket.off("notification:system");
      socket.off("school:updated");
      socket.off("student:updated");
      socket.off("dashboard:update");
      socket.off("bus:attendance_updated");
      socket.off("bus:deleted");
      socket.off("route:deleted");
    };
  }, [queryClient, user]);

  const profileMenuRef = React.useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (profileMenuRef.current && !profileMenuRef.current.contains(event.target as Node)) {
        setProfileMenuOpen(false);
      }
    }
    if (profileMenuOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    } else {
      document.removeEventListener("mousedown", handleClickOutside);
    }
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [profileMenuOpen]);

  const toggleSidebar = () => {
    if (typeof window !== "undefined" && window.matchMedia("(min-width: 1025px)").matches) {
      setCollapsedPersist(!collapsed);
    } else {
      setNavOpen(true);
    }
  };

  const [isIntroPlaying, setIsIntroPlaying] = useState(false);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const playIntro = localStorage.getItem("play_intro");
      if (playIntro === "true") {
        setIsIntroPlaying(true);
      }
    }
  }, []);

  const handleIntroEnd = () => {
    setIsIntroPlaying(false);
    localStorage.removeItem("play_intro");
  };

  const videoRef = React.useRef<HTMLVideoElement>(null);

  useEffect(() => {
    if (isIntroPlaying && videoRef.current) {
      // Slow down the video slightly for a more premium/cinematic feel
      videoRef.current.playbackRate = 0.85;
    }
  }, [isIntroPlaying]);

  if (isIntroPlaying) {
    return (
      <div className="fixed inset-0 z-[10000] bg-black flex items-center justify-center overflow-hidden">
        <video
          ref={videoRef}
          src="/videos/intro.mp4"
          autoPlay
          playsInline
          onEnded={handleIntroEnd}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "contain",
            zIndex: 2
          }}
        />
      </div>
    );
  }

  if (loading && !user) {
    return (
      <div className="dash-auth-loading">
        <div className="spinner-large" />
      </div>
    );
  }

  if (!user) {
    return null;
  }

  const schoolName = user.school?.name || "EduControl";
  const initial = ((user.fullName?.[0] || user.email?.[0]) ?? "U").toUpperCase();
  const avatarUrl = user.avatarUrl;
  const langAppearance = theme === "light" ? "onLight" : "onDark";

  const shellClass = [
    "dashboard",
    "dashboard--saas",
    `dashboard--${theme}`,
    navOpen ? "dashboard--nav-open" : "",
    collapsed && isWide ? "dashboard--sidebar-collapsed" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={shellClass} dir={isAr ? "rtl" : "ltr"}>
      {/* 🚀 Premium Neon Gradient Top Loading Progress Bar */}
      <AnimatePresence>
        {isFetching > 0 && (
          <motion.div
            key="top-loader"
            initial={{ width: "0%", opacity: 0 }}
            animate={{ width: "95%", opacity: 1 }}
            exit={{ width: "100%", opacity: 0 }}
            transition={{ 
              width: { type: "spring", stiffness: 45, damping: 25 },
              opacity: { duration: 0.15 } 
            }}
            style={{
              position: "fixed",
              top: 0,
              left: 0,
              right: 0,
              height: "4px",
              background: "linear-gradient(90deg, #3b82f6, #8b5cf6, #ec4899)",
              zIndex: 99999,
              boxShadow: "0 0 12px rgba(139, 92, 246, 0.8), 0 0 4px rgba(236, 72, 153, 0.5)",
              pointerEvents: "none"
            }}
          />
        )}
      </AnimatePresence>

      {navOpen ? (
        <button
          type="button"
          className="dashboard__backdrop"
          aria-label="Close menu"
          onClick={() => setNavOpen(false)}
        />
      ) : null}

      <aside className={`dashboard__aside shell-sidebar${navOpen ? " dashboard__aside--open" : ""}`}>
        <div className="shell-sidebar__brand">
          <div className="shell-sidebar__logo" aria-hidden style={{ overflow: "hidden", display: "flex", alignItems: "center", justifyContent: "center" }}>
            {user.school?.logo ? (
              <img src={user.school.logo} alt="Logo" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
            ) : (
              <GraduationCap size={22} color="#fff" strokeWidth={2} />
            )}
          </div>
          <div className="shell-sidebar__brand-text">
            <div className="shell-sidebar__school">{schoolName}</div>
          </div>
          <button
            type="button"
            className="dashboard__close-nav shell-sidebar__close"
            onClick={() => setNavOpen(false)}
            aria-label="Close"
          >
            <X size={20} />
          </button>
        </div>

        <SidebarNav
          t={t}
          pathname={pathname}
          collapsed={collapsed && isWide}
          onNavigate={() => setNavOpen(false)}
        />

        {/* Sidebar Footer Removed - Relocated to Topbar */}
      </aside>

      <main className="dashboard__main shell-main">
        <header className="shell-topbar">
          <div className="shell-topbar__left">
            <button
              type="button"
              className="shell-topbar__icon-btn"
              onClick={toggleSidebar}
              aria-label={collapsed && isWide ? "Expand sidebar" : "Toggle sidebar"}
            >
              <PanelLeft size={20} strokeWidth={1.75} />
            </button>
            <span className="shell-topbar__vsep" aria-hidden />
            <div className="shell-topbar__search">
              <Search size={18} className="shell-topbar__search-icon" />
              <input type="text" placeholder={t("topbar_search_ph")} className="shell-topbar__search-input" />
            </div>
          </div>

          <div className="shell-topbar__right" style={{ display: "flex", alignItems: "center" }}>
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
              onClick={() => setIsAiOpen(true)}
              className="shell-topbar__icon-btn"
              style={{
                background: "transparent",
                border: "none",
                cursor: "pointer",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                filter: theme === "dark" ? "invert(1) brightness(2)" : "none"
              }}
            >
              <Lottie animationData={aiAnimation} loop={true} style={{ width: "20px", height: "20px" }} />
            </motion.button>
            <ThemeToggle theme={theme} onToggle={toggle} labels={{ light: t("theme_light"), dark: t("theme_dark") }} />
            <Link
              href="/dashboard/messages"
              className="shell-topbar__icon-btn"
              aria-label="Messages"
              title="Messages"
            >
              <MessageCircle size={20} strokeWidth={1.75} />
            </Link>
            <Link href="/dashboard/notifications" className="shell-topbar__icon-btn" aria-label="Notifications">
              <Bell size={20} strokeWidth={1.75} />
            </Link>
            <LanguageSwitcher appearance={langAppearance} variant="navbar" />
            <div style={{ position: "relative" }} ref={profileMenuRef}>
              <div
                className="shell-topbar__avatar"
                onClick={() => setProfileMenuOpen(!profileMenuOpen)}
                style={{
                  cursor: "pointer",
                  overflow: "hidden",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  transition: "all 0.2s ease",
                  border: profileMenuOpen ? "2px solid var(--primary-light)" : "2px solid transparent",
                  boxShadow: profileMenuOpen ? "0 0 15px rgba(59, 130, 246, 0.4)" : "0 2px 10px rgba(29, 78, 216, 0.28)"
                }}
              >
                {avatarUrl ? (
                  <img src={avatarUrl} alt="User" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                ) : (
                  initial
                )}
              </div>

              {profileMenuOpen && (
                <div
                  className="card-glass fade-in"
                  style={{
                    position: "absolute",
                    top: "calc(100% + 12px)",
                    [isAr ? "left" : "right"]: 0,
                    width: "280px",
                    padding: "20px",
                    zIndex: 1000,
                    boxShadow: "0 20px 50px rgba(0,0,0,0.3)",
                    border: "1px solid var(--glass-border)",
                    borderRadius: "20px"
                  }}
                >
                  <div className="shell-user" style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "20px", flexDirection: isAr ? "row-reverse" : "row" }}>
                    <div
                      className="shell-user__avatar"
                      onClick={() => avatarInputRef.current?.click()}
                      style={{
                        width: "56px",
                        height: "56px",
                        fontSize: "20px",
                        cursor: "pointer",
                        position: "relative",
                        overflow: "hidden"
                      }}
                    >
                      {avatarUrl ? (
                        <img src={avatarUrl} alt="User" style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                      ) : (
                        initial
                      )}

                      <div style={{
                        position: "absolute",
                        inset: 0,
                        background: "rgba(0,0,0,0.4)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        opacity: uploadingAvatar ? 1 : 0,
                        transition: "all 0.2s ease",
                        color: "#fff"
                      }} className="avatar-upload-overlay">
                        {uploadingAvatar ? <Loader2 size={20} className="animate-spin" /> : <Camera size={20} />}
                      </div>
                    </div>

                    <input
                      type="file"
                      ref={avatarInputRef}
                      onChange={handleAvatarUpload}
                      accept="image/*"
                      style={{ display: "none" }}
                    />

                    <div className="shell-user__meta" style={{ flex: 1, textAlign: isAr ? "right" : "left", overflow: "hidden" }}>
                      <div className="shell-user__name" style={{ fontSize: "15px", fontWeight: 800, color: "var(--glass-text-primary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                        {user.fullName || user.email?.split("@")[0]}
                      </div>
                      <div className="shell-user__email" style={{ fontSize: "11px", color: "var(--glass-text-secondary)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis", marginBottom: "4px" }}>
                        {user.email}
                      </div>
                      <span className="shell-user__badge" style={{ fontSize: "10px", padding: "2px 8px", borderRadius: "6px", background: "var(--primary-glow)", color: "var(--primary-light)", fontWeight: 700 }}>
                        {roleBadgeLabel(user.role)}
                      </span>
                    </div>
                  </div>

                  <div style={{ height: "1px", background: "var(--glass-border)", margin: "0 -20px 16px -20px" }} />

                  <div style={{ display: "flex", flexDirection: "column", gap: "4px", marginBottom: "16px" }}>
                    <Link
                      href="/dashboard/settings?tab=account"
                      onClick={() => setProfileMenuOpen(false)}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "12px",
                        padding: "10px 12px",
                        borderRadius: "10px",
                        color: "var(--glass-text-secondary)",
                        textDecoration: "none",
                        fontSize: "14px",
                        fontWeight: 600,
                        transition: "all 0.2s ease",
                        flexDirection: isAr ? "row-reverse" : "row"
                      }}
                      className="profile-menu-item"
                    >
                      <UserCircle size={18} />
                      <span>{isAr ? "إعدادات الملف الشخصي" : "Profile Settings"}</span>
                    </Link>

                    <Link
                      href="/dashboard/settings?tab=ops"
                      onClick={() => setProfileMenuOpen(false)}
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: "12px",
                        padding: "10px 12px",
                        borderRadius: "10px",
                        color: "var(--glass-text-secondary)",
                        textDecoration: "none",
                        fontSize: "14px",
                        fontWeight: 600,
                        transition: "all 0.2s ease",
                        flexDirection: isAr ? "row-reverse" : "row"
                      }}
                      className="profile-menu-item"
                    >
                      <Settings size={18} />
                      <span>{isAr ? "ضوابط المؤسسة" : "Institutional Controls"}</span>
                    </Link>

                    <button
                      onClick={() => { setProfileMenuOpen(false); setShowPasswordModal(true); }}
                      style={{
                        width: "100%",
                        display: "flex",
                        alignItems: "center",
                        gap: "12px",
                        padding: "10px 12px",
                        borderRadius: "10px",
                        color: "var(--glass-text-secondary)",
                        background: "transparent",
                        border: "none",
                        fontSize: "14px",
                        fontWeight: 600,
                        cursor: "pointer",
                        transition: "all 0.2s ease",
                        flexDirection: isAr ? "row-reverse" : "row"
                      }}
                      className="profile-menu-item"
                    >
                      <Key size={18} />
                      <span>{isAr ? "تغيير كلمة المرور" : "Change Password"}</span>
                    </button>
                  </div>

                  <div style={{ height: "1px", background: "var(--glass-border)", margin: "0 -20px 16px -20px" }} />

                  <button
                    type="button"
                    className="shell-user__logout"
                    onClick={handleLogout}
                    disabled={isLoggingOut}
                    style={{
                      width: "100%",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      gap: "10px",
                      padding: "12px",
                      borderRadius: "12px",
                      background: isLoggingOut ? "rgba(248, 113, 113, 0.2)" : "rgba(248, 113, 113, 0.1)",
                      color: "#f87171",
                      border: "1px solid rgba(248, 113, 113, 0.2)",
                      fontWeight: 700,
                      cursor: isLoggingOut ? "not-allowed" : "pointer",
                      transition: "all 0.3s cubic-bezier(0.4, 0, 0.2, 1)",
                      position: "relative",
                      overflow: "hidden"
                    }}
                  >
                    {isLoggingOut ? (
                      <>
                        <Loader2 size={18} className="animate-spin" />
                        <span>{isAr ? "جاري تسجيل الخروج..." : "Logging out..."}</span>
                      </>
                    ) : (
                      <>
                        <LogOut size={18} />
                        <span>{t("nav_logout")}</span>
                      </>
                    )}
                  </button>

                  <style jsx>{`
                    :global(.profile-menu-item:hover) {
                      background: var(--glass-icon-bg);
                      color: var(--primary-light) !important;
                      transform: translateX(${isAr ? '-4px' : '4px'});
                    }
                    :global(.shell-user__avatar:hover .avatar-upload-overlay) {
                      opacity: 1 !important;
                    }
                  `}</style>
                </div>
              )}
            </div>
          </div>
        </header>

        <div className="dashboard-content shell-main__body">{children}</div>
        <AIChatAssistant isOpen={isAiOpen} onClose={() => setIsAiOpen(false)} />

        {/* Password Change Modal */}
        {showPasswordModal && (
          <div style={{
            position: "fixed",
            top: 0, left: 0, right: 0, bottom: 0,
            background: "rgba(0,0,0,0.6)",
            backdropFilter: "blur(8px)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 9999,
            padding: "20px"
          }} onClick={() => passModalStatus !== "saving" && setShowPasswordModal(false)}>
            <div className="card-glass fade-in" style={{
              width: "100%",
              maxWidth: "420px",
              padding: "32px",
              borderRadius: "28px",
              boxShadow: "0 40px 80px rgba(0,0,0,0.5)",
              border: "1px solid var(--glass-border)"
            }} onClick={e => e.stopPropagation()}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px", flexDirection: isAr ? "row-reverse" : "row" }}>
                <h3 style={{ fontSize: "22px", fontWeight: 900, color: "var(--glass-text-primary)" }}>{isAr ? "تحديث كلمة المرور" : "Update Password"}</h3>
                <button onClick={() => setShowPasswordModal(false)} style={{ background: "transparent", border: "none", color: "var(--glass-text-secondary)", cursor: "pointer" }}>
                  <X size={24} />
                </button>
              </div>

              <p style={{ fontSize: "14px", color: "var(--glass-text-secondary)", marginBottom: "24px", textAlign: isAr ? "right" : "left" }}>
                {isAr ? "حدث كلمة مرورك للحفاظ على أمان حسابك." : "Update your administrator password to maintain account security."}
              </p>

              {passModalError && (
                <div style={{ padding: "12px", background: "rgba(248,113,113,0.1)", borderRadius: "10px", color: "#f87171", fontSize: "13px", display: "flex", alignItems: "center", gap: "8px", marginBottom: "20px", flexDirection: isAr ? "row-reverse" : "row" }}>
                  <AlertCircle size={16} />
                  <span>{passModalError}</span>
                </div>
              )}

              <div style={{ display: "grid", gap: "20px", marginBottom: "24px" }}>
                <div>
                  <label style={{ display: "block", fontSize: "12px", fontWeight: 700, color: "var(--glass-text-secondary)", textTransform: "uppercase", marginBottom: "8px", textAlign: isAr ? "right" : "left" }}>
                    {isAr ? "كلمة المرور القديمة" : "Old Password"}
                  </label>
                  <div style={{ position: "relative" }}>
                    <input
                      type={showEyeOld ? "text" : "password"}
                      value={oldPassword}
                      onChange={e => setOldPassword(e.target.value)}
                      style={{ width: "100%", padding: "12px 16px", borderRadius: "12px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-border)", color: "var(--glass-text-primary)", textAlign: isAr ? "right" : "left" }}
                      placeholder="••••••••"
                    />
                    <button type="button" onClick={() => setShowEyeOld(!showEyeOld)} style={{ position: "absolute", top: "50%", transform: "translateY(-50%)", [isAr ? "left" : "right"]: "12px", background: "transparent", border: "none", color: "var(--glass-text-secondary)", cursor: "pointer" }}>
                      {showEyeOld ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>

                <div>
                  <label style={{ display: "block", fontSize: "12px", fontWeight: 700, color: "var(--glass-text-secondary)", textTransform: "uppercase", marginBottom: "8px", textAlign: isAr ? "right" : "left" }}>
                    {isAr ? "كلمة المرور الجديدة" : "New Password"}
                  </label>
                  <div style={{ position: "relative" }}>
                    <input
                      type={showEyeNew ? "text" : "password"}
                      value={newPasswordInModal}
                      onChange={e => setNewPasswordInModal(e.target.value)}
                      style={{ width: "100%", padding: "12px 16px", borderRadius: "12px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-border)", color: "var(--glass-text-primary)", textAlign: isAr ? "right" : "left" }}
                      placeholder="••••••••"
                    />
                    <button type="button" onClick={() => setShowEyeNew(!showEyeNew)} style={{ position: "absolute", top: "50%", transform: "translateY(-50%)", [isAr ? "left" : "right"]: "12px", background: "transparent", border: "none", color: "var(--glass-text-secondary)", cursor: "pointer" }}>
                      {showEyeNew ? <EyeOff size={18} /> : <Eye size={18} />}
                    </button>
                  </div>
                </div>
              </div>

              <button
                onClick={handleUpdatePassword}
                disabled={passModalStatus === "saving" || !oldPassword || !newPasswordInModal}
                className="btn primary"
                style={{
                  width: "100%",
                  padding: "14px",
                  borderRadius: "14px",
                  fontWeight: 800,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  gap: "10px",
                  background: passModalStatus === "success" ? "#10b981" : "var(--gradient-primary)",
                  border: "none",
                  color: "#fff"
                }}
              >
                {passModalStatus === "saving" ? (
                  <Loader2 size={20} className="animate-spin" />
                ) : passModalStatus === "success" ? (
                  <>
                    <CheckCircle2 size={20} />
                    <span>{isAr ? "تم التحديث" : "Updated Successfully"}</span>
                  </>
                ) : (
                  <span>{isAr ? "تحديث كلمة المرور" : "Update Password"}</span>
                )}
              </button>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
