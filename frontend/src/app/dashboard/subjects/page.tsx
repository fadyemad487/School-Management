"use client";

import React, { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2 } from "lucide-react";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";

const PREDEFINED_SUBJECTS = [
  { label: "اللغة العربية", value: "اللغة العربية" },
  { label: "اللغة الإنجليزية", value: "اللغة الإنجليزية" },
  { label: "الرياضيات", value: "الرياضيات" },
  { label: "الدراسات الاجتماعية", value: "الدراسات الاجتماعية" },
  { label: "العلوم", value: "العلوم" },
  { label: "التربية الدينية", value: "التربية الدينية" },
  { label: "التربية الفنية", value: "التربية الفنية" },
  { label: "التربية الموسيقية", value: "التربية الموسيقية" },
  { label: "التربية الرياضية", value: "التربية الرياضية" },
  { label: "تكنولوجيا المعلومات", value: "تكنولوجيا المعلومات" },
  { label: "اكتشف (Discover)", value: "اكتشف (Discover)" },
  { label: "--- Languages / English ---", value: "", disabled: true },
  { label: "Arabic", value: "Arabic" },
  { label: "English", value: "English" },
  { label: "Mathematics", value: "Mathematics" },
  { label: "Science", value: "Science" },
  { label: "Social Studies", value: "Social Studies" },
  { label: "Computer / ICT", value: "Computer / ICT" },
  { label: "--- Second Language ---", value: "", disabled: true },
  { label: "French 🇫🇷", value: "French" },
  { label: "German 🇩🇪", value: "German" },
  { label: "Italy 🇮🇹", value: "Italy" },
];

