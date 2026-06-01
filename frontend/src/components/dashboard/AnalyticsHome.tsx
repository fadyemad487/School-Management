"use client";

import type { CSSProperties, ReactNode } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import {
  Users,
  BookOpen,
  School,
  Wallet,
  Percent,
  UserX,
  Bus,
  ClipboardList,
  Megaphone,
  Bell,
  UserPlus,
  GraduationCap,
  Send,
  Landmark,
  ChevronRight,
} from "lucide-react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  BarChart,
  Bar,
  Legend,
} from "recharts";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import type { DashboardOverview } from "@/types/overview";

function money(n: number | undefined | null, isAr: boolean) {
  const value = n || 0;
  return new Intl.NumberFormat(isAr ? "ar-EG" : "en-US", {
    style: "currency",
    currency: "EGP",
    maximumFractionDigits: 0,
  }).format(value);
}

function shortDate(iso: string, isAr: boolean) {
  const d = new Date(iso);
  return d.toLocaleDateString(isAr ? "ar-EG" : "en-US", { month: "short", day: "numeric" });
}

function axisDayLabel(isoDate: string, isAr: boolean) {
  const [y, m, d] = isoDate.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d));
  return dt.toLocaleDateString(isAr ? "ar-EG" : "en-US", { month: "numeric", day: "numeric" });
}

type Kpi = {
  key: string;
  label: string;
  value: string;
  hint?: string;
  icon: ReactNode;
  accent: string;
};

type QuickTile = {
  href: string;
  label: string;
  Icon: typeof UserPlus;
  accent: string;
};

