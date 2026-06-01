"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { 
  Plus, 
  UserPlus, 
  Users, 
  UserCheck, 
  GraduationCap, 
  Search, 
  Filter, 
  Mail,
  School,
  Hash,
  Loader2,
  Eye,
  Pencil,
  Trash2,
  X,
  User as UserIcon,
  LayoutDashboard
} from "lucide-react";
import Link from "next/link";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";

export default function StudentPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [search, setSearch] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingStudentId, setEditingStudentId] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    fullName: "",
    nameEn: "",
    nationalId: "",
    dob: "",
    gender: "MALE",
    email: "",
    gradeId: "",
    classId: "",
    rollNumber: "",
    status: "ACTIVE"
  });

  const { data: students, isLoading: loadingStudents, refetch } = useQuery({
    queryKey: ["students"],
    queryFn: async () => (await api.get("/students")).data.data,
    staleTime: 0,
    refetchOnMount: "always"
  });

  const { data: classes } = useQuery({
    queryKey: ["classes"],
    queryFn: async () => (await api.get("/classes")).data.data
  });

  const { data: grades } = useQuery({
    queryKey: ["grades"],
    queryFn: async () => (await api.get("/academic/grades")).data.data
  });

  const createMutation = useMutation({
    mutationFn: (payload: typeof formData) => api.post("/students", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["students"] });
      closeModal();
    },
    onError: (error: any) => alert(error.response?.data?.message || "Failed to create student")
  });

  const updateMutation = useMutation({
    mutationFn: (payload: any) => api.put(`/students/${editingStudentId}`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["students"] });
      closeModal();
    },
    onError: (error: any) => alert(error.response?.data?.message || "Failed to update student")
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/students/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["students"] });
      alert(isAr ? "تم سحب الطالب بنجاح" : "Student marked as withdrawn");
    }
  });

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (editingStudentId) {
      updateMutation.mutate(formData);
    } else {
      createMutation.mutate(formData);
    }
  };

  const handleDelete = (id: string) => {
    if (window.confirm(isAr ? "هل أنت متأكد من سحب هذا الطالب من المدرسة؟" : "Are you sure you want to withdraw this student?")) {
      deleteMutation.mutate(id);
    }
  };

  const openEditModal = (student: any) => {
    setEditingStudentId(student.id);
    setFormData({
      fullName: student.user?.fullName || "",
      nameEn: student.nameEn || "",
      nationalId: student.nationalId || "",
      dob: student.dob ? new Date(student.dob).toISOString().split('T')[0] : "",
      gender: student.gender || "MALE",
      email: student.user?.email || "",
      gradeId: student.gradeId || "",
      classId: student.classId || "",
      rollNumber: student.rollNumber || "",
      status: student.status || "ACTIVE"
    });
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setEditingStudentId(null);
    setFormData({ fullName: "", nameEn: "", nationalId: "", dob: "", gender: "MALE", email: "", gradeId: "", classId: "", rollNumber: "", status: "ACTIVE" });
  };

  const filteredData = students?.filter((s: any) => 
    s.user?.fullName?.toLowerCase().includes(search.toLowerCase()) ||
    s.rollNumber?.toLowerCase().includes(search.toLowerCase()) ||
    s.studentCode?.toLowerCase().includes(search.toLowerCase())
  );

  const stats = {
    total: students?.length || 0,
    active: students?.filter((s: any) => s.status === "ACTIVE").length || 0,
    classes: new Set(students?.map((s: any) => s.classId)).size || 0,
  };

  return (
    <div className="student-module" dir={isAr ? "rtl" : "ltr"}>
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "40px" }}>
        <div style={{ textAlign: isAr ? "right" : "left" }}>
          <h2 style={{ fontSize: "32px", fontWeight: 900, letterSpacing: "-1px", color: "var(--glass-text-primary)" }}>{t('mod_students_title' as TranslationKey)}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{t('mod_students_desc' as TranslationKey)}</p>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: "24px", marginBottom: "40px" }}>
        <div className="luxury-stat-card" style={{ "--accent-color": "#3b82f6" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div style={{ textAlign: isAr ? "right" : "left" }}>
                <h4 style={statLabelStyle}>{isAr ? "إجمالي الطلاب" : "Total Students"}</h4>
                <div style={statValueStyle}>{stats.total}</div>
              </div>
              <div style={statIconStyle("#3b82f6", "rgba(59, 130, 246, 0.1)")}>
                <Users size={22} color="#3b82f6" />
              </div>
            </div>
            <div style={statSubStyle}>{isAr ? "مسجلون في العام الحالي" : "Registered in current year"}</div>
          </div>
        </div>

        <div className="luxury-stat-card" style={{ "--accent-color": "#34d399" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div style={{ textAlign: isAr ? "right" : "left" }}>
                <h4 style={statLabelStyle}>{isAr ? "النشطون الآن" : "Active Now"}</h4>
                <div style={statValueStyle}>{stats.active}</div>
              </div>
              <div style={statIconStyle("#34d399", "rgba(52, 211, 153, 0.1)")}>
                <UserCheck size={22} color="#34d399" />
              </div>
            </div>
            <div style={{ ...statSubStyle, color: "#34d399", fontWeight: 600 }}>{isAr ? "منتظمون في الدراسة" : "Regular in classes"}</div>
          </div>
        </div>

        <div className="luxury-stat-card" style={{ "--accent-color": "#a855f7" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div style={{ textAlign: isAr ? "right" : "left" }}>
                <h4 style={statLabelStyle}>{isAr ? "الصفوف المسندة" : "Assigned Classes"}</h4>
                <div style={statValueStyle}>{stats.classes}</div>
              </div>
              <div style={statIconStyle("#a855f7", "rgba(168, 85, 247, 0.1)")}>
                <GraduationCap size={22} color="#a855f7" />
              </div>
            </div>
            <div style={{ ...statSubStyle, color: "#a855f7", fontWeight: 600 }}>{isAr ? "فصول دراسية مكتملة" : "Complete class sections"}</div>
          </div>
        </div>
      </div>

      {/* Filter Row */}
      <div className="card-glass" style={{ padding: "16px 24px", marginBottom: "24px", display: "flex", gap: "20px", alignItems: "center" }}>
        <div style={{ position: "relative", flex: 1 }}>
          <Search size={18} style={{ position: "absolute", left: isAr ? "auto" : "14px", right: isAr ? "14px" : "auto", top: "50%", transform: "translateY(-50%)", color: "var(--glass-text-muted)" }} />
          <input 
            type="text" 
            placeholder={isAr ? "ابحث باسم الطالب، الإيميل أو الكود..." : "Search students by name, email or code..."}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={searchFieldStyle(isAr)}
          />
        </div>
      </div>

      {/* Table */}
      <div className="premium-table-wrapper card-glass" style={{ padding: "0", overflow: "hidden" }}>
        <table className="premium-table">
          <thead>
            <tr>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('std_full_name' as TranslationKey) || 'Full Name'}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('std_roll_no' as TranslationKey) || 'Roll Number'}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('std_class' as TranslationKey) || 'Class'}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{isAr ? "كود الطالب" : "Student ID"}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{t('std_status' as TranslationKey) || 'Status'}</th>
              <th style={{ textAlign: "end" }}>{t('std_actions' as TranslationKey) || 'Actions'}</th>
            </tr>
          </thead>
          <tbody>
            {loadingStudents ? (
              <tr>
                <td colSpan={6} style={{ textAlign: "center", padding: "60px" }}>
                  <Loader2 className="animate-spin" size={32} style={{ margin: "0 auto", color: "var(--primary-light)" }} />
                </td>
              </tr>
            ) : filteredData?.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: "center", padding: "60px", color: "var(--glass-text-muted)" }}>
                  {isAr ? "لا يوجد طلاب مطابقين للبحث." : "No students found matching your criteria."}
                </td>
              </tr>
            ) : filteredData?.map((student: any) => (
              <tr key={student.id}>
                <td>
                  <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    {student.photo ? (
                      <img 
                        src={student.photo} 
                        alt={student.user?.fullName} 
                        style={{ width: "38px", height: "38px", borderRadius: "10px", objectFit: "cover", border: "2px solid var(--glass-border)" }}
                        onError={(e) => { (e.target as any).src = ""; (e.target as any).style.display = 'none'; }} 
                      />
                    ) : (
                      <div style={{ width: "38px", height: "38px", borderRadius: "10px", background: "var(--gradient-primary)", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: "14px", flexShrink: 0 }}>
                        {student.user?.fullName?.[0]?.toUpperCase() || "S"}
                      </div>
                    )}
                    <div>
                      <div style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>{student.user?.fullName}</div>
                      <div style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{student.user?.email}</div>
                    </div>
                  </div>
                </td>
                <td><code style={{ background: "rgba(59, 130, 246, 0.1)", color: "#3b82f6", padding: "4px 10px", borderRadius: "8px", fontSize: "14px", fontWeight: 700 }}>#{student.rollNumber || "—"}</code></td>
                <td>
                  <span className="badge" style={{ background: "rgba(59, 130, 246, 0.1)", color: "#3b82f6" }}>
                    {student.class?.name} {student.class?.section && `- ${student.class.section}`}
                  </span>
                </td>
                <td style={{ fontFamily: "monospace", fontSize: "14px", color: "var(--primary-light)", fontWeight: 700 }}>{student.studentCode || "—"}</td>
                <td>
                    <span className={`badge ${student.status === 'ACTIVE' ? 'present' : 'absent'}`}>
                        {student.status === 'ACTIVE' ? (isAr ? "نشط" : "Active") : (isAr ? "منسحب" : "Withdrawn")}
                    </span>
                </td>
                <td style={{ textAlign: "end" }}>
                  <div style={{ display: "flex", gap: "8px", justifyContent: "flex-end" }}>
                    <Link href={`/dashboard/students/${student.id}`}>
                      <button style={{ ...actionBtnStyle, color: "#a855f7" }} title="Student Dashboard">
                        <LayoutDashboard size={18} />
                      </button>
                    </Link>
                    <Link href={`/dashboard/admissions/${student.fromApplication?.id || ""}`}>
                      <button style={actionBtnStyle} title="View Application">
                        <Eye size={18} />
                      </button>
                    </Link>
                    <button style={actionBtnStyle} onClick={() => openEditModal(student)} title="Edit Student">
                      <Pencil size={18} />
                    </button>
                    <button style={{ ...actionBtnStyle, color: "#f87171" }} onClick={() => handleDelete(student.id)} title="Withdraw Student">
                      <Trash2 size={18} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* QUICK ADD / EDIT MODAL */}
      {isModalOpen && (
        <div style={modalOverlayStyle} onClick={closeModal}>
          <div className="card-glass active" onClick={e => e.stopPropagation()} style={modalContentStyle}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <div style={{ width: "40px", height: "40px", borderRadius: "12px", background: "var(--gradient-primary)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                   {editingStudentId ? <Pencil size={20} color="#fff" /> : <Plus size={20} color="#fff" />}
                </div>
                <h3 style={{ fontSize: "20px", fontWeight: 700, color: "var(--glass-text-primary)" }}>{editingStudentId ? (isAr ? "تعديل بيانات الطالب" : "Edit Student") : t('btn_add_student' as TranslationKey)}</h3>
              </div>
              <button onClick={closeModal} style={closeBtnStyle}><X size={20} /></button>
            </div>
            
            <form onSubmit={handleSave} style={{ display: "grid", gap: "24px" }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div className="form-group">
                  <label style={labelStyle}>{isAr ? "الاسم بالكامل" : "Full Name"}</label>
                  <input type="text" className="form-input" value={formData.fullName} onChange={e => setFormData({...formData, fullName: e.target.value})} required style={inputStyle} />
                </div>
                <div className="form-group">
                  <label style={labelStyle}>{isAr ? "البريد الإلكتروني" : "Email Address"}</label>
                  <input type="email" className="form-input" value={formData.email} onChange={e => setFormData({...formData, email: e.target.value})} required disabled={!!editingStudentId} style={inputStyle} />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div className="form-group">
                  <label style={labelStyle}>{isAr ? "رقم الجلوس" : "Roll Number"}</label>
                  <input type="text" className="form-input" value={formData.rollNumber} onChange={e => setFormData({...formData, rollNumber: e.target.value})} style={inputStyle} />
                </div>
                <div className="form-group">
                  <label style={labelStyle}>{isAr ? "المرحلة الدراسية" : "Assigned Grade"}</label>
                  <select className="form-input" value={formData.gradeId} onChange={e => setFormData({...formData, gradeId: e.target.value})} style={{ ...inputStyle, appearance: "none" }}>
                    <option value="">{isAr ? "اختر المرحلة" : "Select Grade"}</option>
                    {grades?.map((g: any) => <option key={g.id} value={g.id}>{isAr ? g.name : g.nameEn}</option>)}
                  </select>
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div className="form-group">
                  <label style={labelStyle}>{isAr ? "الفصل الدراسي" : "Assigned Class"}</label>
                  <select className="form-input" value={formData.classId} onChange={e => setFormData({...formData, classId: e.target.value})} style={{ ...inputStyle, appearance: "none" }}>
                    <option value="">{isAr ? "اختر الفصل" : "Select Class"}</option>
                    {classes?.filter((c:any) => !formData.gradeId || c.gradeId === formData.gradeId).map((c: any) => (
                      <option key={c.id} value={c.id}>{c.name} - {c.section}</option>
                    ))}
                  </select>
                </div>
                {editingStudentId && (
                  <div className="form-group">
                    <label style={labelStyle}>{isAr ? "حالة الطالب" : "Student Status"}</label>
                    <select className="form-input" value={formData.status} onChange={e => setFormData({...formData, status: e.target.value})} style={{ ...inputStyle, appearance: "none" }}>
                      <option value="ACTIVE">{isAr ? "نشط" : "Active"}</option>
                      <option value="WITHDRAWN">{isAr ? "منسحب" : "Withdrawn"}</option>
                      <option value="SUSPENDED">{isAr ? "موقوف" : "Suspended"}</option>
                      <option value="GRADUATED">{isAr ? "متخرج" : "Graduated"}</option>
                    </select>
                  </div>
                )}
              </div>

              <div style={{ display: "flex", gap: "12px", marginTop: "12px" }}>
                <button type="submit" disabled={createMutation.isPending || updateMutation.isPending} className="btn primary" style={{ flex: 1, padding: "14px", borderRadius: "14px", fontWeight: 700 }}>
                  {editingStudentId ? (updateMutation.isPending ? (isAr ? "جاري الحفظ..." : "Saving...") : (isAr ? "تحديث الطالب" : "Update Student")) : (createMutation.isPending ? (isAr ? "جاري الإضافة..." : "Creating...") : (isAr ? "تأكيد وإضافة" : "Confirm & Add"))}
                </button>
                <button type="button" className="btn outline" onClick={closeModal} style={{ flex: 1, borderRadius: "14px" }}>
                  {isAr ? "إلغاء" : "Cancel"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

const statLabelStyle = { color: "var(--glass-text-secondary)", fontSize: "14px", fontWeight: 600 };
const statValueStyle = { fontSize: "32px", fontWeight: 800, marginTop: "8px", color: "var(--glass-text-primary)" };
const statIconStyle = (color: string, bg: string) => ({ 
  width: "48px", height: "48px", borderRadius: "12px", background: bg, display: "flex", alignItems: "center", justifyContent: "center" 
});
const statSubStyle = { marginTop: "20px", fontSize: "13px", color: "var(--glass-text-muted)" };
const labelStyle = { display: "block", fontSize: "12px", fontWeight: 700, textTransform: "uppercase" as const, marginBottom: "8px", color: "var(--glass-text-secondary)" };
const inputStyle = { width: "100%", padding: "12px 16px", borderRadius: "10px", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", color: "var(--glass-text-primary)", fontSize: "15px", outline: "none" };
const modalOverlayStyle = { position: "fixed" as const, top: 0, left: 0, right: 0, bottom: 0, background: "var(--modal-overlay-bg)", backdropFilter: "blur(10px)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000, padding: "20px" };
const modalContentStyle = { width: "100%", maxWidth: "500px", padding: "40px", border: "1px solid var(--glass-border)", boxShadow: "0 40px 80px rgba(0,0,0,0.5)", borderRadius: "28px", background: "var(--glass-bg)" };
const searchFieldStyle = (isAr: boolean) => ({ 
  width: "100%", background: "var(--glass-input-bg)", border: "1px solid var(--glass-input-border)", borderRadius: "12px", padding: isAr ? "12px 42px 12px 14px" : "12px 14px 12px 42px", color: "var(--glass-text-primary)", outline: "none" 
});
const actionBtnStyle = { width: "36px", height: "36px", border: "1px solid var(--glass-border)", background: "var(--glass-icon-bg)", color: "var(--glass-text-secondary)", borderRadius: "10px", display: "inline-flex", alignItems: "center", justifyContent: "center", cursor: "pointer", transition: "0.2s" };
const closeBtnStyle = { background: "rgba(255,255,255,0.05)", border: "1px solid var(--glass-border)", color: "var(--glass-text-secondary)", cursor: "pointer", width: "36px", height: "36px", borderRadius: "10px", display: "flex", alignItems: "center", justifyContent: "center" };
