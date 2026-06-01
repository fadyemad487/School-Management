"use client";

import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "@/lib/i18n";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { AlertCircle, CalendarDays, CalendarRange, ClipboardList, Info, Star, User } from "lucide-react";
import { api } from "@/lib/api";
import { useAuth } from "@/components/shared/AuthProvider";
import { getSocket } from "@/lib/socket";

type ReportPeriod = "daily" | "weekly" | "monthly";

function parseTraits(raw: unknown): string[] {
  if (!raw) return [];
  try {
    const parsed = JSON.parse(String(raw));
    if (Array.isArray(parsed)) return parsed.map((item) => String(item));
  } catch {
    // Some legacy records may be comma-separated plain text.
  }
  return String(raw)
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function getReportPeriod(report: any): ReportPeriod {
  const text = `${parseTraits(report.traits).join(" ")} ${report.notes || ""}`;
  if (text.includes("تقرير شهري")) return "monthly";
  if (text.includes("تقرير أسبوعي")) return "weekly";
  return "daily";
}

function getPeriodLabel(period: ReportPeriod, isAr: boolean) {
  if (period === "daily") return isAr ? "يومي" : "Daily";
  if (period === "weekly") return isAr ? "أسبوعي" : "Weekly";
  return isAr ? "شهري" : "Monthly";
}

function formatStructuredNotes(notes: string | null | undefined) {
  if (!notes) return [];
  return String(notes)
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean);
}

