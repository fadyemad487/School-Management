"use client";

import React, { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus, Trash2 } from "lucide-react";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { Modal } from "@/components/ui/Modal";

export default function HomeworkPage() {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [open, setOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState<any>({
    classId: "",
    title: "",
    description: "",
  });

  const { data, isLoading } = useQuery({
    queryKey: ["homework"],
    queryFn: async () => (await api.get("/homework")).data.data,
  });

  const items = useMemo(() => (Array.isArray(data) ? data : []), [data]);

  const createMutation = useMutation({
    mutationFn: async () => api.post("/homework", form),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["homework"] });
      setOpen(false);
      setForm({ classId: "", title: "", description: "" });
      setError(null);
    },
    onError: (e) => setError(extractApiError(e).message),
  });

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => api.delete(`/homework/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["homework"] }),
  });

  return (
    <div className="homework-module">
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "24px" }}>
        <div>
          <h2 style={{ fontSize: "28px", fontWeight: 800, color: "var(--glass-text-primary)" }}>{t("mod_homework_title")}</h2>
          <p style={{ color: "var(--glass-text-secondary)" }}>{t("mod_homework_desc")}</p>
        </div>
        <button className="btn primary" style={{ borderRadius: "12px" }} onClick={() => setOpen(true)}>
          <Plus size={18} /> Add
        </button>
      </div>

      {isLoading ? (
        <div className="card-glass" style={{ textAlign: "center" }}>
          <div className="spinner-large" style={{ margin: "0 auto 18px" }} />
          <p style={{ color: "var(--glass-text-secondary)" }}>Loading homework…</p>
        </div>
      ) : (
        <div className="module-grid" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(360px, 1fr))" }}>
          {items.map((h: any) => (
            <div key={h.id} className="card-glass" style={{ display: "flex", justifyContent: "space-between", gap: "16px" }}>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontWeight: 800, color: "var(--glass-text-primary)" }}>{h.title}</div>
                <div style={{ fontSize: "12px", color: "var(--glass-text-muted)", marginTop: "6px" }}>
                  {h.class?.name ? `Class: ${h.class.name}` : `ClassId: ${h.classId}`}
                </div>
                {h.description ? <div style={{ marginTop: "10px", color: "var(--glass-text-secondary)" }}>{h.description}</div> : null}
              </div>
              <button onClick={() => deleteMutation.mutate(h.id)} style={{ background: "none", border: "none", color: "var(--glass-text-muted)", cursor: "pointer" }}>
                <Trash2 size={18} />
              </button>
            </div>
          ))}
          {items.length === 0 ? (
            <div className="card-glass" style={{ gridColumn: "1 / -1", textAlign: "center", padding: "48px" }}>
              <p style={{ color: "var(--glass-text-secondary)" }}>No homework yet.</p>
            </div>
          ) : null}
        </div>
      )}

      <Modal
        isOpen={open}
        onClose={() => setOpen(false)}
        title="Create Homework"
        footer={
          <>
            <button className="btn" onClick={() => setOpen(false)}>
              Cancel
            </button>
            <button className="btn primary" onClick={() => createMutation.mutate()} disabled={createMutation.isPending || !form.classId || !form.title.trim()}>
              {createMutation.isPending ? "Saving…" : "Save"}
            </button>
          </>
        }
      >
        <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>Class ID</label>
            <input className="glass-input" value={form.classId} onChange={(e) => setForm({ ...form, classId: e.target.value })} placeholder="Paste classId for now" />
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>Title</label>
            <input className="glass-input" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })} />
          </div>
          <div>
            <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", fontWeight: 600, color: "var(--glass-text-primary)" }}>Description</label>
            <textarea className="glass-input" value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={4} />
          </div>
          {error ? <div style={{ color: "#f87171", fontWeight: 600 }}>{error}</div> : null}
        </div>
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
        `}</style>
      </Modal>
    </div>
  );
}
