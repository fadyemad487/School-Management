"use client";

import Link from "next/link";
import { Home, ChevronRight } from "lucide-react";
import type { TranslationKey } from "@/lib/i18n";

const ROUTES: Array<{ prefix: string; group: TranslationKey; page: TranslationKey }> = [
  { prefix: "/dashboard/students", group: "nav_group_academic", page: "dash_students" },
  { prefix: "/dashboard/teachers", group: "nav_group_academic", page: "dash_teachers" },
  { prefix: "/dashboard/classes", group: "nav_group_academic", page: "dash_classes" },
  { prefix: "/dashboard/subjects", group: "nav_group_academic", page: "dash_subjects" },
  { prefix: "/dashboard/timetable", group: "nav_group_academic", page: "dash_timetable" },
  { prefix: "/dashboard/homework", group: "nav_group_academic", page: "dash_homework" },
  { prefix: "/dashboard/exams", group: "nav_group_academic", page: "dash_exams" },
  { prefix: "/dashboard/parents", group: "nav_group_people", page: "dash_parents" },
  { prefix: "/dashboard/users", group: "nav_group_people", page: "dash_users" },
  { prefix: "/dashboard/attendance", group: "nav_group_ops", page: "dash_attendance" },
  { prefix: "/dashboard/transport", group: "nav_group_ops", page: "dash_transport" },
  { prefix: "/dashboard/payments", group: "nav_group_finance", page: "dash_finance" },
  { prefix: "/dashboard/announcements", group: "nav_group_comm", page: "dash_announcements" },
  { prefix: "/dashboard/notifications", group: "nav_group_comm", page: "dash_notifications" },
  { prefix: "/dashboard/reports", group: "nav_group_insights", page: "dash_reports" },
  { prefix: "/dashboard/settings", group: "nav_group_system", page: "dash_settings" },
  { prefix: "/dashboard", group: "nav_bc_home", page: "dash_overview" },
];

function matchRoute(pathname: string) {
  if (pathname === "/dashboard") {
    return { group: "nav_bc_home" as const, page: "dash_overview" as const };
  }
  const sorted = [...ROUTES].sort((a, b) => b.prefix.length - a.prefix.length);
  return sorted.find((r) => pathname === r.prefix || pathname.startsWith(`${r.prefix}/`)) ?? null;
}

export function DashboardShellBreadcrumbs({
  pathname,
  t,
}: {
  pathname: string;
  t: (k: TranslationKey) => string;
}) {
  const hit = matchRoute(pathname);
  const isHome = pathname === "/dashboard";

  return (
    <nav className="shell-breadcrumb" aria-label="Breadcrumb">
      <Link href="/dashboard" className="shell-breadcrumb__home" title={t("nav_bc_home")}>
        <Home size={18} strokeWidth={2} aria-hidden />
      </Link>
      {isHome ? (
        <>
          <ChevronRight className="shell-breadcrumb__sep" size={16} aria-hidden />
          <span className="shell-breadcrumb__current">{t("dash_overview")}</span>
        </>
      ) : hit ? (
        <>
          <ChevronRight className="shell-breadcrumb__sep" size={16} aria-hidden />
          <span className="shell-breadcrumb__muted">{t(hit.group)}</span>
          <ChevronRight className="shell-breadcrumb__sep" size={16} aria-hidden />
          <span className="shell-breadcrumb__current">{t(hit.page)}</span>
        </>
      ) : (
        <>
          <ChevronRight className="shell-breadcrumb__sep" size={16} aria-hidden />
          <span className="shell-breadcrumb__current">{pathname.replace("/dashboard/", "") || "—"}</span>
        </>
      )}
    </nav>
  );
}
