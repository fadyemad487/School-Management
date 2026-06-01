"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, GraduationCap, Wand2, Trash2, CheckCircle2 } from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";

export default function GradesPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    nameEn: "",
    order: 1
  });

  const { data, isLoading } = useQuery({
    queryKey: ["grades"],
    queryFn: async () => (await api.get("/academic/grades")).data.data
  });

  const createMutation = useMutation({
    mutationFn: async (newData: typeof formData) => {
      return await api.post("/academic/grades", newData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["grades"] });
      setIsModalOpen(false);
      setFormData({ name: "", nameEn: "", order: 1 });
    }
  });

  const seedMutation = useMutation({
    mutationFn: async () => {
      return await api.post("/academic/grades/seed");
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["grades"] });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      return await api.delete(`/academic/grades/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["grades"] });
    }
  });

  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    createMutation.mutate(formData);
  };

  return (
    <div className="grades-module" dir={isAr ? "rtl" : "ltr"}>
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{t('dash_grades')}</h2>
          <p style={{ color: "var(--glass-text-secondary)" }}>{t('gd_desc' as any)}</p>
        </div>
        <div style={{ display: "flex", gap: "12px" }}>
          {!isLoading && data?.length === 0 && (
            <button 
              className="btn outline" 
              style={{ borderColor: "var(--primary-light)", color: "var(--primary-light)" }}
              onClick={() => seedMutation.mutate()}
              disabled={seedMutation.isPending}
            >
              <Wand2 size={18} /> {seedMutation.isPending ? t('btn_seeding' as any) : t('btn_auto_setup' as any)}
            </button>
          )}
          <button 
            className="btn primary" 
            style={{ borderRadius: "12px" }}
            onClick={() => setIsModalOpen(true)}
          >
            <Plus size={18} /> {t('btn_add_grade' as any)}
          </button>
        </div>
      </div>

      {seedMutation.isSuccess && (
        <div className="card-glass" style={{ marginBottom: "24px", borderColor: "rgba(52, 211, 153, 0.3)", background: "rgba(52, 211, 153, 0.05)", padding: "16px 24px", display: "flex", alignItems: "center", gap: "12px" }}>
          <CheckCircle2 color="#34d399" size={20} />
          <span style={{ color: "#34d399", fontWeight: 600 }}>{t('gd_success_seed' as any)}</span>
        </div>
      )}

      <div className="module-grid" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))" }}>
        {isLoading ? (
          <div className="card-glass" style={{ gridColumn: "1 / -1", textAlign: "center" }}>
            <div className="spinner-large" style={{ margin: "0 auto 20px" }} />
            <p style={{ color: "var(--glass-text-primary)" }}>{t('gd_loading' as any)}</p>
          </div>
        ) : data?.length === 0 ? (
          <div className="card-glass" style={{ gridColumn: "1 / -1", textAlign: "center", padding: "60px" }}>
            <GraduationCap size={48} color="var(--glass-text-muted)" style={{ marginBottom: "20px" }} />
            <p style={{ fontSize: "18px", color: "var(--glass-text-secondary)" }}>{t('gd_no_data' as any)}</p>
          </div>
        ) : data?.sort((a: any, b: any) => a.order - b.order).map((grade: any) => (
          <div key={grade.id} className="luxury-stat-card" style={{ "--accent-color": "var(--primary-light)" } as any}>
            <div className="luxury-stat-inner">
               <div className="l-stat-top">
                  <div className="l-stat-icon" style={{ fontSize: "20px", fontWeight: 800 }}>{grade.order}</div>
                  <div className="l-stat-trend">
                    <button 
                      onClick={() => deleteMutation.mutate(grade.id)}
                      style={{ background: "none", border: "none", color: "var(--glass-text-muted)", cursor: "pointer", transition: "0.2s", display: "flex", alignItems: "center" }}
                      className="hover-red"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
               </div>
               <div className="l-stat-body">
                  <div className="l-stat-val" style={{ fontSize: "24px" }}>{grade.name}</div>
                  <div className="l-stat-label">{grade.nameEn || "N/A"}</div>
               </div>
               <div className="l-stat-bg-blob"></div>
            </div>
          </div>
        ))}
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={t('gd_add_title' as any)}
        footer={
          <>
            <button className="btn" onClick={() => setIsModalOpen(false)}>{t('btn_cancel' as any)}</button>
            <button 
              className="btn primary" 
              onClick={handleCreate}
              disabled={createMutation.isPending}
            >
              {createMutation.isPending ? t('btn_saving' as any) : t('btn_save_grade' as any)}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreate} style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>{t('gd_name_ar' as any)}</label>
            <input 
              type="text" 
              placeholder="e.g. الصف الأول الابتدائي"
              value={formData.name}
              onChange={e => setFormData({...formData, name: e.target.value})}
              className="glass-input"
              required
            />
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>{t('gd_name_en' as any)}</label>
            <input 
              type="text" 
              placeholder="e.g. Primary 1"
              value={formData.nameEn}
              onChange={e => setFormData({...formData, nameEn: e.target.value})}
              className="glass-input"
            />
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>{t('gd_order' as any)}</label>
            <input 
              type="number" 
              min="1"
              max="12"
              value={formData.order}
              onChange={e => setFormData({...formData, order: parseInt(e.target.value)})}
              className="glass-input"
              required
            />
          </div>
        </form>
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
        .hover-red:hover {
          color: #f87171 !important;
          transform: scale(1.1);
        }
        
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
