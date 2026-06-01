"use client";

import React, { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import {
  Plus,
  UserPlus,
  Clock,
  CheckCircle,
  FileText,
  Search,
  Filter,
  Eye,
  Trash2,
  MoreVertical,
  ChevronRight,
  RefreshCw,
  XCircle
} from "lucide-react";
import Link from "next/link";
import { api } from "@/lib/api";
import { useTranslation, type TranslationKey } from "@/lib/i18n";

export default function AdmissionsPage() {
  const { t, isAr } = useTranslation();
  const [search, setSearch] = useState("");
  const [showTrash, setShowTrash] = useState(false);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ["admissions"],
    queryFn: async () => (await api.get("/admissions")).data.data,
    staleTime: 0,
    refetchOnMount: "always"
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => api.delete(`/admissions/${id}`),
    onSuccess: () => {
      refetch();
      alert(t('adm_msg_deleted') || (isAr ? "تم حذف الطلب بنجاح" : "Application deleted successfully"));
    }
  });

  const handleDelete = (id: string) => {
    if (window.confirm(isAr ? "هل أنت متأكد من حذف هذا الطلب؟" : "Are you sure you want to delete this application?")) {
      deleteMutation.mutate(id);
    }
  };

  const getStatusBadge = (status: string) => {
    const map: any = {
      NEW: { label: t('status_new'), color: "#f59e0b", bg: "rgba(245, 158, 11, 0.1)" },
      UNDER_REVIEW: { label: t('status_under_review'), color: "#3b82f6", bg: "rgba(59, 130, 246, 0.1)" },
      FINAL_ACCEPTED: { label: t('status_final_accepted'), color: "#34d399", bg: "rgba(52, 211, 153, 0.1)" },
      REJECTED: { label: t('status_rejected'), color: "#f87171", bg: "rgba(248, 113, 113, 0.1)" },
      CONVERTED: { label: t('status_converted'), color: "#10b981", bg: "rgba(16, 185, 129, 0.1)" },
      DOCUMENTS_INCOMPLETE: { label: t('status_doc_incomplete'), color: "#ef4444", bg: "rgba(239, 68, 68, 0.1)" },
      PENDING_DECISION: { label: t('status_pending_decision'), color: "#8b5cf6", bg: "rgba(139, 92, 246, 0.1)" },
      PRELIMINARY_ACCEPTED: { label: t('status_preliminary_accepted'), color: "#60a5fa", bg: "rgba(96, 165, 250, 0.1)" },
    };
    const info = map[status] || { label: status, color: "var(--glass-text-secondary)", bg: "var(--glass-input-bg)" };
    return <span className="badge" style={{ background: info.bg, color: info.color, fontWeight: 700 }}>{info.label}</span>;
  };

  const stats = {
    total: data?.length || 0,
    new: data?.filter((a: any) => a.status === "NEW").length || 0,
    accepted: data?.filter((a: any) => a.status === "FINAL_ACCEPTED" || a.status === "CONVERTED").length || 0,
  };

  const filteredData = data?.filter((a: any) => {
    const matchesSearch = (a.childNameAr?.toLowerCase() || "").includes(search.toLowerCase()) ||
                         (a.applicationNo?.toLowerCase() || "").includes(search.toLowerCase());
    
    if (showTrash) {
      return matchesSearch && a.status === "REJECTED";
    }
    return matchesSearch && a.status !== "REJECTED";
  });

  return (
    <div className="admissions-module">
      {/* Header */}
      <div className="module-header-row" style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "40px" }}>
        <div>
          <h2 style={{ fontSize: "32px", fontWeight: 900, letterSpacing: "-1px", color: "var(--glass-text-primary)" }}>{t('nav_group_admission')}</h2>
          <p style={{ color: "var(--glass-text-secondary)", marginTop: "4px" }}>
            {isAr ? "متابعة وإدارة طلبات التقديم الجديدة للطلاب للعام الدراسي الحالي." : "Monitor and manage new student applications for the current academic cycle."}
          </p>
        </div>
        <div style={{ display: "flex", gap: "12px" }}>
          <button 
            className={`btn ${showTrash ? 'primary' : 'outline'}`} 
            onClick={() => setShowTrash(!showTrash)}
            style={{ borderRadius: "14px", padding: "14px 28px", border: showTrash ? "none" : "1px solid #f87171", color: showTrash ? "#fff" : "#f87171" }}
          >
            <Trash2 size={20} /> {showTrash ? (isAr ? "الطلبات النشطة" : "Active Applications") : (isAr ? "سلة المحذوفات" : "Trash / Rejected")}
          </button>
          <Link href="/dashboard/admissions/new">
            <button className="btn primary" style={{ borderRadius: "14px", padding: "14px 28px" }}>
              <UserPlus size={20} /> {t('btn_add_student')}
            </button>
          </Link>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="module-grid" style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))", gap: "24px", marginBottom: "40px" }}>
        <div className="luxury-stat-card" style={{ "--accent-color": "#3b82f6" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div>
                <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "14px", fontWeight: 600 }}>{isAr ? "إجمالي الطلبات" : "Total Applications"}</h4>
                <div className="value" style={{ fontSize: "32px", fontWeight: 800, marginTop: "8px", color: "var(--glass-text-primary)" }}>{stats.total}</div>
              </div>
              <div style={{ width: "48px", height: "48px", borderRadius: "12px", background: "rgba(59, 130, 246, 0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <FileText size={22} color="#3b82f6" />
              </div>
            </div>
            <div style={{ marginTop: "20px", fontSize: "13px", color: "var(--glass-text-muted)" }}>
              {isAr ? "تراكمي لهذه الدورة" : "Cumulative for this cycle"}
            </div>
          </div>
        </div>

        <div className="luxury-stat-card" style={{ "--accent-color": "#f59e0b" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div>
                <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "14px", fontWeight: 600 }}>{isAr ? "طلبات جديدة" : "New / Pending"}</h4>
                <div className="value" style={{ fontSize: "32px", fontWeight: 800, marginTop: "8px", color: "var(--glass-text-primary)" }}>{stats.new}</div>
              </div>
              <div style={{ width: "48px", height: "48px", borderRadius: "12px", background: "rgba(245, 158, 11, 0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <Clock size={22} color="#f59e0b" />
              </div>
            </div>
            <div style={{ marginTop: "20px", fontSize: "13px", color: "#f59e0b", fontWeight: 600 }}>
              {isAr ? "تحتاج مراجعة فورية" : "Requires immediate review"}
            </div>
          </div>
        </div>

        <div className="luxury-stat-card" style={{ "--accent-color": "#34d399" } as any}>
          <div className="l-stat-bg-blob"></div>
          <div className="luxury-stat-inner">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div>
                <h4 style={{ color: "var(--glass-text-secondary)", fontSize: "14px", fontWeight: 600 }}>{isAr ? "تم قبولهم" : "Accepted"}</h4>
                <div className="value" style={{ fontSize: "32px", fontWeight: 800, marginTop: "8px", color: "var(--glass-text-primary)" }}>{stats.accepted}</div>
              </div>
              <div style={{ width: "48px", height: "48px", borderRadius: "12px", background: "rgba(52, 211, 153, 0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                <CheckCircle size={22} color="#34d399" />
              </div>
            </div>
            <div style={{ marginTop: "20px", fontSize: "13px", color: "#34d399", fontWeight: 600 }}>
              {isAr ? "جاهزون للتسجيل النهائي" : "Ready for enrollment"}
            </div>
          </div>
        </div>
      </div>

      {/* Filter Row */}
      <div className="card-glass" style={{ padding: "16px 24px", marginBottom: "24px", display: "flex", gap: "20px", alignItems: "center" }}>
        <div style={{ position: "relative", flex: 1 }}>
          <Search size={18} style={{ position: "absolute", left: isAr ? "auto" : "14px", right: isAr ? "14px" : "auto", top: "50%", transform: "translateY(-50%)", color: "var(--glass-text-muted)" }} />
          <input
            type="text"
            placeholder={isAr ? "ابحث باسم الطالب أو رقم الطلب..." : "Search by student name or application ID..."}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{
              width: "100%",
              background: "var(--glass-input-bg)",
              border: "1px solid var(--glass-input-border)",
              borderRadius: "12px",
              padding: isAr ? "12px 42px 12px 14px" : "12px 14px 12px 42px",
              color: "var(--glass-text-primary)",
              outline: "none",
              textAlign: isAr ? "right" : "left"
            }}
          />
        </div>
      </div>

      {/* Table */}
      <div className="premium-table-wrapper card-glass" style={{ padding: "0", overflow: "hidden" }}>
        <table className="premium-table">
          <thead>
            <tr>
              <th style={{ textAlign: isAr ? "right" : "left" }}>{t('adm_label_id')}</th>
              <th style={{ textAlign: isAr ? "right" : "left" }}>{isAr ? "اسم الطالب" : "Student Name"}</th>
              <th style={{ textAlign: isAr ? "right" : "left" }}>{t('adm_label_grade')}</th>
              <th style={{ textAlign: isAr ? "right" : "left" }}>{t('adm_label_phone')}</th>
              <th style={{ textAlign: isAr ? "right" : "left" }}>{t('adm_label_status')}</th>
              <th style={{ textAlign: isAr ? "right" : "left" }}>{isAr ? "التاريخ" : "Date"}</th>
              <th style={{ textAlign: isAr ? "left" : "right" }}>{isAr ? "إجراءات" : "Actions"}</th>
            </tr>
          </thead>
          <tbody>
            {isLoading ? (
              <tr><td colSpan={7} style={{ textAlign: "center", padding: "60px" }}><div className="spinner-large" style={{ margin: "0 auto" }} /></td></tr>
            ) : filteredData?.length === 0 ? (
              <tr><td colSpan={7} style={{ textAlign: "center", padding: "60px", color: "var(--glass-text-muted)" }}>{isAr ? "لا توجد طلبات مطابقة للبحث." : "No matching applications found."}</td></tr>
            ) : filteredData?.map((app: any) => (
              <tr key={app.id}>
                <td style={{ fontFamily: "monospace", fontSize: "13px", color: "var(--primary-light)" }}>
                  {app.applicationNo}
                </td>
                <td>
                  <div style={{ fontWeight: 700, color: "var(--glass-text-primary)" }}>
                    {isAr ? app.childNameAr : (app.childNameEn || app.childNameAr)}
                  </div>
                  <div style={{ fontSize: "12px", color: "var(--glass-text-muted)" }}>
                    {isAr ? (app.childNameEn || "—") : app.childNameAr}
                  </div>
                </td>
                <td>
                  <span className="badge" style={{ background: "rgba(59, 130, 246, 0.1)", color: "#3b82f6" }}>
                    {app.grade?.name || "—"}
                  </span>
                </td>
                <td style={{ fontSize: "14px", color: "var(--glass-text-secondary)" }}>
                  {app.father?.phone || "—"}
                </td>
                <td>
                  {getStatusBadge(app.status)}
                </td>
                <td style={{ fontSize: "13px", color: "var(--glass-text-muted)" }}>
                  {new Date(app.createdAt).toLocaleDateString()}
                </td>
                <td style={{ textAlign: isAr ? "left" : "right" }}>
                  <Link href={`/dashboard/admissions/${app.id}`}>
                    <button className="btn-icon">
                      <Eye size={18} />
                    </button>
                  </Link>
                  {!showTrash && (
                    <button 
                      className="btn-icon delete" 
                      onClick={() => handleDelete(app.id)}
                      style={{ marginLeft: isAr ? "0" : "8px", marginRight: isAr ? "8px" : "0" }}
                    >
                      <Trash2 size={18} />
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <style jsx>{`
        .btn-icon {
          width: 36px;
          height: 36px;
          border-radius: 10px;
          background: var(--glass-icon-bg);
          border: 1px solid var(--glass-border);
          color: var(--glass-text-secondary);
          display: inline-flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          transition: 0.2s;
        }
        .btn-icon:hover {
          background: rgba(59, 130, 246, 0.1);
          color: var(--primary-light);
          border-color: var(--primary-light);
          transform: translateY(-2px);
        }
        .btn-icon.delete:hover {
          background: rgba(239, 68, 68, 0.1);
          color: #ef4444;
          border-color: #ef4444;
        }
      `}</style>
    </div>
  );
}
