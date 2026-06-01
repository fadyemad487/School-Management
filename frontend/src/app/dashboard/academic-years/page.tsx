"use client";

import React, { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { Plus, Calendar, CheckCircle2, AlertCircle, Trash2 } from "lucide-react";
import { api } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";

export default function AcademicYearsPage() {
  const { t, isAr } = useTranslation();
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState({
    name: "",
    startDate: "",
    endDate: "",
    isCurrent: false
  });

  const { data, isLoading } = useQuery({
    queryKey: ["academic-years"],
    queryFn: async () => (await api.get("/academic/years")).data.data
  });

  const createMutation = useMutation({
    mutationFn: async (newData: typeof formData) => {
      return await api.post("/academic/years", newData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["academic-years"] });
      setIsModalOpen(false);
      setFormData({ name: "", startDate: "", endDate: "", isCurrent: false });
    },
    onError: (error: any) => {
      console.error("Create Academic Year Error:", error?.response?.data || error.message);
      alert(error?.response?.data?.message || "Failed to create academic year");
    }
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      return await api.delete(`/academic/years/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["academic-years"] });
    },
    onError: (error: any) => {
      console.error("Delete Academic Year Error:", error?.response?.data || error.message);
      alert(error?.response?.data?.message || "Failed to delete academic year");
    }
  });

  const handleCreate = (e?: React.FormEvent | React.MouseEvent) => {
    if (e) e.preventDefault();
    if (!formData.name || !formData.startDate || !formData.endDate) {
      alert("Please fill in all required fields");
      return;
    }
    createMutation.mutate(formData);
  };

  return (
    <div className="academic-module" dir={isAr ? "rtl" : "ltr"}>
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{t('dash_academic_years')}</h2>
          <p style={{ color: "var(--glass-text-secondary)" }}>{t('ay_desc' as any)}</p>
        </div>
        <button 
          className="btn primary" 
          style={{ borderRadius: "12px" }}
          onClick={() => setIsModalOpen(true)}
        >
          <Plus size={18} /> {t('btn_add_year' as any)}
        </button>
      </div>

      <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(320px, 1fr))", gap: "24px" }}>
        {isLoading ? (
          <div className="luxury-stat-card" style={{ gridColumn: "1 / -1", textAlign: "center", "--accent-color": "var(--primary-light)" } as any}>
            <div className="luxury-stat-inner">
              <div className="spinner-large" style={{ margin: "0 auto 20px" }} />
              <p style={{ color: "var(--glass-text-primary)" }}>{t('ay_loading' as any)}</p>
            </div>
          </div>
        ) : data?.length === 0 ? (
          <div className="luxury-stat-card" style={{ gridColumn: "1 / -1", textAlign: "center", padding: "60px", "--accent-color": "var(--glass-text-muted)" } as any}>
             <div className="luxury-stat-inner">
              <Calendar size={48} color="var(--glass-text-muted)" style={{ marginBottom: "20px" }} />
              <p style={{ fontSize: "18px", color: "var(--glass-text-secondary)" }}>{t('ay_no_data' as any)}</p>
            </div>
          </div>
        ) : data?.map((year: any) => (
          <div 
            key={year.id} 
            className="luxury-stat-card" 
            style={{ "--accent-color": year.isCurrent ? "#10b981" : "#3b82f6" } as any}
          >
            <div className="l-stat-bg-blob"></div>
            <div className="luxury-stat-inner">
              {year.isCurrent && (
                <div style={{ position: "absolute", top: "0px", left: isAr ? "0px" : "auto", right: isAr ? "auto" : "0px", background: "rgba(52, 211, 153, 0.1)", color: "#10b981", padding: "4px 10px", borderRadius: "20px", fontSize: "12px", fontWeight: 700, display: "flex", alignItems: "center", gap: "6px" }}>
                  <CheckCircle2 size={14} /> {t('ay_active' as any)}
                </div>
              )}
              <h3 style={{ fontSize: "22px", fontWeight: 800, marginBottom: "8px", color: "var(--glass-text-primary)" }}>{year.name}</h3>
              <div style={{ display: "flex", gap: "24px", marginTop: "20px" }}>
                <div>
                  <div style={{ fontSize: "11px", color: "var(--glass-text-muted)", textTransform: "uppercase", letterSpacing: "1px" }}>{t('ay_starts' as any)}</div>
                  <div style={{ fontWeight: 600, color: "var(--glass-text-primary)" }}>{new Date(year.startDate).toLocaleDateString()}</div>
                </div>
                <div>
                  <div style={{ fontSize: "11px", color: "var(--glass-text-muted)", textTransform: "uppercase", letterSpacing: "1px" }}>{t('ay_ends' as any)}</div>
                  <div style={{ fontWeight: 600, color: "var(--glass-text-primary)" }}>{new Date(year.endDate).toLocaleDateString()}</div>
                </div>
              </div>
              
              <div style={{ marginTop: "32px", display: "flex", justifyContent: "flex-end", borderTop: "1px solid var(--glass-border)", paddingTop: "16px" }}>
                <button 
                  onClick={() => deleteMutation.mutate(year.id)}
                  style={{ background: "none", border: "none", color: "var(--glass-text-muted)", cursor: "pointer", transition: "0.2s" }}
                  className="hover-red"
                >
                  <Trash2 size={18} />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={t('ay_create' as any)}
        footer={
          <>
            <button className="btn" onClick={() => setIsModalOpen(false)}>{t('btn_cancel' as any)}</button>
            <button 
              className="btn primary" 
              onClick={handleCreate}
              disabled={createMutation.isPending}
            >
              {createMutation.isPending ? t('btn_creating' as any) : t('btn_save_year' as any)}
            </button>
          </>
        }
      >
        <form onSubmit={handleCreate} style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>{t('ay_name' as any)}</label>
            <input 
              type="text" 
              placeholder="e.g. 2024-2025"
              value={formData.name}
              onChange={e => setFormData({...formData, name: e.target.value})}
              className="glass-input"
              required
            />
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px" }}>
            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>{t('ay_start_date' as any)}</label>
              <input 
                type="date" 
                value={formData.startDate}
                onChange={e => setFormData({...formData, startDate: e.target.value})}
                className="glass-input"
                required
              />
            </div>
            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>{t('ay_end_date' as any)}</label>
              <input 
                type="date" 
                value={formData.endDate}
                onChange={e => setFormData({...formData, endDate: e.target.value})}
                className="glass-input"
                required
              />
            </div>
          </div>
          <label style={{ display: "flex", alignItems: "center", gap: "12px", cursor: "pointer", color: "var(--glass-text-primary)" }}>
            <input 
              type="checkbox" 
              checked={formData.isCurrent}
              onChange={e => setFormData({...formData, isCurrent: e.target.checked})}
              style={{ width: "18px", height: "18px" }}
            />
            <span style={{ fontSize: "14px", fontWeight: 600 }}>{t('ay_set_active' as any)}</span>
          </label>
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
        .active-year-glow {
          border-color: rgba(52, 211, 153, 0.3);
          box-shadow: 0 0 20px rgba(52, 211, 153, 0.1);
        }
        .hover-red:hover {
          color: #f87171 !important;
          transform: scale(1.1);
        }
      `}</style>
    </div>
  );
}
