"use client";

import { useState, useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";
import { CheckCircle2, XCircle, Clock, FileText } from "lucide-react";

export default function AttendancePage() {
  const { t, isAr } = useTranslation();
  const [selectedClass, setSelectedClass] = useState("");
  const [attendanceDate, setAttendanceDate] = useState(new Date().toISOString().split("T")[0]);

  const { data: classes } = useQuery({ queryKey: ["classes"], queryFn: async () => (await api.get("/classes")).data.data });
  const { data: students } = useQuery({ queryKey: ["students"], queryFn: async () => (await api.get("/students")).data.data });
  const { data: attendanceRecords } = useQuery({ queryKey: ["attendance"], queryFn: async () => (await api.get("/attendance")).data.data });

  const classStudents = useMemo(() => {
    if (!selectedClass || !students) return [];
    return students.filter((s: any) => s.classId === selectedClass);
  }, [students, selectedClass]);

  // Filter attendance records for the selected class and date
  const todaysAttendance = useMemo(() => {
    if (!attendanceRecords || !selectedClass) return [];
    return attendanceRecords.filter((record: any) => {
      const recordDate = new Date(record.date).toISOString().split("T")[0];
      return record.classId === selectedClass && recordDate === attendanceDate;
    });
  }, [attendanceRecords, selectedClass, attendanceDate]);

  // Map student ID to their attendance record
  const attendanceMap = useMemo(() => {
    const map: Record<string, any> = {};
    todaysAttendance.forEach((record: any) => {
      map[record.studentId] = record;
    });
    return map;
  }, [todaysAttendance]);

  const stats = useMemo(() => {
    let present = 0;
    let absent = 0;
    let late = 0;
    let excused = 0;
    let unrecorded = 0;

    classStudents.forEach((s: any) => {
      const record = attendanceMap[s.id];
      if (!record) {
        unrecorded++;
      } else if (record.status === "PRESENT") present++;
      else if (record.status === "ABSENT") absent++;
      else if (record.status === "LATE") late++;
      else if (record.status === "EXCUSED") excused++;
    });

    return { present, absent, late, excused, unrecorded };
  }, [classStudents, attendanceMap]);

  const renderStatusBadge = (status: string | undefined) => {
    if (!status) return <span style={{ color: "var(--dash-muted-strong)", fontSize: "14px" }}>{isAr ? "لم يُسجل بعد" : "Not recorded"}</span>;
    if (status === "PRESENT") return <span style={{ display: "inline-flex", alignItems: "center", gap: "6px", color: "#10b981", background: "rgba(16,185,129,0.1)", padding: "4px 10px", borderRadius: "20px", fontSize: "13px", fontWeight: 600 }}><CheckCircle2 size={16} /> {isAr ? "حاضر" : "Present"}</span>;
    if (status === "ABSENT") return <span style={{ display: "inline-flex", alignItems: "center", gap: "6px", color: "#ef4444", background: "rgba(239,68,68,0.1)", padding: "4px 10px", borderRadius: "20px", fontSize: "13px", fontWeight: 600 }}><XCircle size={16} /> {isAr ? "غائب" : "Absent"}</span>;
    if (status === "LATE") return <span style={{ display: "inline-flex", alignItems: "center", gap: "6px", color: "#f59e0b", background: "rgba(245,158,11,0.1)", padding: "4px 10px", borderRadius: "20px", fontSize: "13px", fontWeight: 600 }}><Clock size={16} /> {isAr ? "متأخر" : "Late"}</span>;
    if (status === "EXCUSED") return <span style={{ display: "inline-flex", alignItems: "center", gap: "6px", color: "#8b5cf6", background: "rgba(139,92,246,0.1)", padding: "4px 10px", borderRadius: "20px", fontSize: "13px", fontWeight: 600 }}><FileText size={16} /> {isAr ? "عذر" : "Excused"}</span>;
    return <span>{status}</span>;
  };

  return (
    <div className="attendance-module" dir={isAr ? "rtl" : "ltr"}>
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px", flexWrap: "wrap", gap: "16px" }}>
        <div>
          <h2 style={{ fontSize: "24px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{t('mod_attendance_title' as TranslationKey) || "Attendance"}</h2>
          <p style={{ color: "var(--dash-muted-strong)" }}>{isAr ? "متابعة وتقارير الحضور والغياب (يتم التسجيل من قبل المعلمين عبر التطبيق)" : "Attendance records and reports (Recorded by teachers via App)"}</p>
        </div>
      </div>

      <div className="card-glass" style={{ padding: "24px", marginBottom: "24px" }}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: "20px" }}>
          <div>
            <label style={{ display: "block", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-secondary)", marginBottom: "8px" }}>{isAr ? "اختر الفصل" : "Select Class"}</label>
            <select 
              value={selectedClass} 
              onChange={e => setSelectedClass(e.target.value)}
              style={{ width: "100%", padding: "12px", background: "rgba(0,0,0,0.02)", border: "1px solid var(--glass-border)", borderRadius: "10px", color: "var(--glass-text-primary)", outline: "none" }}
            >
              <option value="">{isAr ? "اختر..." : "Select..."}</option>
              {classes?.map((c: any) => <option key={c.id} value={c.id}>{c.name} {c.section}</option>)}
            </select>
          </div>
          <div>
            <label style={{ display: "block", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-secondary)", marginBottom: "8px" }}>{isAr ? "تاريخ الحضور" : "Attendance Date"}</label>
            <input 
              type="date" 
              value={attendanceDate} 
              onChange={e => setAttendanceDate(e.target.value)}
              style={{ width: "100%", padding: "12px", background: "rgba(0,0,0,0.02)", border: "1px solid var(--glass-border)", borderRadius: "10px", color: "var(--glass-text-primary)", outline: "none" }}
            />
          </div>
        </div>
      </div>

      {selectedClass ? (
        <>
          {/* Quick Stats Banner */}
          <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(120px, 1fr))", gap: "16px", marginBottom: "24px" }}>
             <div className="card-glass" style={{ padding: "16px", textAlign: "center", borderLeft: "4px solid #10b981" }}>
               <div style={{ fontSize: "24px", fontWeight: 800, color: "#10b981" }}>{stats.present}</div>
               <div style={{ fontSize: "13px", color: "var(--dash-muted-strong)" }}>{isAr ? "حاضر" : "Present"}</div>
             </div>
             <div className="card-glass" style={{ padding: "16px", textAlign: "center", borderLeft: "4px solid #ef4444" }}>
               <div style={{ fontSize: "24px", fontWeight: 800, color: "#ef4444" }}>{stats.absent}</div>
               <div style={{ fontSize: "13px", color: "var(--dash-muted-strong)" }}>{isAr ? "غائب" : "Absent"}</div>
             </div>
             <div className="card-glass" style={{ padding: "16px", textAlign: "center", borderLeft: "4px solid #f59e0b" }}>
               <div style={{ fontSize: "24px", fontWeight: 800, color: "#f59e0b" }}>{stats.late}</div>
               <div style={{ fontSize: "13px", color: "var(--dash-muted-strong)" }}>{isAr ? "متأخر" : "Late"}</div>
             </div>
             <div className="card-glass" style={{ padding: "16px", textAlign: "center", borderLeft: "4px solid var(--glass-border)" }}>
               <div style={{ fontSize: "24px", fontWeight: 800, color: "var(--glass-text-secondary)" }}>{stats.unrecorded}</div>
               <div style={{ fontSize: "13px", color: "var(--dash-muted-strong)" }}>{isAr ? "لم يسجل" : "Unrecorded"}</div>
             </div>
          </div>

          <div className="premium-table-wrapper card-glass" style={{ padding: "0", overflow: "hidden" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "16px 20px", borderBottom: "1px solid var(--glass-border)", background: "rgba(0,0,0,0.01)" }}>
              <div style={{ fontWeight: 600, color: "var(--glass-text-primary)" }}>
                {isAr ? `تلاميذ الفصل (${classStudents.length})` : `Class Students (${classStudents.length})`}
              </div>
            </div>
            <table className="premium-table">
              <thead>
                <tr>
                  <th style={{ textAlign: isAr ? "right" : "left", width: "40%" }}>{isAr ? "الطالب" : "Student"}</th>
                  <th style={{ textAlign: "center" }}>{isAr ? "الحالة" : "Status"}</th>
                </tr>
              </thead>
              <tbody>
                {classStudents.length === 0 ? (
                  <tr><td colSpan={2} style={{ textAlign: "center", padding: "40px", color: "var(--dash-muted-strong)" }}>{isAr ? "لا يوجد طلاب في هذا الفصل" : "No students in this class"}</td></tr>
                ) : (
                  classStudents.map((s: any) => {
                    const record = attendanceMap[s.id];
                    return (
                      <tr key={s.id}>
                        <td>
                          <div style={{ fontWeight: 600, color: "var(--glass-text-primary)" }}>{s.nameAr || s.user?.fullName}</div>
                          <div style={{ fontSize: "12px", color: "var(--glass-text-secondary)" }}>{s.nationalId || `ID: ${s.id.slice(0,8)}`}</div>
                        </td>
                        <td style={{ textAlign: "center" }}>
                          {renderStatusBadge(record?.status)}
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <div className="card-glass" style={{ padding: "60px 20px", textAlign: "center", color: "var(--dash-muted-strong)" }}>
          {isAr ? "الرجاء اختيار فصل والتاريخ لعرض تقرير الحضور والغياب." : "Please select a class and date to view the attendance report."}
        </div>
      )}
    </div>
  );
}