export function AnalyticsHome() {
  const { t, isAr } = useTranslation();
  const { data, isLoading, isError } = useQuery({
    queryKey: ["overview"],
    queryFn: async () => (await api.get<{ data: DashboardOverview }>("/dashboard/overview")).data.data,
  });

  const o = data;

  const quickTiles: QuickTile[] = [
    { href: "/dashboard/students", label: t("qa_add_student"), Icon: UserPlus, accent: "#2563eb" },
    { href: "/dashboard/teachers", label: t("qa_add_teacher"), Icon: GraduationCap, accent: "#4f46e5" },
    { href: "/dashboard/announcements", label: t("qa_add_announcement"), Icon: Megaphone, accent: "#7c3aed" },
    { href: "/dashboard/notifications", label: t("qa_send_notification"), Icon: Send, accent: "#0891b2" },
  ];

  const kpis: Kpi[] = [
    {
      key: "st",
      label: t("stat_total_students"),
      value: isLoading ? "…" : String(o?.totalStudents ?? 0),
      icon: <Users size={20} />,
      accent: "#2563eb",
    },
    {
      key: "tc",
      label: t("stat_active_teachers"),
      value: isLoading ? "…" : String(o?.totalTeachers ?? 0),
      icon: <BookOpen size={20} />,
      accent: "#7c3aed",
    },
    {
      key: "cl",
      label: t("stat_class_rooms"),
      value: isLoading ? "…" : String(o?.totalClasses ?? 0),
      icon: <School size={20} />,
      accent: "#0891b2",
    },
    {
      key: "at",
      label: t("kpi_attendance_today"),
      value:
        isLoading ? "…" : o?.attendanceRateToday == null ? t("stat_no_data") : `${o.attendanceRateToday}%`,
      hint:
        o?.attendanceMarkedToday != null && o.attendanceMarkedToday > 0
          ? `${t("stat_marked_today")}: ${o.attendanceMarkedToday}`
          : undefined,
      icon: <Percent size={20} />,
      accent: "#059669",
    },
    {
      key: "ab",
      label: t("kpi_absent_today"),
      value: isLoading ? "…" : String(o?.absentStudentsToday ?? 0),
      icon: <UserX size={20} />,
      accent: "#dc2626",
    },
    {
      key: "fe",
      label: t("kpi_pending_fees"),
      value: isLoading ? "…" : String(o?.pendingFeesCount ?? 0),
      hint: o != null ? money(o.pendingFeesAmount, isAr) : undefined,
      icon: <Wallet size={20} />,
      accent: "#d97706",
    },
    {
      key: "bu",
      label: t("kpi_active_buses"),
      value: isLoading ? "…" : String(o?.activeBuses ?? 0),
      icon: <Bus size={20} />,
      accent: "#4f46e5",
    },
    {
      key: "hw",
      label: t("kpi_homework_today"),
      value: isLoading ? "…" : String(o?.homeworkSentToday ?? 0),
      icon: <ClipboardList size={20} />,
      accent: "#db2777",
    },
    {
      key: "rv",
      label: t("stat_revenue_monthly"),
      value: isLoading ? "…" : money(o?.totalRevenue ?? 0, isAr),
      icon: <Landmark size={20} />,
      accent: "#0d9488",
    },
  ];

  const trend = o?.attendanceTrend30d?.length
    ? o.attendanceTrend30d.map((row) => ({
        ...row,
        label: axisDayLabel(row.date, isAr),
      }))
    : [];

  const revenue = o?.monthlyRevenue?.length
    ? o.monthlyRevenue.map((row) => ({
        ...row,
        label: row.month,
      }))
    : [];

  const classRowsWithData = o?.classSuccessVsFail?.filter((c) => c.samples > 0) ?? [];
  const classRows = classRowsWithData.length
    ? classRowsWithData.slice(0, 12)
    : (o?.classSuccessVsFail?.slice(0, 12) ?? []);

  const tooltipStyles = {
    borderRadius: 12,
    border: "1px solid var(--dash-chart-border)",
    background: "var(--dash-tooltip-bg)",
    color: "var(--dash-tooltip-fg)",
  };

  return (
    <div className="home-dash">
      <header className="home-dash__header">
        <div>
          <h1 className="home-dash__title">{t("home_title")}</h1>
          <p className="home-dash__subtitle">{t("home_subtitle")}</p>
        </div>
        {isError ? <p className="home-dash__error">Unable to load overview. Check your session and API.</p> : null}
      </header>

      <section className="home-dash__action-rail" aria-labelledby="home-quick-heading">
        <div className="action-rail">
          <div className="action-rail__head">
            <div>
              <h2 id="home-quick-heading" className="action-rail__title">
                {t("home_quick")}
              </h2>
              <p className="action-rail__sub">{t("home_actions_hint")}</p>
            </div>
          </div>
          <div className="action-rail__grid">
            {quickTiles.map(({ href, label, Icon, accent }) => (
              <Link
                key={href}
                href={href}
                className="action-tile"
                style={{ "--tile-accent": accent } as CSSProperties}
              >
                <span className="action-tile__icon">
                  <Icon size={22} strokeWidth={2} aria-hidden />
                </span>
                <span className="action-tile__text">{label}</span>
                <ChevronRight className="action-tile__go" size={20} strokeWidth={2} aria-hidden />
              </Link>
            ))}
          </div>
        </div>
      </section>

      <section className="home-dash__kpis" aria-label="Summary">
        {kpis.map((k) => (
          <article key={k.key} className="dash-kpi">
            <div className="dash-kpi__icon" style={{ color: k.accent, background: `${k.accent}18` }}>
              {k.icon}
            </div>
            <div className="dash-kpi__body">
              <div className="dash-kpi__label">{k.label}</div>
              <div className="dash-kpi__value">{k.value}</div>
              {k.hint ? <div className="dash-kpi__hint">{k.hint}</div> : null}
            </div>
          </article>
        ))}
      </section>

      <section className="home-dash__split" aria-label="Feeds">
        <div className="dash-feed">
          <div className="dash-feed__head">
            <Megaphone size={18} />
            <h2>{t("home_announcements")}</h2>
          </div>
          <ul className="dash-feed__list">
            {!o?.latestAnnouncements?.length ? (
              <li className="dash-feed__empty">{t("list_empty")}</li>
            ) : (
              o.latestAnnouncements.map((a) => (
                <li key={a.id} className="dash-feed__item">
                  <div className="dash-feed__item-title">{a.title}</div>
                  <div className="dash-feed__item-meta">
                    <span>{a.audience}</span>
                    <span>{shortDate(a.createdAt, isAr)}</span>
                  </div>
                  <p className="dash-feed__item-excerpt">{a.excerpt}</p>
                </li>
              ))
            )}
          </ul>
        </div>

        <div className="dash-feed">
          <div className="dash-feed__head">
            <Bell size={18} />
            <h2>{t("home_notifications")}</h2>
          </div>
          <ul className="dash-feed__list">
            {!o?.latestNotifications?.length ? (
              <li className="dash-feed__empty">{t("list_empty")}</li>
            ) : (
              o.latestNotifications.map((n) => (
                <li key={n.id} className="dash-feed__item">
                  <div className="dash-feed__item-title">{n.title}</div>
                  <div className="dash-feed__item-meta">
                    <span>{n.type}</span>
                    <span>{shortDate(n.createdAt, isAr)}</span>
                  </div>
                  <p className="dash-feed__item-excerpt">{n.message}</p>
                </li>
              ))
            )}
          </ul>
        </div>
      </section>

      <section className="home-dash__charts" aria-label="Charts">
        <div className="dash-chart-card">
          <h3 className="dash-chart-card__title">{t("chart_attendance_30d")}</h3>
          <div className="dash-chart-card__body">
            <ResponsiveContainer width="100%" height="100%" minHeight={280}>
              <AreaChart data={trend} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="attFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.35} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--dash-chart-grid)" />
                <XAxis dataKey="label" tick={{ fill: "var(--dash-chart-axis)", fontSize: 11 }} interval={4} />
                <YAxis domain={[0, 100]} tick={{ fill: "var(--dash-chart-axis)", fontSize: 11 }} width={32} />
                <Tooltip
                  contentStyle={tooltipStyles}
                  formatter={(v) => [`${Number(v)}%`, t("kpi_attendance_today")]}
                />
                <Area type="monotone" dataKey="rate" stroke="#3b82f6" strokeWidth={2} fill="url(#attFill)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="dash-chart-card">
          <h3 className="dash-chart-card__title">{t("chart_monthly_revenue")}</h3>
          <div className="dash-chart-card__body">
            <ResponsiveContainer width="100%" height="100%" minHeight={280}>
              <BarChart data={revenue} margin={{ top: 8, right: 8, left: 4, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--dash-chart-grid)" />
                <XAxis dataKey="label" tick={{ fill: "var(--dash-chart-axis)", fontSize: 11 }} angle={-25} textAnchor="end" height={56} />
                <YAxis tick={{ fill: "var(--dash-chart-axis)", fontSize: 11 }} width={44} />
                <Tooltip
                  contentStyle={tooltipStyles}
                  formatter={(v) => [money(Number(v), isAr), t("stat_revenue_monthly")]}
                />
                <Bar dataKey="amount" fill="#7c3aed" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="dash-chart-card dash-chart-card--wide">
          <h3 className="dash-chart-card__title">{t("chart_class_success")}</h3>
          <p className="dash-chart-card__note">{t("chart_class_footnote")}</p>
          <div className="dash-chart-card__body dash-chart-card__body--tall">
            <ResponsiveContainer width="100%" height="100%" minHeight={320}>
              <BarChart
                layout="vertical"
                data={classRows}
                margin={{ top: 8, right: 24, left: 8, bottom: 8 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="var(--dash-chart-grid)" horizontal={false} />
                <XAxis type="number" domain={[0, 100]} tick={{ fill: "var(--dash-chart-axis)", fontSize: 11 }} />
                <YAxis type="category" dataKey="label" width={120} tick={{ fill: "var(--dash-chart-axis)", fontSize: 11 }} />
                <Tooltip contentStyle={tooltipStyles} />
                <Legend />
                <Bar dataKey="passRate" name="Present %" stackId="s" fill="#10b981" radius={[0, 4, 4, 0]} />
                <Bar dataKey="failRate" name="Absent %" stackId="s" fill="#fb7185" radius={[4, 0, 0, 4]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </section>
    </div>
  );
}
