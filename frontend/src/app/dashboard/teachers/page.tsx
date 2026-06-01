"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, X, User as UserIcon, Mail, Briefcase, Award, MapPin, Phone, Settings, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";
import TeacherWizard from "@/components/dashboard/TeacherWizard";
import TeacherProfileModal from "@/components/dashboard/TeacherProfileModal";

const modalOverlayStyle: React.CSSProperties = { position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(15, 23, 42, 0.4)", backdropFilter: "blur(4px)", zIndex: 1000, display: "flex", alignItems: "center", justifyContent: "center", padding: "20px" };
const modalContentStyle: React.CSSProperties = { width: "100%", maxWidth: "800px", background: "var(--glass-bg)", borderRadius: "24px", padding: "40px", maxHeight: "95vh", overflowY: "auto", border: "1px solid var(--glass-border)", boxShadow: "0 20px 40px rgba(0,0,0,0.1)" };

export default function TeachersPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [selectedTeacher, setSelectedTeacher] = useState<any>(null);
  const [teacherToEdit, setTeacherToEdit] = useState<any>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["teachers"],
    queryFn: async () => (await api.get("/teachers")).data.data
  });

  const createMutation = useMutation({
    mutationFn: (payload: any) => api.post("/teachers", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["teachers"] });
      setIsModalOpen(false);
    },
    onError: (error: any) => alert(error.response?.data?.message || "Failed to create teacher")
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: any }) => api.put(`/teachers/${id}`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["teachers"] });
      setIsEditModalOpen(false);
      setTeacherToEdit(null);
    },
    onError: (error: any) => alert(error.response?.data?.message || "Failed to update teacher")
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/teachers/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["teachers"] }),
    onError: (error: any) => alert(error.response?.data?.message || "Failed to delete teacher")
  });

  return (
    <div className="teachers-module" dir={isAr ? "rtl" : "ltr"}>
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "24px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{t('mod_teachers_title' as TranslationKey) || "Teachers"}</h2>
          <p style={{ color: "var(--dash-muted-strong)" }}>{t('mod_teachers_desc' as TranslationKey) || "Manage faculty members"}</p>
        </div>
        <button className="btn primary" onClick={() => setIsModalOpen(true)} style={{ borderRadius: "12px" }}>
          <Plus size={18} /> {t('btn_add_teacher' as TranslationKey) || "Add Teacher"}
        </button>
      </div>

      <div className="premium-table-wrapper card-glass" style={{ padding: "0", overflow: "hidden" }}>
        <table className="premium-table">
          <thead>
            <tr>
              <th style={isAr ? { textAlign: "right" } : {}}>{isAr ? "الاسم بالكامل" : "Full Name"}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{isAr ? "المادة / الوظيفة" : "Subject / Job"}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{isAr ? "الفصول المخصصة" : "Assigned Classes"}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{isAr ? "المرحلة" : "Stage"}</th>
              <th style={isAr ? { textAlign: "right" } : {}}>{isAr ? "التواصل" : "Contact"}</th>
              <th style={{ textAlign: isAr ? "left" : "right" }}>{isAr ? "إجراءات" : "Actions"}</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr>
                <td colSpan={6} style={{ textAlign: "center", padding: "60px", color: "var(--glass-text-muted)" }}>
                  <div className="spinner-large" style={{ margin: "0 auto 12px" }} />
                  {isAr ? "جاري تحميل البيانات..." : "Loading faculty data..."}
                </td>
              </tr>
            ) : data?.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ textAlign: "center", padding: "60px", color: "var(--glass-text-muted)" }}>
                  {isAr ? "لا يوجد معلمين مطابغين للبحث." : "No teachers found."}
                </td>
              </tr>
            ) : data?.map((teacher: any) => (
              <tr key={teacher.id}>
                <td>
                  <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                    <div style={{ width: "36px", height: "36px", borderRadius: "10px", background: "var(--gradient-primary)", color: "#fff", display: "flex", alignItems: "center", justifyContent: "center", fontWeight: 700, fontSize: "14px" }}>
                      {teacher.user?.fullName?.[0] || "T"}
                    </div>
                    <div>
                      <div style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>{teacher.user?.fullName}</div>
                      <div style={{ fontSize: "11px", color: "var(--dash-muted-strong)" }}>ID: {teacher.code || "—"}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <span className="badge" style={{ background: "rgba(59, 130, 246, 0.1)", color: "#3b82f6", fontWeight: 600 }}>
                    {t(`data_${teacher.subject?.toUpperCase()}` as TranslationKey) || teacher.subject || t('data_GENERAL' as TranslationKey)}
                  </span>
                </td>
                <td>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: "4px", maxWidth: "200px" }}>
                    {teacher.teacherSubjects?.length > 0 ? (
                      teacher.teacherSubjects.map((ts: any) => (
                        <span key={ts.id} style={{ padding: "2px 8px", borderRadius: "6px", background: "rgba(16, 185, 129, 0.1)", color: "#10b981", fontSize: "11px", fontWeight: 600, whiteSpace: "nowrap" }}>
                          {ts.class?.name} ({ts.subject?.name})
                        </span>
                      ))
                    ) : (
                      <span style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{isAr ? "لا توجد" : "None"}</span>
                    )}
                  </div>
                </td>
                <td style={{ color: "var(--glass-text-secondary)" }}>
                  {t(`data_${teacher.stage?.toUpperCase()}` as TranslationKey) || teacher.stage || "—"}
                </td>
                <td>
                  <div style={{ fontSize: "12px", color: "var(--glass-text-secondary)" }}>
                    <div style={{ display: "flex", alignItems: "center", gap: "6px" }}><Mail size={12} /> {teacher.user?.email}</div>
                    <div style={{ display: "flex", alignItems: "center", gap: "6px", marginTop: "4px" }}><Phone size={12} /> {teacher.phone || "—"}</div>
                  </div>
                </td>
                <td style={{ textAlign: isAr ? "left" : "right" }}>
                  <div style={{ display: "flex", gap: "8px", justifyContent: "flex-end" }}>
                    <button 
                      className="btn outline" 
                      style={{ padding: "6px 12px", fontSize: "12px" }}
                      onClick={() => setSelectedTeacher(teacher)}
                    >
                      {isAr ? "عرض الملف" : "View Profile"}
                    </button>
                    <button 
                      className="btn outline" 
                      style={{ padding: "6px", width: "32px", height: "32px" }}
                      onClick={() => { setTeacherToEdit(teacher); setIsEditModalOpen(true); }}
                      title={isAr ? "تعديل" : "Edit"}
                    >
                      <Settings size={14} />
                    </button>
                    <button 
                      className="btn outline" 
                      style={{ padding: "6px", width: "32px", height: "32px", color: "#ef4444" }}
                      onClick={() => window.confirm(isAr ? "هل أنت متأكد من حذف هذا المدرس؟" : "Are you sure you want to delete this teacher?") && deleteMutation.mutate(teacher.id)}
                      title={isAr ? "حذف" : "Delete"}
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* TEACHER WIZARD MODAL */}
      {isModalOpen && (
        <div style={modalOverlayStyle}>
          <div className="card-glass active" onClick={e => e.stopPropagation()} style={modalContentStyle}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
              <h3 style={{ fontSize: "24px", fontWeight: 800, color: "var(--glass-text-primary)" }}>
                {isAr ? "إضافة مدرس جديد" : "Add New Teacher"}
              </h3>
              <button onClick={() => setIsModalOpen(false)} style={{ background: "rgba(255,255,255,0.05)", border: "1px solid var(--glass-border)", color: "var(--glass-text-secondary)", cursor: "pointer", width: "36px", height: "36px", borderRadius: "10px", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <X size={20} />
              </button>
            </div>
            
            <TeacherWizard 
              onSave={(payload) => createMutation.mutate(payload)} 
              onCancel={() => setIsModalOpen(false)}
              isPending={createMutation.isPending}
            />
          </div>
        </div>
      )}

      {selectedTeacher && (
        <TeacherProfileModal 
          teacher={selectedTeacher} 
          onClose={() => setSelectedTeacher(null)} 
        />
      )}

      {/* EDIT TEACHER MODAL */}
      {isEditModalOpen && teacherToEdit && (
        <div style={modalOverlayStyle}>
          <div style={modalContentStyle}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "24px" }}>
              <h2 style={{ fontSize: "20px", fontWeight: 800 }}>{isAr ? "تعديل بيانات المدرس" : "Edit Teacher Info"}</h2>
              <button onClick={() => { setIsEditModalOpen(false); setTeacherToEdit(null); }} style={{ color: "var(--glass-text-secondary)" }}><X /></button>
            </div>
            <TeacherWizard 
              initialData={teacherToEdit}
              onSave={(payload) => updateMutation.mutate({ id: teacherToEdit.id, payload })} 
              onCancel={() => { setIsEditModalOpen(false); setTeacherToEdit(null); }}
              isPending={updateMutation.isPending}
            />
          </div>
        </div>
      )}
    </div>
  );
}
