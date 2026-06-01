"use client";

import React, { useState, useEffect, useMemo } from "react";
import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import {
  Users, GraduationCap, UserCheck, BookOpen, X, RefreshCw,
  Calendar, Check, ClipboardList, Megaphone, Bus, Archive, Video,
  CreditCard, TrendingUp, ShieldCheck, FileText, ChevronLeft, ChevronRight, Award,
  Bell, Info, Clock, MessageSquare
} from "lucide-react";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, AreaChart, Area
} from "recharts";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { useAuth } from "@/components/shared/AuthProvider";
import { DashboardOverview } from "@/types/overview";
import styles from "./PremiumAnalyticsHome.module.css";

// ─── PREMIUM ILLUSTRATED ICONS (PNG) ──────────────────────────
const StudentIcon = () => (
  <img src="/icons/students.png" alt="Students" width={36} height={36} style={{ objectFit: 'contain' }} />
);
const TeacherIcon = () => (
  <img src="/icons/teacher.png" alt="Teachers" width={36} height={36} style={{ objectFit: 'contain' }} />
);
const DriverIcon = () => (
  <img src="/icons/driver.png" alt="Drivers" width={36} height={36} style={{ objectFit: 'contain' }} />
);
const SubjectIcon = () => (
  <img src="/icons/subjects.png" alt="Subjects" width={36} height={36} style={{ objectFit: 'contain' }} />
);