export default function SubjectsPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<{ name: string; code?: string; gradeId?: string }>({ name: "" });
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["subjects"],
    queryFn: async () => (await api.get("/subjects")).data.data,
  });

  const createMutation = useMutation({
    mutationFn: async (payload?: any) => api.post("/subjects", payload || form),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["subjects"] });
      setOpen(false);
      setForm({ name: "" });
      setError(null);
    },
    onError: (e) => setError(extractApiError(e).message),
  });

  const bulkMutation = useMutation({
    mutationFn: async (subjects: any[]) => api.post("/subjects/bulk", { subjects }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["subjects"] }),
    onError: (e) => alert(extractApiError(e).message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/subjects/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["subjects"] }),
  });

  const handleQuickAdd = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    if (!val) return;
    createMutation.mutate({ name: val });
    e.target.value = ""; // Reset select
  };

  const items = useMemo(() => (Array.isArray(data) ? data : []), [data]);

  return (
    <div className="subjects-module" dir={isAr ? "rtl" : "ltr"}>
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{t("mod_subjects_title")}</h2>
          <p style={{ color: "var(--glass-text-secondary)" }}>{t("mod_subjects_desc")}</p>
        </div>
        <div style={{ display: "flex", gap: "12px", alignItems: "center" }}>
          <div style={{ position: "relative" }}>
            <select
              className="glass-input"
              onChange={handleQuickAdd}
              style={{ padding: "10px 40px 10px 15px", minWidth: "220px", fontSize: "14px", cursor: "pointer", border: "1px solid var(--primary-light)" }}
            >
              <option value="">{t('sb_quick_add' as any)}</option>
              {PREDEFINED_SUBJECTS.map((s, idx) => (
                <option key={idx} value={s.value} disabled={s.disabled}>{s.label}</option>
              ))}
            </select>
          </div>
          <button className="btn primary" style={{ borderRadius: "12px", padding: "10px 24px" }} onClick={() => setOpen(true)}>
            <Plus size={18} /> {t('sb_custom_add' as any)}
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="card-glass" style={{ textAlign: "center", padding: "60px" }}>
          <div className="spinner-large" style={{ margin: "0 auto 18px" }} />
          <p style={{ color: "var(--glass-text-secondary)" }}>{t('sb_loading' as any)}</p>
        </div>
      ) : (
        <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: "20px" }}>
          {items.map((s: any) => (
            <div key={s.id} className="luxury-stat-card" style={{ "--accent-color": "var(--primary-light)" } as any}>
              <div className="luxury-stat-inner" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "24px" }}>
                <div style={{ position: "relative", zIndex: 10 }}>
                  <div style={{ fontWeight: 800, color: "var(--glass-text-primary)", fontSize: "18px" }}>{s.name}</div>
                  <div style={{ fontSize: "12px", color: "var(--glass-text-muted)", marginTop: "4px" }}>
                    {s.code ? (
                      <span dir="ltr">CODE: {s.code}</span>
                    ) : t('sb_no_code' as any)}
                  </div>
                </div>
                <button
                  onClick={() => deleteMutation.mutate(s.id)}
                  style={{ position: "relative", zIndex: 10, background: "rgba(244, 63, 94, 0.1)", border: "none", color: "#f43f5e", cursor: "pointer", width: "36px", height: "36px", borderRadius: "10px", display: "flex", alignItems: "center", justifyContent: "center", transition: "0.2s" }}
                  title="Delete"
                  className="hover-scale"
                >
                  <Trash2 size={18} />
                </button>
                <div className="l-stat-bg-blob"></div>
              </div>
            </div>
          ))}
          {items.length === 0 ? (
            <div className="card-glass" style={{ gridColumn: "1 / -1", textAlign: "center", padding: "80px", border: "2px dashed var(--glass-border)" }}>
              <p style={{ fontSize: "18px", color: "var(--glass-text-secondary)" }}>{t('sb_no_data' as any)}</p>
              <p style={{ fontSize: "14px", color: "var(--glass-text-muted)", marginTop: "8px" }}>{t('sb_no_data_sub' as any)}</p>
            </div>
          ) : null}
        </div>
      )}

      <Modal
        isOpen={open}
        onClose={() => setOpen(false)}
        title={t('sb_add_title' as any)}
        footer={
          <>
            <button className="btn" onClick={() => setOpen(false)}>
              {t('btn_cancel' as any)}
            </button>
            <button className="btn primary" onClick={() => createMutation.mutate(form)} disabled={createMutation.isPending || !form.name.trim()}>
              {createMutation.isPending ? t('btn_saving' as any) : t('btn_save_year' as any)}
            </button>
          </>
        }
      >
        <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>
              {t('sb_name' as any)}
            </label>
            <input className="glass-input" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder={t('sb_name_ph' as any)} />
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>
              {t('sb_code' as any)}
            </label>
            <input className="glass-input" value={form.code ?? ""} onChange={(e) => setForm({ ...form, code: e.target.value || undefined })} placeholder={t('sb_code_ph' as any)} />
          </div>
          {error ? <div style={{ color: "#f87171", fontWeight: 600, padding: "12px", background: "rgba(248, 113, 113, 0.1)", borderRadius: "8px" }}>{error}</div> : null}
        </div>
      </Modal>

      <style jsx>{`
        .glass-input {
          width: 100%;
          background: var(--glass-input-bg);
          border: 1px solid var(--glass-input-border);
          border-radius: 12px;
          padding: 14px 18px;
          color: var(--glass-text-primary);
          font-family: inherit;
          transition: 0.3s;
        }
        .glass-input:focus {
          border-color: var(--primary-light);
          outline: none;
          box-shadow: 0 0 15px rgba(59, 130, 246, 0.2);
        }
        .hover-scale:hover {
          transform: translateY(-2px);
          box-shadow: 0 10px 20px rgba(0,0,0,0.1);
        }
        
        /* LUXURY STAT CARDS */
        .luxury-stat-card { position: relative; border-radius: 24px; background: var(--glass-bg); border: 1px solid var(--glass-border); overflow: hidden; transition: 0.4s cubic-bezier(0.2, 0, 0, 1); cursor: default; }
        .luxury-stat-card:hover { transform: translateY(-8px) scale(1.02); border-color: var(--accent-color); box-shadow: 0 15px 30px rgba(0,0,0,0.1); }
        .luxury-stat-inner { position: relative; z-index: 2; }
        .l-stat-bg-blob { position: absolute; bottom: -20px; right: -20px; width: 100px; height: 100px; background: var(--accent-color); filter: blur(50px); opacity: 0.15; transition: 0.4s; z-index: 1; }
        .luxury-stat-card:hover .l-stat-bg-blob { opacity: 0.3; transform: scale(1.5); }
      `}</style>
    </div>
  );
}
