"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, X, User, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";

const labelStyle = { display: "block", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-secondary)", marginBottom: "8px" };
const inputStyle = { width: "100%", padding: "12px", background: "rgba(0,0,0,0.02)", border: "1px solid var(--glass-border)", borderRadius: "10px", color: "var(--glass-text-primary)", fontSize: "14px", transition: "0.2s" };
const modalOverlayStyle: React.CSSProperties = { position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(15, 23, 42, 0.4)", backdropFilter: "blur(4px)", zIndex: 1000, display: "flex", alignItems: "center", justifyContent: "center", padding: "20px" };
const modalContentStyle: React.CSSProperties = { width: "100%", maxWidth: "500px", background: "var(--glass-bg)", borderRadius: "24px", padding: "32px", maxHeight: "90vh", overflowY: "auto", border: "1px solid var(--glass-border)", boxShadow: "0 20px 40px rgba(0,0,0,0.1)" };

export default function ClassesPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    section: "",
    maxCapacity: 40,
    roomNumber: "",
    floor: "",
    gradeId: "",
  });

  const { data: classes, isLoading } = useQuery({ queryKey: ["classes"], queryFn: async () => (await api.get("/classes")).data.data });
  const { data: grades } = useQuery({ queryKey: ["grades"], queryFn: async () => (await api.get("/academic/grades")).data.data });
  const { data: teachers } = useQuery({ queryKey: ["teachers"], queryFn: async () => (await api.get("/teachers")).data.data });

  const createMutation = useMutation({
    mutationFn: (payload: typeof formData) => api.post("/classes", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["classes"] });
      setIsModalOpen(false);
      setFormData({ name: "", section: "", maxCapacity: 40, roomNumber: "", floor: "", gradeId: "" });
    },
    onError: (error: any) => alert(error.response?.data?.message || "Failed to create class")
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/classes/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["classes"] }),
    onError: (error: any) => alert(error.response?.data?.message || "Failed to delete class")
  });

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    createMutation.mutate(formData);
  };

  return (
    <div className="classes-module" dir={isAr ? "rtl" : "ltr"}>
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "24px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{t('mod_classes_title' as TranslationKey) || "Classes"}</h2>
          <p style={{ color: "var(--dash-muted-strong)" }}>{t('mod_classes_desc' as TranslationKey) || "Manage academic sections"}</p>
        </div>
        <button className="btn primary" onClick={() => setIsModalOpen(true)} style={{ borderRadius: "12px" }}>
          <Plus size={18} /> {t('btn_add_class' as TranslationKey) || "Add Class"}
        </button>
      </div>

      <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "24px" }}>
        {isLoading ? (
          <p style={{ color: "var(--glass-text-muted)" }}>{t('ay_loading' as any)}</p>
        ) : classes?.map((schoolClass: any) => (
          <div key={schoolClass.id} className="luxury-stat-card" style={{ "--accent-color": "#8b5cf6" } as any}>
            <div className="luxury-stat-inner">
              <div className="l-stat-top">
                <div className="l-stat-icon" style={{ background: "rgba(249, 115, 22, 0.1)", color: "#f97316", border: "none", width: "auto", padding: "0 12px", borderRadius: "8px", fontSize: "14px", fontWeight: 700 }}>
                  {t('cl_section' as any)} <span dir="ltr" style={{ display: "inline-block", margin: "0 4px" }}>({schoolClass.section})</span>
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                  <div className="l-stat-trend" style={{ fontSize: "12px", color: "var(--glass-text-muted)", fontWeight: 600 }}>
                    {schoolClass.grade?.name || "General"}
                  </div>
                  <button 
                    onClick={() => {
                      if(window.confirm(isAr ? "هل أنت متأكد من حذف هذا الفصل؟" : "Are you sure you want to delete this class?")) {
                        deleteMutation.mutate(schoolClass.id);
                      }
                    }}
                    style={{ background: "rgba(239, 68, 68, 0.1)", border: "none", color: "#ef4444", borderRadius: "6px", width: "28px", height: "28px", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", transition: "0.2s" }}
                    title={isAr ? "حذف الفصل" : "Delete Class"}
                  >
                    <Trash2 size={14} />
                  </button>
                </div>
              </div>

              <div className="l-stat-body" style={{ marginBottom: "16px" }}>
                <div className="l-stat-val" style={{ fontSize: "22px" }}>{schoolClass.name}</div>
              </div>

              <div style={{ background: "rgba(0,0,0,0.02)", padding: "12px", borderRadius: "12px", display: "grid", gridTemplateColumns: "1fr 1fr", gap: "8px", border: "1px solid var(--glass-border)" }}>
                <div>
                  <div style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{t('cl_capacity' as any)}</div>
                  <div style={{ fontSize: "13px", fontWeight: 700, color: "var(--glass-text-primary)" }}>{schoolClass.maxCapacity} {t('cl_students' as any)}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{t('cl_room' as any)}</div>
                  <div style={{ fontSize: "13px", fontWeight: 700, color: "var(--glass-text-primary)" }}>{schoolClass.roomNumber || t('cl_unassigned' as any)}</div>
                </div>
                <div style={{ gridColumn: "span 2" }}>
                  <div style={{ fontSize: "11px", color: "var(--glass-text-muted)" }}>{t('cl_floor' as any)}</div>
                  <div style={{ fontSize: "13px", fontWeight: 700, color: "var(--glass-text-primary)" }}>{schoolClass.floor || t('cl_unassigned' as any)}</div>
                </div>
              </div>

              <div className="l-stat-bg-blob"></div>
            </div>
          </div>
        ))}
      </div>

      {/* QUICK ADD MODAL */}
      {isModalOpen && (
        <div style={modalOverlayStyle}>
          <div className="card-glass active" onClick={e => e.stopPropagation()} style={modalContentStyle}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
                <div style={{ width: "40px", height: "40px", borderRadius: "12px", background: "var(--gradient-primary)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <Plus size={20} color="#fff" />
                </div>
                <h3 style={{ fontSize: "20px", fontWeight: 700, color: "var(--glass-text-primary)" }}>{t('btn_add_class' as TranslationKey) || "Add Class"}</h3>
              </div>
              <button onClick={() => setIsModalOpen(false)} style={{ background: "rgba(255,255,255,0.05)", border: "1px solid var(--glass-border)", color: "var(--glass-text-secondary)", cursor: "pointer", width: "36px", height: "36px", borderRadius: "10px", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <X size={20} />
              </button>
            </div>

            <form onSubmit={handleSave} style={{ display: "grid", gap: "20px" }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                <div className="form-group">
                  <label style={labelStyle}>{t('cl_name' as any)}</label>
                  <input type="text" value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} required placeholder={t('cl_name_ph' as any)} style={inputStyle} />
                </div>
                <div className="form-group">
                  <label style={labelStyle}>{t('cl_section' as any)}</label>
                  <input type="text" value={formData.section} onChange={e => setFormData({ ...formData, section: e.target.value })} required placeholder={t('cl_section_ph' as any)} style={inputStyle} />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
                <div className="form-group">
                  <label style={labelStyle}>{t('cl_max_cap' as any)}</label>
                  <input type="number" value={formData.maxCapacity} onChange={e => setFormData({ ...formData, maxCapacity: Number(e.target.value) })} required style={inputStyle} />
                </div>
                <div className="form-group">
                  <label style={labelStyle}>{t('cl_room_no' as any)}</label>
                  <input type="text" value={formData.roomNumber} onChange={e => setFormData({ ...formData, roomNumber: e.target.value })} placeholder={t('cl_room_ph' as any)} style={inputStyle} />
                </div>
              </div>

              <div className="form-group">
                <label style={labelStyle}>{t('cl_floor' as any)}</label>
                <input type="text" value={formData.floor} onChange={e => setFormData({ ...formData, floor: e.target.value })} placeholder={t('cl_floor_ph' as any)} style={inputStyle} />
              </div>

              <div className="form-group">
                <label style={labelStyle}>{t('cl_grade' as any)}</label>
                <select value={formData.gradeId} onChange={e => setFormData({ ...formData, gradeId: e.target.value })} style={{ ...inputStyle, appearance: "none" }}>
                  <option value="">{t('cl_sel_grade' as any)}</option>
                  {grades?.map((g: any) => <option key={g.id} value={g.id}>{isAr ? g.name : g.nameEn}</option>)}
                </select>
              </div>

              <div style={{ display: "flex", gap: "12px", marginTop: "12px" }}>
                <button type="button" className="btn outline" onClick={() => setIsModalOpen(false)} style={{ flex: 1 }}>{t('btn_cancel' as any)}</button>
                <button type="submit" className="btn primary" disabled={createMutation.isPending} style={{ flex: 2 }}>{createMutation.isPending ? t('btn_saving' as any) : t('btn_save_year' as any)}</button>
              </div>
            </form>
          </div>
        </div>
      )}
      <style jsx>{`
        /* LUXURY STAT CARDS */
        .luxury-stat-card { position: relative; border-radius: 24px; background: var(--glass-bg); border: 1px solid var(--glass-border); overflow: hidden; transition: 0.4s cubic-bezier(0.2, 0, 0, 1); cursor: default; }
        .luxury-stat-card:hover { transform: translateY(-8px) scale(1.02); border-color: var(--accent-color); box-shadow: 0 15px 30px rgba(0,0,0,0.1); }
        .luxury-stat-inner { padding: 24px; position: relative; z-index: 2; }
        .l-stat-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .l-stat-icon { width: 40px; height: 40px; border-radius: 12px; background: rgba(255,255,255,0.05); border: 1px solid var(--glass-border); display: flex; align-items: center; justify-content: center; color: var(--accent-color); }
        .l-stat-trend { color: #10b981; font-weight: 900; }
        .l-stat-val { font-size: 32px; font-weight: 950; color: var(--glass-text-primary); line-height: 1; letter-spacing: -0.04em; }
        .l-stat-label { font-size: 10px; font-weight: 800; color: var(--glass-text-muted); margin-top: 10px; letter-spacing: 0.1em; }
        .l-stat-bg-blob { position: absolute; bottom: -20px; right: -20px; width: 100px; height: 100px; background: var(--accent-color); filter: blur(50px); opacity: 0.15; transition: 0.4s; }
        .luxury-stat-card:hover .l-stat-bg-blob { opacity: 0.3; transform: scale(1.5); }
      `}</style>
    </div>
  );
}