export function PremiumAnalyticsHome() {
  const { t, isAr } = useTranslation();
  const { user } = useAuth();

  const handleLeaveAction = async (id: string, action: "APPROVED" | "REJECTED") => {
    try {
      await api.patch(`/leaves/${id}/status`, { status: action });
      refetchOv(); // Refresh main overview which contains pendingLeaves
    } catch (err) {
      console.error("Failed to update leave status:", err);
    }
  };

  // Fetch real notifications
  const { data: notifData, refetch: refetchNotifs } = useQuery({
    queryKey: ["notifications"],
    queryFn: async () => (await api.get("/notifications")).data.data,
    staleTime: 0,
    refetchOnMount: "always",
  });
  const notifications = useMemo(() => (Array.isArray(notifData) ? notifData.slice(0, 5) : []), [notifData]);

  const [feesPeriod, setFeesPeriod] = useState<string>("last6months");

  // Fetch real overview data
  const { data: ov, isLoading: ovLoading, isFetching: ovFetching, error: ovError, refetch: refetchOv } = useQuery({
    queryKey: ["overview", feesPeriod],
    queryFn: async () => {
      try {
        const res = await api.get<{ data: DashboardOverview }>(`/dashboard/overview?period=${feesPeriod}`);
        console.log("Overview API Response:", res.data);
        return res.data.data;
      } catch (err) {
        console.error("Overview API Error:", err);
        throw err;
      }
    },
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
    refetchInterval: 60000, // Sync every 60s to save DB resources
  });

  const pendingLeaves = useMemo(() => (Array.isArray(ov?.pendingLeaves) ? ov.pendingLeaves : []), [ov?.pendingLeaves]);

  // Calendar Logic for Overview
  const [ovCalendarDate, setOvCalendarDate] = useState(new Date());

  // Fetch events for the specific month in overview
  const { data: ovEventsData, refetch: refetchEvents } = useQuery({
    queryKey: ["ovSchedules", ovCalendarDate.getMonth(), ovCalendarDate.getFullYear()],
    queryFn: async () => (await api.get(`/schedules?month=${ovCalendarDate.getMonth()}&year=${ovCalendarDate.getFullYear()}`)).data.data,
    enabled: !!ov,
    staleTime: 0,
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    refetchInterval: 60000, // Sync every 60s to save DB resources
  });
  const ovEvents = Array.isArray(ovEventsData) ? ovEventsData : [];

  const changeOvMonth = (offset: number) => {
    const d = new Date(ovCalendarDate);
    d.setMonth(d.getMonth() + offset);
    setOvCalendarDate(d);
  };

  const getOvDays = (year: number, month: number) => {
    const date = new Date(year, month, 1);
    const days = [];
    const firstDay = date.getDay();
    const prevMonthLastDay = new Date(year, month, 0).getDate();
    for (let i = firstDay - 1; i >= 0; i--) {
      days.push({ day: prevMonthLastDay - i, current: false });
    }
    const lastDay = new Date(year, month + 1, 0).getDate();
    for (let i = 1; i <= lastDay; i++) {
      days.push({ day: i, current: true });
    }
    return days;
  };
  const ovDays = getOvDays(ovCalendarDate.getFullYear(), ovCalendarDate.getMonth());

  useEffect(() => {
    if (ovError) console.error("Query Error Object:", ovError);
  }, [ovError]);

  const renderBadge = (change: number) => {
    const isUp = change >= 0;
    return (
      <div className={`${styles.statBadge} ${isUp ? styles.up : styles.down}`}>
        {isUp ? "+" : ""}{change}%
      </div>
    );
  };

  const feesData = [
    { name: "Q1 2023", total: 60, collected: 45 },
    { name: "Q2 2023", total: 60, collected: 50 },
    { name: "Q3 2023", total: 60, collected: 48 },
    { name: "Q4 2023", total: 60, collected: 50 },
    { name: "Q1 2024", total: 60, collected: 48 },
    { name: "Q2 2024", total: 60, collected: 40 },
    { name: "Q3 2024", total: 60, collected: 38 },
    { name: "Q4 2024", total: 60, collected: 49 }
  ];

  const [activeAttTab, setActiveAttTab] = useState<'students' | 'teachers' | 'drivers'>('students');
  const att = ov?.attendanceStats?.[activeAttTab] || { present: 0, absent: 0, late: 0, emergency: 0 };
  const attendanceData = [
    { name: "Present", value: att.present || 3610, color: "#3b82f6" },
    { name: "Absent", value: att.absent || 44, color: "#e2e8f0" },
    { name: "Late", value: att.late || 1, color: "#f59e0b" },
    { name: "Emergency", value: att.emergency || 28, color: "#10b981" }
  ];

  const pp = ov?.platformPerformance || { high: 45, medium: 11, low: 2 };
  const performanceData = [
    { name: isAr ? "مرتفع" : "High", value: pp.high, color: "#3b82f6" },
    { name: isAr ? "متوسط" : "Medium", value: pp.medium, color: "#f59e0b" },
    { name: isAr ? "منخفض" : "Low", value: pp.low, color: "#ef4444" }
  ];

  const totalPP = pp.high + pp.medium + pp.low;
  const healthScore = totalPP > 0
    ? Math.round(((pp.high + pp.medium * 0.5) / totalPP) * 100)
    : 0;

  const earningsData = [
    { name: "Jan", value: 4000 }, { name: "Feb", value: 3000 },
    { name: "Mar", value: 5000 }, { name: "Apr", value: 4500 },
    { name: "May", value: 6000 }, { name: "Jun", value: 5500 }
  ];

  const topSubjectsData = [
    { name: "Maths", value: 85, color: "#3b82f6" },
    { name: "Physics", value: 65, color: "#0ea5e9" },
    { name: "Chemistry", value: 45, color: "#0ea5e9" },
    { name: "Botany", value: 75, color: "#10b981" },
    { name: "English", value: 80, color: "#f59e0b" },
    { name: "Spanish", value: 90, color: "#ef4444" }
  ];

  // Real date for the "Updated" label
  const [now, setNow] = useState<Date | null>(null);
  useEffect(() => { setNow(new Date()); }, []);
  const formattedDate = now
    ? now.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
    : '...';
  const formattedTime = now
    ? now.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' })
    : '';

  const handleManualRefresh = () => {
    refetchOv();
    refetchNotifs();
    refetchEvents();
    setNow(new Date());
  };

  return (
    <div className={styles.container}>
      {/* HEADER */}
      <header className={styles.header}>
        <div className={styles.headerLeft}>
          <h1>{isAr ? "لوحة تحكم المسؤول" : "Admin Dashboard"}</h1>
          <p>{isAr ? "نظرة عامة / لوحة تحكم المسؤول" : "Overview / Admin Dashboard"}</p>
        </div>
        <div className={styles.headerRight}>
          <Link href="/dashboard/admissions" className={styles.btnPrimary}>{isAr ? "إضافة طالب جديد" : "Add New Student"}</Link>
          <Link href="/dashboard/payments" className={styles.btnSecondary}>{isAr ? "تفاصيل المصروفات" : "Fees Details"}</Link>
        </div>
      </header>

      {/* WELCOME BANNER */}
      <div className={styles.welcomeBanner}>
        <div className={styles.shape1}></div>
        <div className={styles.shape2}></div>
        <div className={styles.welcomeText}>
          <h2>{isAr ? `أهلاً بك مجدداً، ${user?.school?.name || user?.fullName || "المدرسة"}` : `Welcome Back, ${user?.school?.name || user?.fullName || "School"}`}</h2>
          <p>{isAr ? "نتمنى لك يوماً سعيداً في العمل" : "Have a Good day at work"}</p>
        </div>
        <div className={styles.welcomeRight}>
          <div className={styles.statusPill}>
            <button
              onClick={() => window.location.reload()}
              title={isAr ? "تحديث الصفحة بالكامل" : "Full Page Refresh"}
              className={styles.refreshIconButton}
            >
              <RefreshCw size={12} className={ovFetching ? styles.spin : ""} />
            </button>
            <div className={styles.updateContent}>
              <span className={styles.updateLabel}>{isAr ? "نظام EduControl" : "EduControl System"}</span>
              <span className={styles.updateTime}>{isAr ? "تم التحديث مؤخراً" : "Updated Recently"} • {formattedTime}</span>
            </div>
            <div className={styles.statusDot}></div>
          </div>
        </div>
      </div>

      {/* TOP STATS CARDS */}
      <div className={styles.statsGrid}>
        {/* Total Students */}
        <div className={styles.luxuryStatCard} style={{ "--accent-color": "#e11d48" } as any}>
          <div className={styles.luxuryStatInner}>
            <div className={styles.statTop}>
              <div style={{ display: 'flex', gap: 12 }}>
                <div className={`${styles.statIconWrap} ${styles.pink}`}><StudentIcon /></div>
                <div>
                  <div className={styles.statValue}>{ov?.totalStudents ?? "..."}</div>
                  <div className={styles.statLabel}>{isAr ? "إجمالي الطلاب" : "Total Students"}</div>
                </div>
              </div>
              {renderBadge(ov?.studentChange ?? 0)}
            </div>
            <div className={styles.statBottom}>
              <span>{isAr ? "نشط" : "Active"} : <strong>{ov?.activeStudents ?? "..."}</strong></span>
              <span>{isAr ? "غير نشط" : "Inactive"} : <strong>{ov?.inactiveStudents ?? "..."}</strong></span>
            </div>
          </div>
          <div className={styles.bgBlob}></div>
        </div>

        {/* Total Teachers */}
        <div className={styles.luxuryStatCard} style={{ "--accent-color": "#2563eb" } as any}>
          <div className={styles.luxuryStatInner}>
            <div className={styles.statTop}>
              <div style={{ display: 'flex', gap: 12 }}>
                <div className={`${styles.statIconWrap} ${styles.blue}`}><TeacherIcon /></div>
                <div>
                  <div className={styles.statValue}>{ov?.totalTeachers ?? "..."}</div>
                  <div className={styles.statLabel}>{isAr ? "إجمالي المعلمين" : "Total Teachers"}</div>
                </div>
              </div>
              {renderBadge(ov?.teacherChange ?? 0)}
            </div>
            <div className={styles.statBottom}>
              <span>{isAr ? "نشط" : "Active"} : <strong>{ov?.activeTeachers ?? "..."}</strong></span>
              <span>{isAr ? "غير نشط" : "Inactive"} : <strong>{ov?.inactiveTeachers ?? "..."}</strong></span>
            </div>
          </div>
          <div className={styles.bgBlob}></div>
        </div>

        {/* Total Drivers */}
        <div className={styles.luxuryStatCard} style={{ "--accent-color": "#ea580c" } as any}>
          <div className={styles.luxuryStatInner}>
            <div className={styles.statTop}>
              <div style={{ display: 'flex', gap: 12 }}>
                <div className={`${styles.statIconWrap} ${styles.orange}`}><DriverIcon /></div>
                <div>
                  <div className={styles.statValue}>{ov?.totalDrivers ?? "..."}</div>
                  <div className={styles.statLabel}>{isAr ? "إجمالي السائقين" : "Total Drivers"}</div>
                </div>
              </div>
              {renderBadge(ov?.driverChange ?? 0)}
            </div>
            <div className={styles.statBottom}>
              <span>{isAr ? "نشط" : "Active"} : <strong>{ov?.activeDrivers ?? "..."}</strong></span>
              <span>{isAr ? "غير نشط" : "Inactive"} : <strong>{ov?.inactiveDrivers ?? "..."}</strong></span>
            </div>
          </div>
          <div className={styles.bgBlob}></div>
        </div>

        {/* Total Subjects */}
        <div className={styles.luxuryStatCard} style={{ "--accent-color": "#16a34a" } as any}>
          <div className={styles.luxuryStatInner}>
            <div className={styles.statTop}>
              <div style={{ display: 'flex', gap: 12 }}>
                <div className={`${styles.statIconWrap} ${styles.green}`}><SubjectIcon /></div>
                <div>
                  <div className={styles.statValue}>{ov?.totalSubjects ?? "..."}</div>
                  <div className={styles.statLabel}>{isAr ? "إجمالي المواد" : "Total Subjects"}</div>
                </div>
              </div>
              {renderBadge(ov?.subjectChange ?? 0)}
            </div>
            <div className={styles.statBottom}>
              <span>{isAr ? "نشط" : "Active"} : <strong>{ov?.activeSubjects ?? "..."}</strong></span>
              <span>{isAr ? "غير نشط" : "Inactive"} : <strong>{ov?.inactiveSubjects ?? "..."}</strong></span>
            </div>
          </div>
          <div className={styles.bgBlob}></div>
        </div>
      </div>

      {/* ROW 2: FEES COLLECTION (2/3) & LEAVE REQUESTS (1/3) */}
      <div className={styles.mainSplit}>
        {/* Fees Collection */}
        <div className={styles.card}>
          <div className={styles.cardHeader}>
            <h3 className={styles.cardTitle}>{isAr ? "تحصيل المصروفات" : "Fees Collection"}</h3>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <select
                value={feesPeriod}
                onChange={(e) => setFeesPeriod(e.target.value)}
                style={{
                  background: 'var(--ov-surface-2)',
                  border: '1px solid var(--ov-divider)',
                  borderRadius: '10px',
                  padding: '4px 12px',
                  fontSize: '11px',
                  fontWeight: 600,
                  color: 'var(--ov-text-muted)',
                  cursor: 'pointer',
                  outline: 'none',
                  appearance: 'none',
                  textAlign: 'center'
                }}
              >
                <option value="today">{isAr ? "اليوم" : "Today"}</option>
                <option value="week">{isAr ? "هذا الأسبوع" : "This Week"}</option>
                <option value="month">{isAr ? "هذا الشهر" : "This Month"}</option>
                <option value="last6months">{isAr ? "آخر 6 أشهر" : "Last 6 Months"}</option>
              </select>
            </div>
          </div>
          <div style={{ height: 240 }}>
            <ResponsiveContainer width="100%" height="100%">
              <BarChart
                data={(ov?.feesCollectionTrend || feesData).map((d: any) => ({
                  ...d,
                  remaining: Math.max(0, Number(d.total) - Number(d.collected))
                }))}
                margin={{ top: 10, right: 10, left: -10, bottom: 0 }}
              >
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94a3b8' }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 11, fill: '#94a3b8' }} />
                <Tooltip
                  cursor={{ fill: 'rgba(226, 232, 240, 0.4)' }}
                  contentStyle={{ borderRadius: '12px', border: 'none', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.1)' }}
                />
                <Bar dataKey="collected" stackId="a" name={isAr ? "المحصل" : "Collected"} fill="#3b82f6" barSize={16} />
                <Bar dataKey="remaining" stackId="a" name={isAr ? "المتبقي" : "Remaining"} fill="#e2e8f0" radius={[6, 6, 0, 0]} barSize={16} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Leave Requests */}
        <div className={styles.card}>
          <div className={styles.cardHeader}>
            <h3 className={styles.cardTitle}>{isAr ? "طلبات الإجازة" : "Leave Requests"}</h3>
            <span className={styles.cardSubtitle}><Calendar size={14} /> {isAr ? "هذا الأسبوع" : "This Week"}</span>
          </div>
          <div className={`${styles.list} ${styles.scrollableList}`} style={{ overflowY: 'auto' }}>
            {pendingLeaves.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px 0', color: '#94a3b8' }}>
                <Clock size={32} style={{ marginBottom: 8, opacity: 0.5 }} />
                <p style={{ fontSize: 13 }}>{isAr ? "لا توجد طلبات معلقة" : "No pending requests"}</p>
              </div>
            ) : (
              pendingLeaves.map((l: any) => {
                const isTeacher = !!l.teacherId;
                const person = isTeacher ? l.teacher : l.student;
                const name = isAr ? (person?.nameAr || person?.user?.fullName) : (person?.nameEn || person?.user?.fullName);
                const role = isTeacher ? (isAr ? "معلم" : "Teacher") : (isAr ? "طالب" : "Student");
                const roleIcon = isTeacher ? "👨‍🏫" : "🎓";
                const startDate = new Date(l.startDate).toLocaleDateString(isAr ? 'ar-EG' : 'en-GB', { day: '2-digit', month: 'short' });
                const endDate = new Date(l.endDate).toLocaleDateString(isAr ? 'ar-EG' : 'en-GB', { day: '2-digit', month: 'short' });
                const applyDate = new Date(l.applyDate).toLocaleDateString(isAr ? 'ar-EG' : 'en-GB', { day: '2-digit', month: 'short' });

                return (
                  <div key={l.id} className={styles.listItem}>
                    <div className={styles.avatar}>{person?.photo ? <img src={person.photo} alt="P" /> : roleIcon}</div>
                    <div className={styles.listBody}>
                      <h4>{name} <span className={`${styles.tag} ${l.type === 'Emergency' ? styles.red : styles.green}`}>{l.type}</span></h4>
                      <p>{role}</p>
                      <div style={{ marginTop: 8, fontSize: 11, display: 'flex', gap: 16 }}>
                        <span>{isAr ? "الإجازة :" : "Leave :"} <strong>{startDate} - {endDate}</strong></span>
                        <span>{isAr ? "التقديم :" : "Apply on :"} <strong>{applyDate}</strong></span>
                      </div>
                    </div>
                    <div className={styles.actionBtns}>
                      <button className={`${styles.actionBtn} ${styles.approve}`} onClick={() => handleLeaveAction(l.id, "APPROVED")}><Check size={14} /></button>
                      <button className={`${styles.actionBtn} ${styles.reject}`} onClick={() => handleLeaveAction(l.id, "REJECTED")}><X size={14} /></button>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>

      {/* THREE COLUMN LAYOUT */}
      <div className={styles.threeCols}>
        {/* COLUMN 1 */}
        <div className={styles.colFlex}>
          {/* Schedules */}
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3 className={styles.cardTitle}>{isAr ? "الجداول الزمنية" : "Schedules"}</h3>
              <Link href="/dashboard/schedules" className={styles.cardSubtitle} style={{ color: '#3b82f6', fontWeight: 600, textDecoration: 'none' }}>
                + {isAr ? "إضافة جديد" : "Add New"}
              </Link>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <h4 style={{ fontSize: 14, fontWeight: 600, margin: 0 }}>
                {ovCalendarDate.toLocaleString(isAr ? 'ar-EG' : 'en-US', { month: 'long', year: 'numeric' })}
              </h4>
              <div style={{ display: 'flex', gap: 8 }}>
                <button onClick={() => changeOvMonth(-1)} style={{ cursor: 'pointer', width: 20, height: 20, borderRadius: '50%', background: '#f1f5f9', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ChevronLeft size={12} /></button>
                <button onClick={() => changeOvMonth(1)} style={{ cursor: 'pointer', width: 20, height: 20, borderRadius: '50%', background: '#0f172a', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ChevronRight size={12} /></button>
              </div>
            </div>
            {/* Calendar Grid */}
            <div className={styles.calendarGrid}>
              {(isAr ? ['ح', 'ن', 'ث', 'ر', 'خ', 'ج', 'س'] : ['S', 'M', 'T', 'W', 'T', 'F', 'S']).map((d, i) => <div key={`dh-${i}`} className={styles.calDayHead}>{d}</div>)}
              {ovDays.map((d, i) => {
                const hasEvent = d.current && ovEvents.some((e: any) =>
                  e.day === d.day && e.month === ovCalendarDate.getMonth() && e.year === ovCalendarDate.getFullYear()
                );
                let c = styles.calDay;
                if (!d.current) c += ` ${styles.muted}`; // prev month
                if (hasEvent) c += ` ${styles.active}`;
                return <div key={`d-${i}`} className={c}>{d.day}</div>
              })}
            </div>
            <div>
              <h4 style={{ fontSize: 14, fontWeight: 600, marginBottom: 12 }}>{isAr ? "الفعاليات القادمة" : "Upcoming Events"}</h4>
              <div className={styles.list}>
                {ovEvents.length === 0 ? (
                  <p style={{ fontSize: 12, color: 'var(--ov-text-muted)', textAlign: 'center', padding: '20px 0' }}>
                    {isAr ? "لا توجد فعاليات في هذا الشهر" : "No events this month"}
                  </p>
                ) : (
                  ovEvents.slice(0, 3).map((e: any) => (
                    <div key={e.id} className={styles.listItem} style={{ alignItems: 'center' }}>
                      <div style={{
                        width: 40, height: 40, borderRadius: 8,
                        background: e.type === 'MEETING' ? '#e0f2fe' : '#dbeafe',
                        color: e.type === 'MEETING' ? '#0ea5e9' : '#3b82f6',
                        display: 'flex', alignItems: 'center', justifyContent: 'center'
                      }}>
                        {e.type === 'MEETING' ? <Users size={20} /> : <Megaphone size={20} />}
                      </div>
                      <div className={styles.listBody}>
                        <h4 style={{ margin: 0 }}>{e.title}</h4>
                        <p style={{ color: 'var(--ov-text)', fontWeight: 500, fontSize: 11 }}>
                          {e.day} {new Date(e.year, e.month).toLocaleString(isAr ? 'ar-EG' : 'en-US', { month: 'long' })} {e.year}
                        </p>
                        <p>{e.startTime} - {e.endTime}</p>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>

          {/* Earnings */}
          <div className={styles.card}>
            <div className={styles.cardHeader} style={{ marginBottom: 4 }}>
              <div>
                <p style={{ fontSize: 12, color: '#64748b', margin: '0 0 4px 0' }}>{isAr ? "إجمالي الأرباح" : "Total Earnings"}</p>
                <h3 style={{ fontSize: 20, margin: 0 }}>
                  {ov ? `EGP ${Number(ov.totalEarnings).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : "..."}
                </h3>
              </div>
              <div style={{ width: 32, height: 32, background: '#3b82f6', color: '#fff', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><TrendingUp size={16} /></div>
            </div>
            <div style={{ height: 80, marginTop: 12 }}>
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={earningsData}>
                  <Area type="monotone" dataKey="value" stroke="#3b82f6" fill="#eff6ff" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* Expenses */}
          <div className={styles.card}>
            <div className={styles.cardHeader} style={{ marginBottom: 4 }}>
              <div>
                <p style={{ fontSize: 12, color: '#64748b', margin: '0 0 4px 0' }}>{isAr ? "إجمالي المصاريف" : "Total Expenses"}</p>
                <h3 style={{ fontSize: 20, margin: 0 }}>
                  {ov ? `EGP ${Number(ov.totalExpenses).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}` : "..."}
                </h3>
              </div>
              <div style={{ width: 32, height: 32, background: '#ef4444', color: '#fff', borderRadius: 8, display: 'flex', alignItems: 'center', justifyContent: 'center' }}><TrendingUp size={16} style={{ transform: 'rotate(180deg)' }} /></div>
            </div>
            <div style={{ height: 80, marginTop: 12 }}>
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={earningsData}>
                  <Area type="monotone" dataKey="value" stroke="#ef4444" fill="#fef2f2" strokeWidth={2} />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* COLUMN 2 */}
        <div className={styles.colFlex}>
          {/* Attendance Donut */}
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3 className={styles.cardTitle}>{isAr ? "الحضور" : "Attendance"}</h3>
              <Link href="/dashboard/attendance" className={styles.cardSubtitle} style={{ textDecoration: 'none', display: 'flex', alignItems: 'center', gap: 4 }}>
                {isAr ? "اليوم" : "Today"} <ChevronRight size={14} />
              </Link>
            </div>
            <div style={{ display: 'flex', justifyContent: 'center', gap: 24, marginBottom: 24, borderBottom: '1px solid #f1f5f9', paddingBottom: 16 }}>
              <div
                onClick={() => setActiveAttTab('students')}
                style={{ textAlign: 'center', cursor: 'pointer', color: activeAttTab === 'students' ? '#3b82f6' : '#64748b' }}
              >
                <h4 style={{ margin: 0 }}>{isAr ? "الطلاب" : "Students"}</h4>
                {activeAttTab === 'students' && <div style={{ width: 24, height: 2, background: '#3b82f6', margin: '4px auto' }}></div>}
              </div>
              <div
                onClick={() => setActiveAttTab('teachers')}
                style={{ textAlign: 'center', cursor: 'pointer', color: activeAttTab === 'teachers' ? '#3b82f6' : '#64748b' }}
              >
                <h4 style={{ margin: 0 }}>{isAr ? "المعلمون" : "Teachers"}</h4>
                {activeAttTab === 'teachers' && <div style={{ width: 24, height: 2, background: '#3b82f6', margin: '4px auto' }}></div>}
              </div>
              <div
                onClick={() => setActiveAttTab('drivers')}
                style={{ textAlign: 'center', cursor: 'pointer', color: activeAttTab === 'drivers' ? '#3b82f6' : '#64748b' }}
              >
                <h4 style={{ margin: 0 }}>{isAr ? "السائقون" : "Drivers"}</h4>
                {activeAttTab === 'drivers' && <div style={{ width: 24, height: 2, background: '#3b82f6', margin: '4px auto' }}></div>}
              </div>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
              <div style={{ textAlign: 'center', flex: 1, borderRight: '1px solid #f1f5f9' }}>
                <h2 style={{ margin: 0, fontSize: 18 }}>{att.emergency || "00"}</h2>
                <p style={{ fontSize: 11, color: '#64748b', margin: 0 }}>{isAr ? "طوارئ" : "Emergency"}</p>
              </div>
              <div style={{ textAlign: 'center', flex: 1, borderRight: '1px solid #f1f5f9' }}>
                <h2 style={{ margin: 0, fontSize: 18 }}>{att.absent || "00"}</h2>
                <p style={{ fontSize: 11, color: '#64748b', margin: 0 }}>{isAr ? "غائب" : "Absent"}</p>
              </div>
              <div style={{ textAlign: 'center', flex: 1 }}>
                <h2 style={{ margin: 0, fontSize: 18 }}>{att.late || "00"}</h2>
                <p style={{ fontSize: 11, color: '#64748b', margin: 0 }}>{isAr ? "متأخر" : "Late"}</p>
              </div>
            </div>
            <div className={styles.attendanceRingWrap}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={attendanceData} innerRadius={60} outerRadius={80} dataKey="value" stroke="none">
                    {attendanceData.map((entry, index) => <Cell key={`cell-${index}`} fill={entry.color} />)}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', textAlign: 'center' }}>
                <h2 style={{ margin: 0, fontSize: 24 }}>{att.present || "00"}</h2>
                <p style={{ margin: 0, fontSize: 12, color: '#64748b' }}>{isAr ? "حاضر" : "Present"}</p>
              </div>
            </div>
            <Link href="/dashboard/attendance" style={{ textDecoration: 'none' }}>
              <button style={{ width: '100%', padding: 10, background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: 8, marginTop: 16, cursor: 'pointer', fontWeight: 600, color: '#334155' }}>
                {isAr ? "عرض الكل" : "View All"}
              </button>
            </Link>
          </div>

          {/* Best Performers */}
          <div className={styles.starCardsRow}>
            <div className={`${styles.starCard} ${styles.green}`}>
              <img src="/icons/best-performer.png" alt="" style={{ position: 'absolute', left: 12, top: 20, width: 64, height: 'auto', opacity: 0.8, pointerEvents: 'none' }} />
              <div className={styles.starTitle}>{isAr ? "أفضل أداء" : "Best Performer"}</div>
              <div className={styles.starNav}>
                <button className={styles.starNavBtn}><ChevronLeft size={14} /></button>
                <button className={styles.starNavBtn}><ChevronRight size={14} /></button>
              </div>
              <h3 className={styles.starName}>{isAr ? "أ/ سارة" : "Ms Sara"}</h3>
              <p className={styles.starSub}>{isAr ? "معلمة فيزياء" : "Physics Teacher"}</p>
              <div style={{ width: 100, height: 100, background: 'rgba(255,255,255,0.2)', borderTopLeftRadius: 50, borderTopRightRadius: 50, marginTop: 'auto', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', overflow: 'hidden' }}>
                <img src="/icons/best-performer-avatar.png" alt="Ms Sara" style={{ width: '85%', height: 'auto', objectFit: 'contain', marginBottom: '-5px' }} />
              </div>
            </div>
            <div className={`${styles.starCard} ${styles.blue}`}>
              <img src="/icons/star-student.png" alt="" style={{ position: 'absolute', left: 12, top: 20, width: 64, height: 'auto', opacity: 0.8, pointerEvents: 'none' }} />
              <div className={styles.starTitle}>{isAr ? "طلاب متميزون" : "Star Students"}</div>
              <div className={styles.starNav}>
                <button className={styles.starNavBtn}><ChevronLeft size={14} /></button>
                <button className={styles.starNavBtn}><ChevronRight size={14} /></button>
              </div>
              <h3 className={styles.starName}>{isAr ? "أحمد" : "Ahmed"}</h3>
              <p className={styles.starSub}>A12</p>
              <div style={{ width: 100, height: 100, background: 'rgba(255,255,255,0.2)', borderTopLeftRadius: 50, borderTopRightRadius: 50, marginTop: 'auto', display: 'flex', alignItems: 'flex-end', justifyContent: 'center', overflow: 'hidden' }}>
                <img src="/icons/star-student-avatar.png" alt="Ahmed" style={{ width: '85%', height: 'auto', objectFit: 'contain', marginBottom: '-5px' }} />
              </div>
            </div>
          </div>

          {/* Notice Board */}
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3 className={styles.cardTitle}>{isAr ? "لوحة الإعلانات" : "Notice Board"}</h3>
              <Link href="/dashboard/notifications" className={styles.cardSubtitle} style={{ color: '#3b82f6', fontWeight: 600, textDecoration: 'none' }}>{isAr ? "عرض الكل" : "View All"}</Link>
            </div>
            <div className={styles.list} style={{ maxHeight: 188, overflowY: 'auto', paddingRight: 8 }}>
              {notifications.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '24px 0', color: '#94a3b8', fontSize: 13 }}>
                  <Bell size={24} style={{ marginBottom: 8, opacity: 0.5 }} />
                  <p style={{ margin: 0 }}>{isAr ? "لا توجد تنبيهات بعد" : "No notifications yet"}</p>
                </div>
              ) : (
                notifications.slice(0, 3).map((n: any) => {
                  const sentDate = new Date(n.sentAt);
                  const daysAgo = Math.max(0, Math.floor((Date.now() - sentDate.getTime()) / (1000 * 60 * 60 * 24)));
                  const formattedSentDate = sentDate.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
                  const typeColors: Record<string, { bg: string; color: string }> = {
                    GENERAL: { bg: '#e0f2fe', color: '#0ea5e9' },
                    ABSENCE: { bg: '#fee2e2', color: '#ef4444' },
                    HOMEWORK: { bg: '#ede9fe', color: '#8b5cf6' },
                    RESULT: { bg: '#dcfce7', color: '#10b981' },
                    FEE_DUE: { bg: '#fef3c7', color: '#f59e0b' },
                    BUS: { bg: '#cffafe', color: '#06b6d4' },
                  };
                  const tc = typeColors[n.type] || typeColors.GENERAL;
                  return (
                    <div key={n.id} className={styles.listItem}>
                      <div style={{ width: 32, height: 32, borderRadius: '50%', background: tc.bg, color: tc.color, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                        <FileText size={16} />
                      </div>
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <h4 style={{ margin: '0 0 4px 0', fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{n.title}</h4>
                        <p style={{ margin: 0, fontSize: 11, color: '#64748b', display: 'flex', alignItems: 'center', gap: 4 }}>
                          <Calendar size={10} /> {isAr ? "أضيف في:" : "Added on:"} {formattedSentDate}
                        </p>
                      </div>
                      <div style={{ fontSize: 11, fontWeight: 600, background: 'var(--ov-divider)', color: 'var(--ov-text-soft)', padding: '4px 8px', borderRadius: 4, whiteSpace: 'nowrap', flexShrink: 0 }}>
                        {daysAgo === 0 ? (isAr ? "اليوم" : "Today") : (isAr ? `${daysAgo} أيام` : `${daysAgo} Days`)}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>
        </div>

        {/* COLUMN 3 */}
        <div className={styles.colFlex}>
          {/* Quick Links */}
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3 className={styles.cardTitle}>{isAr ? "روابط سريعة" : "Quick Links"}</h3>
            </div>
            <div className={styles.quickLinksGrid}>
              <Link href="/dashboard/subjects" target="_blank" rel="noopener noreferrer" className={styles.quickLinkItem} style={{ textDecoration: 'none' }}>
                <div className={styles.quickLinkCircle} style={{ background: '#dcfce7', color: '#16a34a' }}><BookOpen size={24} /></div>
                <span className={styles.quickLinkLabel}>{isAr ? "المواد" : "Subjects"}</span>
              </Link>
              <Link href="/dashboard/schedules" target="_blank" rel="noopener noreferrer" className={styles.quickLinkItem} style={{ textDecoration: 'none' }}>
                <div className={styles.quickLinkCircle} style={{ background: '#e0f2fe', color: '#0ea5e9' }}><Megaphone size={24} /></div>
                <span className={styles.quickLinkLabel}>{isAr ? "الفعاليات" : "Events"}</span>
              </Link>
              <Link href="/dashboard/attendance" target="_blank" rel="noopener noreferrer" className={styles.quickLinkItem} style={{ textDecoration: 'none' }}>
                <div className={styles.quickLinkCircle} style={{ background: '#ffedd5', color: '#ea580c' }}><ClipboardList size={24} /></div>
                <span className={styles.quickLinkLabel}>{isAr ? "الحضور" : "Attendance"}</span>
              </Link>
              <Link href="/dashboard/exams" target="_blank" rel="noopener noreferrer" className={styles.quickLinkItem} style={{ textDecoration: 'none' }}>
                <div className={styles.quickLinkCircle} style={{ background: '#ccfbf1', color: '#0d9488' }}><Award size={24} /></div>
                <span className={styles.quickLinkLabel}>{isAr ? "الاختبارات" : "Exams"}</span>
              </Link>
              <Link href="/dashboard/messages" target="_blank" rel="noopener noreferrer" className={styles.quickLinkItem} style={{ textDecoration: 'none' }}>
                <div className={styles.quickLinkCircle} style={{ background: '#ffe4e6', color: '#e11d48' }}><MessageSquare size={24} /></div>
                <span className={styles.quickLinkLabel}>{isAr ? "الرسائل" : "Messages"}</span>
              </Link>
              <Link href="/dashboard/reports" target="_blank" rel="noopener noreferrer" className={styles.quickLinkItem} style={{ textDecoration: 'none' }}>
                <div className={styles.quickLinkCircle} style={{ background: '#dbeafe', color: '#3b82f6' }}><FileText size={24} /></div>
                <span className={styles.quickLinkLabel}>{isAr ? "التقارير" : "Reports"}</span>
              </Link>
            </div>
          </div>

          {/* Academic Classes */}
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3 className={styles.cardTitle}>{isAr ? "الفصول الأكاديمية" : "Academic Classes"}</h3>
              <Link href="/dashboard/classes" className={styles.cardSubtitle} style={{ color: '#3b82f6', fontWeight: 600, textDecoration: 'none' }}>+ {isAr ? "إضافة جديد" : "Add New"}</Link>
            </div>
            <div style={{ maxHeight: 220, overflowY: 'auto', paddingRight: 4 }}>
              {ov?.academicClasses && ov.academicClasses.length > 0 ? (
                ov.academicClasses.map((cls, idx) => {
                  const percent = Math.min(100, Math.round((cls.studentsCount / (cls.capacity || 1)) * 100));
                  const barColor = percent > 90 ? '#ef4444' : percent > 70 ? '#f59e0b' : '#10b981';
                  return (
                    <div key={cls.id || idx} className={styles.progressItem}>
                      <div className={styles.progressHeader} style={{ marginBottom: 8 }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                          <div className={styles.avatar} style={{ width: 32, height: 32, fontSize: 14, borderRadius: '8px', background: 'rgba(14, 165, 233, 0.15)', color: '#0ea5e9' }}>🏫</div>
                          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <span style={{ fontWeight: 600, fontSize: 13, color: 'var(--ov-text)' }}>{cls.name} {cls.section}</span>
                            <span style={{ fontSize: 11, color: 'var(--ov-muted)' }}>
                              {cls.room ? `${isAr ? 'غرفة' : 'Room'} ${cls.room}` : ''}
                              {cls.room && cls.floor ? ' • ' : ''}
                              {cls.floor ? `${isAr ? 'طابق' : 'Floor'} ${cls.floor}` : ''}
                              {!cls.room && !cls.floor ? (isAr ? 'غير محدد' : 'Not assigned') : ''}
                            </span>
                          </div>
                        </div>
                        <span style={{ fontSize: 12, fontWeight: 700, color: 'var(--ov-text)' }}>
                          {cls.studentsCount} <span style={{ color: 'var(--ov-muted)', fontSize: 11, fontWeight: 500 }}>/ {cls.capacity}</span>
                        </span>
                      </div>
                      <div className={styles.progressBarBg}>
                        <div className={styles.progressFill} style={{ width: `${percent}%`, background: barColor }}></div>
                      </div>
                    </div>
                  );
                })
              ) : (
                <div style={{ textAlign: 'center', padding: '24px 0', color: 'var(--ov-muted)', fontSize: 13 }}>
                  <p>{isAr ? "لا توجد فصول أكاديمية حتى الآن" : "No academic classes yet"}</p>
                </div>
              )}
            </div>
          </div>

          {/* Performance */}
          <div className={styles.card}>
            <div className={styles.cardHeader}>
              <h3 className={styles.cardTitle}>{isAr ? "أداء المنصة" : "Platform Performance"}</h3>
            </div>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 12, fontSize: 12, fontWeight: 600 }}>
                  <span style={{ color: '#3b82f6' }}>■ {isAr ? "مرتفع" : "High"}:</span><span>{pp.high}</span>
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginBottom: 12, fontSize: 12, fontWeight: 600 }}>
                  <span style={{ color: '#f59e0b' }}>■ {isAr ? "متوسط" : "Medium"}:</span><span>{pp.medium}</span>
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center', fontSize: 12, fontWeight: 600 }}>
                  <span style={{ color: '#ef4444' }}>■ {isAr ? "منخفض" : "Low"}:</span><span>{pp.low}</span>
                </div>
              </div>
              <div style={{ width: 100, height: 100, position: 'relative' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={performanceData} innerRadius={25} outerRadius={45} dataKey="value" stroke="none">
                      {performanceData.map((entry, index) => <Cell key={`cell-${index}`} fill={entry.color} />)}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', fontWeight: 700, fontSize: 14 }}>
                  {healthScore}%
                </div>
              </div>
            </div>
          </div>

          {/* Fees Stats */}
          <div className={styles.card} style={{ display: 'flex', flexDirection: 'column' }}>
            <div className={styles.feeSummaryItem}>
              <span className={styles.feeSummaryLabel}>{isAr ? "إجمالي المصروفات المحصلة" : "Total Fees Collected"}</span>
              <div className={styles.feeSummaryRow}>
                <span className={styles.feeSummaryValue}>
                  {ov ? `EGP ${Number(ov.totalEarnings).toLocaleString(undefined, { minimumFractionDigits: 2 })}` : "..."}
                </span>
                <span className={`${styles.statBadge} ${styles.up}`}>+ {ov?.totalEarnings ? "100" : "0"}%</span>
              </div>
            </div>
            <div className={styles.feeSummaryItem}>
              <span className={styles.feeSummaryLabel}>{isAr ? "الغرامات المحصلة حتى اليوم" : "Fine Collected till date"}</span>
              <div className={styles.feeSummaryRow}>
                <span className={styles.feeSummaryValue}>
                  {ov ? `EGP ${Number(ov.totalFines).toLocaleString(undefined, { minimumFractionDigits: 2 })}` : "..."}
                </span>
                <span className={`${styles.statBadge} ${styles.up}`}>+ 0%</span>
              </div>
            </div>
            <div className={styles.feeSummaryItem}>
              <span className={styles.feeSummaryLabel}>{isAr ? "طلاب لم يدفعوا" : "Student Not Paid"}</span>
              <div className={styles.feeSummaryRow}>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  {ov && ov.unpaidStudents?.recent?.length > 0 ? (
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <div style={{ display: 'flex', marginRight: 8 }}>
                        {ov.unpaidStudents.recent.map((inv: any, idx: number) => (
                          <div
                            key={idx}
                            style={{
                              width: 28, height: 28, borderRadius: '50%', background: '#e2e8f0',
                              border: '2px solid #fff', marginLeft: idx === 0 ? 0 : -8,
                              display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', zIndex: 10 - idx
                            }}
                            title={inv.student.user.fullName}
                          >
                            {inv.student.photo ? (
                              <img src={inv.student.photo} alt={inv.student.user.fullName} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                            ) : (
                              <span style={{ fontSize: 10, fontWeight: 600, color: '#475569' }}>{inv.student.user.fullName.charAt(0)}</span>
                            )}
                          </div>
                        ))}
                      </div>
                      <span className={styles.feeSummaryValue} style={{ fontSize: 14 }}>
                        {ov.unpaidStudents.count > ov.unpaidStudents.recent.length
                          ? `+${ov.unpaidStudents.count - ov.unpaidStudents.recent.length}`
                          : ''}
                      </span>
                    </div>
                  ) : (
                    <span className={styles.feeSummaryValue}>{ov?.unpaidStudents?.count ?? "..."}</span>
                  )}
                </div>
                <span className={`${styles.statBadge} ${styles.down}`}>Unpaid</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ACTION RIBBON */}
      <div className={styles.actionRibbon}>
        <Link href="/dashboard/reports" target="_blank" rel="noopener noreferrer" className={`${styles.ribbonCard} ${styles.yellow}`} style={{ textDecoration: 'none' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div className={styles.ribbonIcon}><FileText size={20} /></div>
            <span>{isAr ? "التقارير" : "Reports"}</span>
          </div>
          <ChevronRight size={20} />
        </Link>
        <Link href="/dashboard/transport" target="_blank" rel="noopener noreferrer" className={`${styles.ribbonCard} ${styles.green}`} style={{ textDecoration: 'none' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div className={styles.ribbonIcon}><Bus size={20} /></div>
            <span>{isAr ? "وسائل النقل" : "Transportation"}</span>
          </div>
          <ChevronRight size={20} />
        </Link>
        <Link href="/dashboard/communication/zoom" target="_blank" rel="noopener noreferrer" className={`${styles.ribbonCard} ${styles.red}`} style={{ textDecoration: 'none' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div className={styles.ribbonIcon}><Video size={20} /></div>
            <span>{isAr ? "اجتماعات زووم" : "Zoom Meetings"}</span>
          </div>
          <ChevronRight size={20} />
        </Link>
        <Link href="/dashboard/archive" target="_blank" rel="noopener noreferrer" className={`${styles.ribbonCard} ${styles.blue}`} style={{ textDecoration: 'none' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div className={styles.ribbonIcon}><Archive size={20} /></div>
            <span>{isAr ? "الأرشيف" : "Archives"}</span>
          </div>
          <ChevronRight size={20} />
        </Link>
      </div>
    </div>
  );
}
