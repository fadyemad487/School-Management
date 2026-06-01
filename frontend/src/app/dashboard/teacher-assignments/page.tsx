"use client";

import { useState, useMemo } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2, GraduationCap, BookOpen, School, Search, User, ChevronDown } from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";

export default function TeacherAssignmentsPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();

  const [selectedTeacherId, setSelectedTeacherId] = useState<string>("");
  const [assignForm, setAssignForm] = useState({ subjectId: "", classId: "" });
  const [searchQuery, setSearchQuery] = useState("");

  // ── Data Fetching ──────────────────────────────────────────
  const { data: teachers = [], isLoading: loadingTeachers } = useQuery({
    queryKey: ["teachers"],
    queryFn: async () => (await api.get("/teachers")).data.data,
  });

  const { data: classes = [] } = useQuery({
    queryKey: ["classes"],
    queryFn: async () => (await api.get("/classes")).data.data,
  });

  const { data: subjects = [] } = useQuery({
    queryKey: ["subjects"],
    queryFn: async () => (await api.get("/subjects")).data.data,
  });

  const { data: assignments = [], isLoading: loadingAssignments } = useQuery({
    queryKey: ["teacher-assignments", selectedTeacherId],
    queryFn: async () => {
      if (!selectedTeacherId) return [];
      return (await api.get(`/teachers/${selectedTeacherId}/assignments`)).data.data;
    },
    enabled: !!selectedTeacherId,
  });

  // ── Mutations ──────────────────────────────────────────────
  const assignMutation = useMutation({
    mutationFn: (payload: { subjectId: string; classId: string }) =>
      api.post(`/teachers/${selectedTeacherId}/assignments`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["teacher-assignments", selectedTeacherId] });
      setAssignForm({ subjectId: "", classId: "" });
    },
    onError: (e: any) => alert(e.response?.data?.message || "Failed to assign"),
  });

  const unassignMutation = useMutation({
    mutationFn: (assignmentId: string) =>
      api.delete(`/teachers/${selectedTeacherId}/assignments/${assignmentId}`),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: ["teacher-assignments", selectedTeacherId] }),
    onError: (e: any) => alert(e.response?.data?.message || "Failed to unassign"),
  });

  // ── Derived ────────────────────────────────────────────────
  const selectedTeacher = useMemo(
    () => teachers.find((t: any) => t.id === selectedTeacherId),
    [teachers, selectedTeacherId]
  );

  const filteredTeachers = useMemo(() => {
    if (!searchQuery.trim()) return teachers;
    const q = searchQuery.toLowerCase();
    return teachers.filter(
      (t: any) =>
        t.user?.fullName?.toLowerCase().includes(q) ||
        t.subject?.toLowerCase().includes(q) ||
        t.code?.toLowerCase().includes(q)
    );
  }, [teachers, searchQuery]);

  const canAssign = assignForm.subjectId && assignForm.classId && selectedTeacherId;

  return (
    <div dir={isAr ? "rtl" : "ltr"} style={{ maxWidth: "1400px", margin: "0 auto" }}>
      {/* ── Page Header ──────────────────────────────────── */}
      <div style={{ marginBottom: "32px" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "8px" }}>
          <div style={{
            width: "48px", height: "48px", borderRadius: "16px",
            background: "var(--gradient-primary)", display: "flex",
            alignItems: "center", justifyContent: "center"
          }}>
            <GraduationCap size={24} color="#fff" />
          </div>
          <div>
            <h1 style={{ fontSize: "28px", fontWeight: 900, color: "var(--glass-text-primary)", margin: 0 }}>
              {isAr ? "تخصيص المعلمين" : "Teacher Assignments"}
            </h1>
            <p style={{ fontSize: "14px", color: "var(--glass-text-muted)", margin: 0 }}>
              {isAr ? "خصّص كل معلم للفصول والمواد التي يدرّسها" : "Assign each teacher to their classes and subjects"}
            </p>
          </div>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "340px 1fr", gap: "28px" }}>
        {/* ═══════════════════════════════════════════════════ */}
        {/* LEFT PANEL: Teacher Selector                       */}
        {/* ═══════════════════════════════════════════════════ */}
        <div className="card-glass" style={{ padding: "24px", borderRadius: "24px", height: "fit-content", maxHeight: "80vh", display: "flex", flexDirection: "column" }}>
          <h3 style={{ fontSize: "16px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "16px", display: "flex", alignItems: "center", gap: "8px" }}>
            <User size={18} />
            {isAr ? "اختر المعلم" : "Select Teacher"}
          </h3>

          {/* Search */}
          <div style={{ position: "relative", marginBottom: "16px" }}>
            <Search size={16} style={{ position: "absolute", top: "50%", transform: "translateY(-50%)", [isAr ? "right" : "left"]: "12px", color: "var(--glass-text-muted)" }} />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder={isAr ? "ابحث بالاسم أو المادة..." : "Search by name or subject..."}
              style={{
                width: "100%", padding: "10px 12px", [isAr ? "paddingRight" : "paddingLeft"]: "36px",
                background: "rgba(0,0,0,0.03)", border: "1px solid var(--glass-border)",
                borderRadius: "12px", color: "var(--glass-text-primary)", fontSize: "13px",
                outline: "none", transition: "0.2s"
              }}
            />
          </div>

          {/* Teacher List */}
          <div style={{ flex: 1, overflowY: "auto", display: "flex", flexDirection: "column", gap: "6px" }}>
            {loadingTeachers ? (
              <div style={{ textAlign: "center", padding: "40px 0", color: "var(--glass-text-muted)" }}>
                <div className="spinner-large" style={{ margin: "0 auto 12px" }} />
                {isAr ? "جاري التحميل..." : "Loading..."}
              </div>
            ) : filteredTeachers.length === 0 ? (
              <div style={{ textAlign: "center", padding: "40px 0", color: "var(--glass-text-muted)", fontSize: "13px" }}>
                {isAr ? "لا يوجد معلمين" : "No teachers found"}
              </div>
            ) : (
              filteredTeachers.map((teacher: any) => {
                const isActive = teacher.id === selectedTeacherId;
                return (
                  <button
                    key={teacher.id}
                    onClick={() => setSelectedTeacherId(teacher.id)}
                    style={{
                      width: "100%", padding: "12px 14px", borderRadius: "14px",
                      background: isActive ? "var(--primary-glow)" : "transparent",
                      border: isActive ? "1.5px solid var(--primary-light)" : "1.5px solid transparent",
                      cursor: "pointer", textAlign: isAr ? "right" : "left",
                      display: "flex", alignItems: "center", gap: "12px",
                      transition: "all 0.2s ease",
                      color: "var(--glass-text-primary)"
                    }}
                  >
                    <div style={{
                      width: "38px", height: "38px", borderRadius: "12px", flexShrink: 0,
                      background: isActive ? "var(--gradient-primary)" : "rgba(59, 130, 246, 0.1)",
                      color: isActive ? "#fff" : "var(--primary-light)",
                      display: "flex", alignItems: "center", justifyContent: "center",
                      fontWeight: 800, fontSize: "15px", transition: "0.2s"
                    }}>
                      {teacher.user?.fullName?.[0] || "T"}
                    </div>
                    <div style={{ overflow: "hidden", flex: 1 }}>
                      <div style={{
                        fontWeight: 700, fontSize: "14px",
                        color: isActive ? "var(--primary-light)" : "var(--glass-text-primary)",
                        whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis"
                      }}>
                        {teacher.user?.fullName}
                      </div>
                      <div style={{ fontSize: "11px", color: "var(--glass-text-muted)", marginTop: "2px" }}>
                        {teacher.subject || (isAr ? "بدون مادة" : "No subject")} • {teacher.code || "—"}
                      </div>
                    </div>
                    {isActive && (
                      <div style={{
                        width: "8px", height: "8px", borderRadius: "50%",
                        background: "var(--primary-light)", flexShrink: 0,
                        boxShadow: "0 0 8px var(--primary-light)"
                      }} />
                    )}
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* ═══════════════════════════════════════════════════ */}
        {/* RIGHT PANEL: Assignment Management                 */}
        {/* ═══════════════════════════════════════════════════ */}
        <div>
          {!selectedTeacherId ? (
            /* Empty State */
            <div className="card-glass" style={{
              padding: "80px 40px", borderRadius: "24px", textAlign: "center",
              border: "2px dashed var(--glass-border)"
            }}>
              <GraduationCap size={56} style={{ color: "var(--glass-text-muted)", marginBottom: "16px" }} />
              <h3 style={{ fontSize: "20px", fontWeight: 800, color: "var(--glass-text-secondary)", marginBottom: "8px" }}>
                {isAr ? "اختر معلمًا من القائمة" : "Select a teacher from the list"}
              </h3>
              <p style={{ color: "var(--glass-text-muted)", fontSize: "14px" }}>
                {isAr ? "اضغط على اسم المعلم لعرض وإدارة تخصيصاته" : "Click a teacher's name to view and manage their assignments"}
              </p>
            </div>
          ) : (
            <>
              {/* Teacher Info Header */}
              <div className="card-glass" style={{ padding: "24px", borderRadius: "20px", marginBottom: "20px" }}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "16px" }}>
                  <div style={{ display: "flex", alignItems: "center", gap: "16px" }}>
                    <div style={{
                      width: "56px", height: "56px", borderRadius: "18px",
                      background: "var(--gradient-primary)", color: "#fff",
                      display: "flex", alignItems: "center", justifyContent: "center",
                      fontSize: "22px", fontWeight: 900
                    }}>
                      {selectedTeacher?.user?.fullName?.[0] || "T"}
                    </div>
                    <div>
                      <h2 style={{ fontSize: "22px", fontWeight: 900, color: "var(--glass-text-primary)", margin: 0 }}>
                        {selectedTeacher?.user?.fullName}
                      </h2>
                      <div style={{ display: "flex", gap: "8px", marginTop: "6px", flexWrap: "wrap" }}>
                        <span style={{ padding: "3px 10px", borderRadius: "8px", background: "rgba(59, 130, 246, 0.1)", color: "#3b82f6", fontSize: "12px", fontWeight: 700 }}>
                          {selectedTeacher?.subject || (isAr ? "بدون مادة" : "No subject")}
                        </span>
                        <span style={{ padding: "3px 10px", borderRadius: "8px", background: "rgba(16, 185, 129, 0.1)", color: "#10b981", fontSize: "12px", fontWeight: 700 }}>
                          {selectedTeacher?.stage || "—"}
                        </span>
                        <span style={{ padding: "3px 10px", borderRadius: "8px", background: "rgba(139, 92, 246, 0.1)", color: "#8b5cf6", fontSize: "12px", fontWeight: 700 }}>
                          {assignments.length} {isAr ? "تخصيص" : "assignments"}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Assign Form */}
              <div className="card-glass" style={{ padding: "24px", borderRadius: "20px", marginBottom: "20px" }}>
                <h3 style={{ fontSize: "15px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "16px", display: "flex", alignItems: "center", gap: "8px" }}>
                  <Plus size={18} style={{ color: "var(--primary-light)" }} />
                  {isAr ? "إضافة تخصيص جديد" : "Add New Assignment"}
                </h3>
                <div style={{ display: "flex", gap: "12px", alignItems: "flex-end", flexWrap: "wrap" }}>
                  {/* Subject Dropdown */}
                  <div style={{ flex: 1, minWidth: "200px" }}>
                    <label style={{ display: "block", fontSize: "12px", fontWeight: 700, color: "var(--glass-text-muted)", marginBottom: "6px" }}>
                      <BookOpen size={12} style={{ display: "inline", verticalAlign: "middle", marginInlineEnd: "4px" }} />
                      {isAr ? "المادة" : "Subject"}
                    </label>
                    <select
                      value={assignForm.subjectId}
                      onChange={(e) => setAssignForm({ ...assignForm, subjectId: e.target.value })}
                      style={{
                        width: "100%", padding: "11px 14px",
                        background: "rgba(0,0,0,0.03)", border: "1px solid var(--glass-border)",
                        borderRadius: "12px", color: "var(--glass-text-primary)", fontSize: "14px",
                        cursor: "pointer", outline: "none", transition: "0.2s"
                      }}
                    >
                      <option value="">{isAr ? "-- اختر المادة --" : "-- Select Subject --"}</option>
                      {subjects.map((s: any) => (
                        <option key={s.id} value={s.id}>{s.name}</option>
                      ))}
                    </select>
                  </div>

                  {/* Class Dropdown */}
                  <div style={{ flex: 1, minWidth: "200px" }}>
                    <label style={{ display: "block", fontSize: "12px", fontWeight: 700, color: "var(--glass-text-muted)", marginBottom: "6px" }}>
                      <School size={12} style={{ display: "inline", verticalAlign: "middle", marginInlineEnd: "4px" }} />
                      {isAr ? "الفصل" : "Class"}
                    </label>
                    <select
                      value={assignForm.classId}
                      onChange={(e) => setAssignForm({ ...assignForm, classId: e.target.value })}
                      style={{
                        width: "100%", padding: "11px 14px",
                        background: "rgba(0,0,0,0.03)", border: "1px solid var(--glass-border)",
                        borderRadius: "12px", color: "var(--glass-text-primary)", fontSize: "14px",
                        cursor: "pointer", outline: "none", transition: "0.2s"
                      }}
                    >
                      <option value="">{isAr ? "-- اختر الفصل --" : "-- Select Class --"}</option>
                      {classes.map((c: any) => (
                        <option key={c.id} value={c.id}>{c.name} ({c.section})</option>
                      ))}
                    </select>
                  </div>

                  {/* Assign Button */}
                  <button
                    onClick={() => canAssign && assignMutation.mutate(assignForm)}
                    disabled={!canAssign || assignMutation.isPending}
                    style={{
                      padding: "11px 28px", borderRadius: "12px", border: "none",
                      background: canAssign ? "var(--gradient-primary)" : "rgba(0,0,0,0.05)",
                      color: canAssign ? "#fff" : "var(--glass-text-muted)",
                      fontWeight: 800, cursor: canAssign ? "pointer" : "not-allowed",
                      display: "flex", alignItems: "center", gap: "8px", fontSize: "14px",
                      transition: "all 0.25s ease",
                      boxShadow: canAssign ? "0 8px 20px rgba(59, 130, 246, 0.3)" : "none",
                      minWidth: "140px", justifyContent: "center"
                    }}
                  >
                    {assignMutation.isPending ? (
                      <div className="spinner-small" style={{ width: "16px", height: "16px", border: "2px solid rgba(255,255,255,0.3)", borderTopColor: "#fff", borderRadius: "50%", animation: "spin 0.8s linear infinite" }} />
                    ) : (
                      <Plus size={18} />
                    )}
                    {isAr ? "تخصيص" : "Assign"}
                  </button>
                </div>
              </div>

              {/* Assignments Grid */}
              <div>
                <h3 style={{ fontSize: "15px", fontWeight: 800, color: "var(--glass-text-primary)", marginBottom: "16px" }}>
                  {isAr ? `التخصيصات الحالية (${assignments.length})` : `Current Assignments (${assignments.length})`}
                </h3>

                {loadingAssignments ? (
                  <div className="card-glass" style={{ padding: "60px", textAlign: "center", borderRadius: "20px" }}>
                    <div className="spinner-large" style={{ margin: "0 auto 12px" }} />
                    <p style={{ color: "var(--glass-text-muted)" }}>{isAr ? "جاري التحميل..." : "Loading..."}</p>
                  </div>
                ) : assignments.length === 0 ? (
                  <div className="card-glass" style={{
                    padding: "60px 32px", textAlign: "center", borderRadius: "20px",
                    border: "2px dashed var(--glass-border)"
                  }}>
                    <BookOpen size={40} style={{ color: "var(--glass-text-muted)", marginBottom: "12px" }} />
                    <p style={{ color: "var(--glass-text-muted)", fontSize: "15px", fontWeight: 600 }}>
                      {isAr ? "لم يتم تخصيص فصول أو مواد لهذا المعلم بعد" : "No assignments yet for this teacher"}
                    </p>
                    <p style={{ color: "var(--glass-text-muted)", fontSize: "13px", marginTop: "4px" }}>
                      {isAr ? "استخدم النموذج أعلاه لإضافة أول تخصيص" : "Use the form above to add the first assignment"}
                    </p>
                  </div>
                ) : (
                  <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "16px" }}>
                    {assignments.map((a: any) => (
                      <div
                        key={a.id}
                        className="card-glass"
                        style={{
                          padding: "20px", borderRadius: "18px",
                          display: "flex", justifyContent: "space-between", alignItems: "center",
                          transition: "all 0.25s ease",
                          borderLeft: isAr ? "none" : "4px solid var(--primary-light)",
                          borderRight: isAr ? "4px solid var(--primary-light)" : "none"
                        }}
                      >
                        <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
                          <div style={{
                            width: "44px", height: "44px", borderRadius: "14px",
                            background: "rgba(59, 130, 246, 0.08)",
                            display: "flex", alignItems: "center", justifyContent: "center"
                          }}>
                            <BookOpen size={20} style={{ color: "var(--primary-light)" }} />
                          </div>
                          <div>
                            <div style={{ fontWeight: 800, fontSize: "15px", color: "var(--glass-text-primary)" }}>
                              {a.subject?.name}
                            </div>
                            <div style={{ fontSize: "12px", color: "var(--glass-text-muted)", marginTop: "3px", display: "flex", alignItems: "center", gap: "4px" }}>
                              <School size={12} />
                              {a.class?.name} {a.class?.section ? `(${a.class.section})` : ""}
                            </div>
                          </div>
                        </div>
                        <button
                          onClick={() => {
                            if (window.confirm(isAr ? "هل أنت متأكد من إلغاء هذا التخصيص؟" : "Remove this assignment?")) {
                              unassignMutation.mutate(a.id);
                            }
                          }}
                          style={{
                            background: "rgba(239, 68, 68, 0.06)", border: "none",
                            color: "#ef4444", borderRadius: "10px", width: "36px", height: "36px",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            cursor: "pointer", transition: "all 0.2s ease", flexShrink: 0
                          }}
                          title={isAr ? "إلغاء التخصيص" : "Remove"}
                        >
                          <Trash2 size={16} />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </>
          )}
        </div>
      </div>

      <style jsx>{`
        @keyframes spin { to { transform: rotate(360deg); } }
        button:hover { opacity: 0.92; }
        .card-glass:hover { box-shadow: 0 8px 24px rgba(0,0,0,0.06); }
      `}</style>
    </div>
  );
}
