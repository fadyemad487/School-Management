"use client";

import { useState, useEffect } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";
import { 
  UserCheck, 
  Users, 
  Calendar, 
  Clock, 
  Bell, 
  CheckCircle, 
  XCircle, 
  AlertCircle,
  ArrowRight,
  Loader2
} from "lucide-react";
import Link from "next/link";

export default function MarkAttendancePage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  
  const [selectedClassId, setSelectedClassId] = useState<string>("");
  const [selectedPeriod, setSelectedPeriod] = useState<number>(1);
  const [attendanceDate, setAttendanceDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [studentStatuses, setStudentStatuses] = useState<Record<string, "PRESENT" | "ABSENT" | "LATE" | "EXCUSED">>({});

  // 1. Fetch School Settings
  const { data: settings } = useQuery({
    queryKey: ["school-settings"],
    queryFn: async () => (await api.get("/settings")).data.data
  });

  // 2. Fetch Classes
  const { data: classes } = useQuery({
    queryKey: ["classes"],
    queryFn: async () => (await api.get("/classes")).data.data
  });

  // 3. Fetch Students
  const { data: students, isLoading: loadingStudents } = useQuery({
    queryKey: ["class-students", selectedClassId],
    queryFn: async () => (await api.get(`/classes/${selectedClassId}/students`)).data.data,
    enabled: !!selectedClassId
  });

  useEffect(() => {
    if (students) {
      const initial: any = {};
      students.forEach((s: any) => {
        initial[s.id] = "PRESENT";
      });
      setStudentStatuses(initial);
    }
  }, [students]);

  const mutation = useMutation({
    mutationFn: (payload: any) => api.post("/attendance/bulk", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["attendance"] });
      alert(t('sett_save_success'));
    }
  });

  const handleMarkAll = (status: "PRESENT" | "ABSENT") => {
    if (!students) return;
    const update: any = {};
    students.forEach((s: any) => { update[s.id] = status; });
    setStudentStatuses(update);
  };

  const handleStatusChange = (studentId: string, status: any) => {
    setStudentStatuses(prev => ({ ...prev, [studentId]: status }));
  };

  const handleSave = () => {
    if (!selectedClassId) return;
    
    const records = Object.entries(studentStatuses).map(([studentId, status]) => ({
      studentId,
      status,
      notes: ""
    }));

    mutation.mutate({
      date: attendanceDate,
      classId: selectedClassId,
      periodNumber: settings?.attendanceMode === "PERIODIC" ? selectedPeriod : undefined,
      records
    });
  };

  return (
    <div className="mark-attendance-module" style={{ paddingBottom: "120px" }} dir={isAr ? "rtl" : "ltr"}>
      {/* Header */}
      <div className="module-header" style={{ marginBottom: "32px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "8px", color: "var(--glass-text-muted)", marginBottom: "8px", fontSize: "14px" }}>
            <Link href="/dashboard/attendance" style={{ color: "inherit", textDecoration: "none" }}>{t('dash_attendance')}</Link>
            <ArrowRight size={14} style={{ transform: isAr ? "rotate(180deg)" : "none" }} />
            <span>{t('attn_mark_title')}</span>
          </div>
          <h2 style={{ fontSize: "32px", fontWeight: 900, letterSpacing: "-1px", color: "var(--glass-text-primary)" }}>{t('attn_mark_title')}</h2>
        </div>

        <div style={{ display: "flex", gap: "12px" }}>
          <button onClick={() => handleMarkAll("PRESENT")} className="btn outline" style={{ color: "#10b981", borderColor: "rgba(16, 185, 129, 0.3)" }}>
            <CheckCircle size={18} />
            {t('attn_mark_all_present')}
          </button>
        </div>
      </div>

      {/* Global Selectors Card */}
      <div className="card-glass" style={{ padding: "24px", marginBottom: "32px", display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: "24px", alignItems: "flex-end" }}>
        <div>
          <label style={labelStyle}>{t('attn_select_class')}</label>
          <select 
            value={selectedClassId} 
            onChange={e => setSelectedClassId(e.target.value)}
            style={inputStyle}
          >
            <option value="" style={{ color: "var(--glass-text-muted)" }}>-- {t('attn_select_class')} --</option>
            {classes?.map((c: any) => (
              <option key={c.id} value={c.id} style={{ color: "#000" }}>{c.name}</option>
            ))}
          </select>
        </div>

        <div>
          <label style={labelStyle}>Attendance Date</label>
          <input 
            type="date" 
            value={attendanceDate}
            onChange={e => setAttendanceDate(e.target.value)}
            style={inputStyle}
          />
        </div>

        {settings?.attendanceMode === "PERIODIC" && (
          <div>
            <label style={labelStyle}>{t('attn_select_period')}</label>
            <div style={{ display: "flex", gap: "8px", overflowX: "auto", padding: "4px" }}>
              {Array.from({ length: settings.periodsPerDay || 8 }).map((_, i) => (
                <button
                  key={i}
                  onClick={() => setSelectedPeriod(i + 1)}
                  style={periodButtonStyle(selectedPeriod === i + 1)}
                >
                  {i + 1}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Students List */}
      {!selectedClassId ? (
        <div className="card-glass" style={{ padding: "80px", textAlign: "center", color: "var(--glass-text-secondary)" }}>
          <Users size={64} style={{ marginBottom: "20px", opacity: 0.1, margin: "0 auto" }} />
          <h3 style={{ fontSize: "20px", fontWeight: 700, color: "var(--glass-text-primary)" }}>Select a Class</h3>
          <p style={{ marginTop: "8px", opacity: 0.6 }}>{t('attn_select_class')} to start marking attendance.</p>
        </div>
      ) : loadingStudents ? (
        <div style={{ textAlign: "center", padding: "80px" }}>
           <Loader2 className="animate-spin" size={32} style={{ margin: "0 auto", color: "var(--primary-light)" }} />
        </div>
      ) : (
        <div className="premium-table-wrapper card-glass" style={{ padding: "0" }}>
          <table className="premium-table">
            <thead>
              <tr>
                <th style={{ width: "80px" }}>#</th>
                <th style={isAr ? { textAlign: "right" } : {}}>Student Name</th>
                <th style={isAr ? { textAlign: "right" } : {}}>National ID</th>
                <th style={{ textAlign: "center", width: "450px" }}>Status</th>
              </tr>
            </thead>
            <tbody>
              {students?.map((s: any, index: number) => (
                <tr key={s.id}>
                  <td style={{ color: "var(--glass-text-muted)", fontSize: "13px" }}>{index + 1}</td>
                  <td>
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                       <div style={{ width: "32px", height: "32px", borderRadius: "8px", background: "var(--glass-icon-bg)", color: "var(--glass-text-primary)", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 800, fontSize: "12px" }}>
                          {(s.nameAr || s.user?.fullName)?.[0]}
                       </div>
                       <span style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>{s.nameAr || s.user?.fullName}</span>
                    </div>
                  </td>
                  <td style={{ fontSize: "13px", color: "var(--glass-text-secondary)", fontFamily: "monospace" }}>{s.nationalId || "---"}</td>
                  <td>
                    <div style={{ display: "flex", justifyContent: "center", gap: "10px" }}>
                      <StatusBtn 
                        active={studentStatuses[s.id] === "PRESENT"} 
                        type="PRESENT" 
                        label={t('stat_present')}
                        onClick={() => handleStatusChange(s.id, "PRESENT")} 
                      />
                      <StatusBtn 
                        active={studentStatuses[s.id] === "ABSENT"} 
                        type="ABSENT" 
                        label={t('stat_absent')}
                        onClick={() => handleStatusChange(s.id, "ABSENT")} 
                      />
                      <StatusBtn 
                        active={studentStatuses[s.id] === "LATE"} 
                        type="LATE" 
                        label={t('stat_late')}
                        onClick={() => handleStatusChange(s.id, "LATE")} 
                      />
                      <StatusBtn 
                        active={studentStatuses[s.id] === "EXCUSED"} 
                        type="EXCUSED" 
                        label={t('stat_excused')}
                        onClick={() => handleStatusChange(s.id, "EXCUSED")} 
                      />
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Floating Footer Action */}
      {selectedClassId && students && (
        <div className="card-glass" style={floatingFooterStyle(isAr)}>
          <div style={{ display: "flex", gap: "32px", alignItems: "center" }}>
             <div style={{ textAlign: isAr ? "right" : "left" }}>
                <p style={{ fontSize: "11px", textTransform: "uppercase", letterSpacing: "1px", color: "var(--glass-text-muted)" }}>Total Marked</p>
                <p style={{ fontWeight: 900, color: "var(--primary-light)", fontSize: "18px" }}>{students.length} Students</p>
             </div>
             <div style={{ width: "1px", height: "36px", background: "var(--glass-border)" }} />
             <div style={{ textAlign: isAr ? "right" : "left" }}>
                <p style={{ fontSize: "11px", textTransform: "uppercase", letterSpacing: "1px", color: "var(--glass-text-muted)" }}>Absence Queue</p>
                <p style={{ fontWeight: 900, color: "#f87171", fontSize: "18px" }}>
                  {Object.values(studentStatuses).filter(v => v === "ABSENT").length} Alerts
                </p>
             </div>
          </div>

          <button 
            disabled={mutation.isPending}
            onClick={handleSave}
            className="btn primary" 
            style={{ 
              padding: "16px 48px", 
              borderRadius: "16px", 
              fontWeight: 800, 
              display: "flex", 
              alignItems: "center", 
              gap: "12px",
              boxShadow: "0 15px 30px rgba(99, 102, 241, 0.3)"
            }}
          >
            <Bell size={20} />
            {mutation.isPending ? "Syncing..." : t('attn_save_notify')}
          </button>
        </div>
      )}
    </div>
  );
}

// Components & Helpers
function StatusBtn({ active, type, label, onClick }: any) {
  const colors: any = {
    PRESENT: { bg: "rgba(16, 185, 129, 0.1)", border: "#10b981", color: "#10b981" },
    ABSENT: { bg: "rgba(239, 68, 68, 0.1)", border: "#ef4444", color: "#ef4444" },
    LATE: { bg: "rgba(245, 158, 11, 0.1)", border: "#f59e0b", color: "#f59e0b" },
    EXCUSED: { bg: "rgba(59, 130, 246, 0.1)", border: "#3b82f6", color: "#3b82f6" }
  };

  const style = {
    padding: "10px 18px",
    borderRadius: "10px",
    fontSize: "13px",
    fontWeight: 700,
    cursor: "pointer",
    transition: "all 0.2s ease",
    background: active ? colors[type].bg : "var(--glass-icon-bg)",
    border: "1px solid",
    borderColor: active ? colors[type].border : "var(--glass-border)",
    color: active ? colors[type].color : "var(--glass-text-secondary)",
    minWidth: "100px",
    textAlign: "center" as const,
    boxShadow: active ? `0 4px 12px ${colors[type].bg}` : "none"
  };

  return <div onClick={onClick} style={style}>{label}</div>;
}

const labelStyle = { 
  display: "block", 
  fontSize: "12px", 
  fontWeight: 700, 
  textTransform: "uppercase" as const, 
  marginBottom: "10px", 
  color: "var(--glass-text-secondary)",
  letterSpacing: "0.05em"
};

const inputStyle = { 
  width: "100%", 
  padding: "14px 16px", 
  borderRadius: "12px", 
  background: "var(--glass-input-bg)", 
  border: "1px solid var(--glass-input-border)", 
  color: "var(--glass-text-primary)", 
  fontSize: "15px", 
  outline: "none" 
};

const periodButtonStyle = (active: boolean) => ({
  minWidth: "40px",
  height: "40px",
  borderRadius: "10px",
  border: "1px solid",
  borderColor: active ? "var(--primary-light)" : "var(--glass-border)",
  background: active ? "var(--primary-light)" : "var(--glass-icon-bg)",
  color: active ? "#ffffff" : "var(--glass-text-primary)",
  fontWeight: 700,
  fontSize: "15px",
  cursor: "pointer",
  transition: "all 0.2s"
});

const floatingFooterStyle = (isAr: boolean) => ({
  position: "fixed" as const, 
  bottom: "40px", 
  right: isAr ? "auto" : "40px", 
  left: isAr ? "40px" : "auto",
  padding: "20px 40px",
  zIndex: 1000,
  display: "flex",
  alignItems: "center",
  gap: "40px",
  boxShadow: "0 30px 60px rgba(0,0,0,0.5)",
  background: "var(--glass-bg)",
  border: "1px solid var(--glass-border)",
  borderRadius: "24px",
  backdropFilter: "blur(20px)"
});
