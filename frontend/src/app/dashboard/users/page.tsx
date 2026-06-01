"use client";

import React, { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Plus, X, Search, Shield, Mail, User as UserIcon, MoreHorizontal, CheckCircle2 } from "lucide-react";
import { api, extractApiError } from "@/lib/api";
import { useTranslation } from "@/lib/i18n";
import { useAuth } from "@/components/shared/AuthProvider";

const ROLE_COLORS: Record<string, { bg: string, text: string }> = {
  SUPER_ADMIN: { bg: "rgba(239, 68, 68, 0.1)", text: "#ef4444" },
  SCHOOL_ADMIN: { bg: "rgba(59, 130, 246, 0.1)", text: "#3b82f6" },
  ADMIN: { bg: "rgba(99, 102, 241, 0.1)", text: "#6366f1" },
  TEACHER: { bg: "rgba(16, 185, 129, 0.1)", text: "#10b981" },
  STUDENT: { bg: "rgba(245, 158, 11, 0.1)", text: "#f59e0b" },
  PARENT: { bg: "rgba(139, 92, 246, 0.1)", text: "#8b5cf6" },
  ACCOUNTANT: { bg: "rgba(6, 182, 212, 0.1)", text: "#06b6d4" },
};

export default function UsersPage() {
  const { t, isAr } = useTranslation();
  const { user: currentUser } = useAuth();
  const queryClient = useQueryClient();
  const [q, setQ] = useState("");
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading } = useQuery({
    queryKey: ["users", q],
    queryFn: async () => {
      try {
        const res = await api.get("/users", { params: q ? { q } : undefined });
        setError(null);
        return res.data.data;
      } catch (e) {
        setError(extractApiError(e).message);
        return [];
      }
    },
  });

  const items = useMemo(() => (Array.isArray(data) ? data : []), [data]);

  const roleMutation = useMutation({
    mutationFn: async ({ id, role }: { id: string; role: string }) => api.patch(`/users/${id}/role`, { role }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["users"] }),
    onError: (e) => setError(extractApiError(e).message),
  });

  const canEdit = ["SUPER_ADMIN", "SCHOOL_ADMIN", "ADMIN"].includes(currentUser?.role || "");

  const formatRole = (r: string) => r.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, c => c.toUpperCase());

  return (
    <div className="users-module" dir={isAr ? "rtl" : "ltr"}>
      {/* Header Section */}
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "32px" }}>
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 800, color: "var(--glass-text-primary)", letterSpacing: "-0.5px" }}>{isAr ? "إدارة المستخدمين" : "Users Management"}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>{isAr ? "التحكم في أدوار وصلاحيات المستخدمين في المنصة" : "Manage roles and permissions for all platform users"}</p>
        </div>
        <div style={{ display: "flex", gap: "12px" }}>
           <div className="badge-premium" style={{ background: "rgba(255,255,255,0.05)", border: "1px solid var(--glass-border)", padding: "8px 16px", borderRadius: "12px", display: "flex", alignItems: "center", gap: "8px" }}>
              <CheckCircle2 size={16} color="#10b981" />
              <span style={{ fontSize: "13px", fontWeight: 600, color: "var(--glass-text-secondary)" }}>{items.length} {isAr ? "مستخدم" : "Total Users"}</span>
           </div>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="card-glass active" style={{ marginBottom: "24px", padding: "16px", display: "flex", gap: "16px", alignItems: "center" }}>
        <div style={{ position: "relative", flex: 1 }}>
          <Search style={{ position: "absolute", left: isAr ? "auto" : "16px", right: isAr ? "16px" : "auto", top: "50%", transform: "translateY(-50%)", color: "var(--glass-text-muted)" }} size={18} />
          <input 
            className="glass-input-search" 
            placeholder={isAr ? "البحث بالاسم أو البريد..." : "Search users by name or email..."} 
            value={q} 
            onChange={(e) => setQ(e.target.value)} 
            style={{ paddingLeft: isAr ? "16px" : "48px", paddingRight: isAr ? "48px" : "16px" }}
          />
        </div>
        {canEdit && (
          <div style={{ background: "rgba(16, 185, 129, 0.05)", padding: "8px 12px", borderRadius: "10px", color: "#10b981", fontSize: "12px", fontWeight: 700, border: "1px solid rgba(16, 185, 129, 0.2)" }}>
            <Shield size={14} style={{ verticalAlign: "middle", marginRight: "6px" }} />
            {isAr ? "وضع التعديل مفعل" : "Admin Mode Active"}
          </div>
        )}
      </div>

      {error ? <div className="error-box">{error}</div> : null}

      {isLoading ? (
        <div style={{ padding: "100px 0", textAlign: "center" }}>
          <div className="spinner-large" style={{ margin: "0 auto" }} />
          <p style={{ marginTop: "16px", color: "var(--glass-text-muted)" }}>{isAr ? "جاري جلب المستخدمين..." : "Fetching users list..."}</p>
        </div>
      ) : (
        <div className="users-grid">
          {items.map((u: any) => {
            const roleStyle = ROLE_COLORS[u.role] || { bg: "rgba(255,255,255,0.05)", text: "var(--glass-text-muted)" };
            const initial = (u.fullName?.[0] || u.email?.[0] || "?").toUpperCase();
            
            return (
              <div key={u.id} className="user-card luxury-stat-card">
                <div className="glow-blob"></div>
                <div className="card-content">
                  <div style={{ display: "flex", alignItems: "center", gap: "16px", marginBottom: "20px" }}>
                    <div className="user-avatar" style={{ background: roleStyle.text + "22", color: roleStyle.text }}>
                      {initial}
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div className="user-name" title={u.fullName}>{u.fullName}</div>
                      <div className="user-email">
                        <Mail size={12} style={{ marginInlineEnd: "4px" }} />
                        {u.email}
                      </div>
                    </div>
                  </div>

                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: "12px", borderTop: "1px solid var(--glass-border)", paddingTop: "16px" }}>
                    <div className="role-badge" style={{ background: roleStyle.bg, color: roleStyle.text }}>
                      {formatRole(u.role)}
                    </div>
                    
                    {canEdit ? (
                      <select
                        className="role-selector"
                        value={u.role}
                        disabled={roleMutation.isPending}
                        onChange={(e) => roleMutation.mutate({ id: u.id, role: e.target.value })}
                      >
                        {[
                          "SUPER_ADMIN", "ADMIN", "SCHOOL_ADMIN", "ADMISSION_OFFICER", "STUDENT_AFFAIRS",
                          "ACCOUNTANT", "BUS_SUPERVISOR", "DRIVER", "TEACHER", "STUDENT", "PARENT",
                        ].map((r) => (
                          <option key={r} value={r}>{formatRole(r)}</option>
                        ))}
                      </select>
                    ) : (
                      <div style={{ color: "var(--glass-text-muted)", fontSize: "11px", fontWeight: 700 }}>{isAr ? "عرض فقط" : "View Only"}</div>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
          
          {items.length === 0 && !isLoading && (
            <div style={{ gridColumn: "1 / -1", padding: "80px", textAlign: "center", background: "rgba(255,255,255,0.02)", borderRadius: "24px", border: "1px dashed var(--glass-border)" }}>
              <UserIcon size={48} color="var(--glass-text-muted)" style={{ marginBottom: "16px", opacity: 0.3 }} />
              <p style={{ color: "var(--glass-text-muted)", fontSize: "16px" }}>{isAr ? "لم يتم العثور على مستخدمين" : "No users found matching your search."}</p>
            </div>
          )}
        </div>
      )}

      <style jsx>{`
        .users-grid {
          display: grid;
          grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
          gap: 20px;
        }
        .luxury-stat-card {
          position: relative;
          background: var(--glass-bg);
          backdrop-filter: blur(20px);
          border: 1px solid var(--glass-border);
          border-radius: 24px;
          padding: 24px;
          overflow: hidden;
          transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
          z-index: 1;
        }
        .luxury-stat-card:hover {
          transform: translateY(-8px) scale(1.02);
          border-color: var(--primary-light);
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
        }
        .glow-blob {
          position: absolute;
          width: 140px;
          height: 140px;
          background: var(--gradient-primary);
          filter: blur(60px);
          opacity: 0.1;
          border-radius: 50%;
          top: -40px;
          inset-inline-end: -40px;
          z-index: 0;
          transition: 0.6s;
        }
        .luxury-stat-card:hover .glow-blob {
          opacity: 0.25;
          transform: scale(1.8) translate(-10%, 10%);
        }
        .card-content {
          position: relative;
          z-index: 2;
        }
        .user-card {
          min-height: 180px;
        }
        .user-avatar {
          width: 48px;
          height: 48px;
          border-radius: 14px;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: 800;
          font-size: 18px;
          flex-shrink: 0;
        }
        .user-name {
          font-weight: 800;
          color: var(--glass-text-primary);
          font-size: 16px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .user-email {
          font-size: 12px;
          color: var(--glass-text-muted);
          margin-top: 4px;
          display: flex;
          align-items: center;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .role-badge {
          font-size: 11px;
          font-weight: 800;
          padding: 4px 10px;
          border-radius: 8px;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }
        .glass-input-search {
          width: 100%;
          background: rgba(0,0,0,0.02);
          border: 1px solid var(--glass-border);
          border-radius: 14px;
          padding: 14px 18px;
          color: var(--glass-text-primary);
          font-family: inherit;
          font-size: 14px;
          transition: 0.3s;
        }
        .glass-input-search:focus {
          border-color: var(--primary-light);
          background: rgba(255,255,255,0.05);
          outline: none;
          box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.1);
        }
        .role-selector {
          background: rgba(255,255,255,0.05);
          border: 1px solid var(--glass-border);
          border-radius: 8px;
          padding: 6px 8px;
          font-size: 12px;
          color: var(--glass-text-secondary);
          font-weight: 600;
          cursor: pointer;
          outline: none;
          transition: 0.2s;
        }
        .role-selector:hover {
          border-color: var(--primary-light);
        }
        .error-box {
          background: rgba(239, 68, 68, 0.05);
          border: 1px solid rgba(239, 68, 68, 0.2);
          color: #ef4444;
          padding: 12px 16px;
          border-radius: 12px;
          margin-bottom: 24px;
          font-size: 14px;
          font-weight: 600;
        }
      `}</style>
    </div>
  );
}