export default function BehaviorPage() {
  const { t, isAr } = useTranslation();
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const [activePeriod, setActivePeriod] = useState<ReportPeriod>("daily");

  const { data: behaviorRes, isLoading } = useQuery({
    queryKey: ["behavior"],
    queryFn: async () => {
      const res = await api.get("/behavior");
      return res.data;
    }
  });

  // WebSocket listener for real-time updates
  useEffect(() => {
    const socket = getSocket();
    if (!socket || !user?.schoolId) return;

    const handleBehaviorCreated = (data: any) => {
      console.log("Behavior report created:", data);
      queryClient.invalidateQueries({ queryKey: ["behavior"] });
    };

    socket.on("behavior:created", handleBehaviorCreated);

    return () => {
      socket.off("behavior:created", handleBehaviorCreated);
    };
  }, [user?.schoolId, queryClient]);

  const reports = behaviorRes?.data || [];
  const groupedReports = useMemo(() => {
    return {
      daily: reports.filter((report: any) => getReportPeriod(report) === "daily"),
      weekly: reports.filter((report: any) => getReportPeriod(report) === "weekly"),
      monthly: reports.filter((report: any) => getReportPeriod(report) === "monthly")
    };
  }, [reports]);

  const activeReports = groupedReports[activePeriod];

  const getTypeStyles = (type: string) => {
    if (type === "POSITIVE") {
      return {
        border: "#10b981",
        bg: "bg-emerald-500/15 text-emerald-500",
        glow: "#10b981",
        icon: <Star size={24} />,
        traitClass: "bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20"
      };
    } else if (type === "FOLLOWUP") {
      return {
        border: "#f59e0b",
        bg: "bg-amber-500/15 text-amber-500",
        glow: "#f59e0b",
        icon: <Info size={24} />,
        traitClass: "bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20"
      };
    } else {
      return {
        border: "#f43f5e",
        bg: "bg-rose-500/15 text-rose-500",
        glow: "#f43f5e",
        icon: <AlertCircle size={24} />,
        traitClass: "bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20"
      };
    }
  };

  const periodTabs: Array<{ period: ReportPeriod; Icon: any }> = [
    { period: "daily", Icon: CalendarDays },
    { period: "weekly", Icon: ClipboardList },
    { period: "monthly", Icon: CalendarRange }
  ];

  return (
    <div className="module-page fade-in">
      <div className="module-header">
        <div>
          <h1 className="module-title">{t("dash_behavior")}</h1>
          <p className="module-desc">
            {isAr ? "متابعة تقارير السلوك اليومية والأسبوعية والشهرية." : "Review daily, weekly, and monthly behavior reports."}
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-6">
        {periodTabs.map(({ period, Icon }) => {
          const selected = activePeriod === period;
          return (
            <button
              key={period}
              type="button"
              onClick={() => setActivePeriod(period)}
              className={`card-glass px-4 py-4 flex items-center justify-between transition-all ${
                selected ? "ring-2 ring-indigo-500 bg-indigo-500/10" : "hover:translate-y-[-2px]"
              }`}
            >
              <div className="text-start">
                <p className={`font-black ${selected ? "text-indigo-500" : "text-[var(--glass-text-primary)]"}`}>
                  {getPeriodLabel(period, isAr)}
                </p>
                <p className="text-xs text-[var(--glass-text-secondary)]">
                  {groupedReports[period].length} {isAr ? "تقرير" : "reports"}
                </p>
              </div>
              <div className={`w-11 h-11 rounded-xl flex items-center justify-center ${selected ? "bg-indigo-500 text-white" : "bg-black/5 dark:bg-white/10 text-[var(--glass-text-secondary)]"}`}>
                <Icon size={20} />
              </div>
            </button>
          );
        })}
      </div>

      {isLoading ? (
        <div className="flex justify-center p-12">
          <div className="spinner-large" />
        </div>
      ) : activeReports.length === 0 ? (
        <div className="card-glass p-12 text-center text-slate-400">
          <AlertCircle size={64} className="mx-auto mb-6 opacity-30" />
          <p className="text-lg">
            {isAr ? `لا توجد تقارير ${getPeriodLabel(activePeriod, true)} بعد` : `No ${getPeriodLabel(activePeriod, false).toLowerCase()} reports yet`}
          </p>
        </div>
      ) : (
        <div className={activePeriod === "daily" ? "grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6" : "grid grid-cols-1 xl:grid-cols-2 gap-6"}>
          {activeReports.map((report: any) => {
            const styles = getTypeStyles(report.type);
            const traits = parseTraits(report.traits);
            const structuredNotes = formatStructuredNotes(report.notes);
            return (
              <div 
                key={report.id} 
                className="card-glass p-5 hover:translate-y-[-4px] transition-transform duration-300 relative overflow-hidden"
                style={{ borderTop: `4px solid ${styles.border}` }}
              >
                {/* Background Glow */}
                <div 
                  className="absolute top-0 right-0 w-32 h-32 opacity-10 rounded-full blur-3xl pointer-events-none"
                  style={{ backgroundColor: styles.glow, transform: isAr ? 'translate(-30%, -30%)' : 'translate(30%, -30%)' }}
                />

                <div className="flex justify-between items-start mb-4 relative z-10">
                  <div className="flex items-center gap-3">
                    <div className={`flex items-center justify-center w-12 h-12 rounded-2xl ${styles.bg} shadow-inner`}>
                      {styles.icon}
                    </div>
                    <div>
                      <h3 className="font-bold text-[17px] text-[var(--glass-text-primary)] leading-tight">
                        {report.student?.nameAr || report.student?.nameEn || "طالب"}
                      </h3>
                      <span className="text-xs text-[var(--glass-text-secondary)] font-medium">
                        {new Date(report.createdAt).toLocaleDateString(isAr ? "ar-EG" : "en-US", { weekday: 'long', year: 'numeric', month: 'short', day: 'numeric' })}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="bg-black/5 dark:bg-white/5 rounded-xl p-3 mb-4 flex flex-col gap-2 relative z-10">
                  <div className="flex items-center text-sm text-[var(--glass-text-secondary)]">
                    <User size={14} className="min-w-[14px] mx-1 opacity-70" /> 
                    <span className="truncate">{report.teacher?.nameAr || report.teacher?.nameEn || "مدرس"}</span>
                  </div>
                  <div className="flex items-center text-sm text-[var(--glass-text-secondary)]">
                    <div className="w-[6px] h-[6px] rounded-full bg-blue-500 mx-2 opacity-70" />
                    <span className="font-medium text-[var(--glass-text-primary)]">{isAr ? "الفصل:" : "Class:"} {report.class?.name}</span>
                  </div>
                </div>

                <div className="mb-4 relative z-10">
                  <p className="text-xs font-bold text-[var(--glass-text-muted)] uppercase tracking-wider mb-2">
                    {isAr ? "التقييم السلوكي" : "Behavior Traits"}
                  </p>
                  <div className="flex flex-wrap gap-2">
                    {traits.map((trait: string, idx: number) => (
                      <span 
                        key={idx} 
                        className={`px-3 py-1.5 text-[13px] font-bold rounded-lg shadow-sm border ${styles.traitClass}`}
                      >
                        {trait}
                      </span>
                    ))}
                  </div>
                </div>

                {activePeriod === "daily" ? (
                  report.notes && (
                    <div className="relative z-10 mt-auto pt-4 border-t border-[var(--glass-border)]">
                      <p className="text-sm text-[var(--glass-text-secondary)] leading-relaxed italic">
                        "{report.notes}"
                      </p>
                    </div>
                  )
                ) : (
                  <div className="relative z-10 mt-auto pt-4 border-t border-[var(--glass-border)]">
                    <p className="text-xs font-bold text-[var(--glass-text-muted)] uppercase tracking-wider mb-3">
                      {activePeriod === "weekly"
                        ? (isAr ? "تفاصيل التقرير الأسبوعي" : "Weekly Details")
                        : (isAr ? "تفاصيل التقرير الشهري" : "Monthly Details")}
                    </p>
                    <div className="space-y-2">
                      {structuredNotes.map((line, idx) => (
                        <div key={idx} className="rounded-xl bg-black/5 dark:bg-white/5 border border-[var(--glass-border)] p-3">
                          <p className="text-sm text-[var(--glass-text-secondary)] leading-relaxed whitespace-pre-wrap">
                            {line}
                          </p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
            </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
